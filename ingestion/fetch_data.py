import requests
import zipfile
import os
import glob
import yaml
import pandas as pd
import snowflake.connector
from cryptography.hazmat.primitives import serialization
from snowflake.connector.pandas_tools import write_pandas


def get_snowflake_connection(schema="RAW"):
    with open("/Users/kovid/.dbt/profiles.yml", "r") as f:
        profiles = yaml.safe_load(f)
    dev = profiles["dbt_cricket"]["outputs"]["dev"]
    with open(dev["private_key_path"], "rb") as key_file:
        private_key = serialization.load_pem_private_key(key_file.read(), password=None)
    private_key_bytes = private_key.private_bytes(
        encoding=serialization.Encoding.DER,
        format=serialization.PrivateFormat.PKCS8,
        encryption_algorithm=serialization.NoEncryption()
    )
    return snowflake.connector.connect(
        user=dev["user"],
        account=dev["account"],
        private_key=private_key_bytes,
        warehouse=dev["warehouse"],
        database=dev["database"],
        schema=schema
    )


def download_cricsheet_data():
    url = "https://cricsheet.org/downloads/ipl_csv2.zip"
    print("Downloading IPL data from Cricsheet...")
    response = requests.get(url)
    with open("ipl_data.zip", "wb") as f:
        f.write(response.content)
    os.makedirs("raw_data", exist_ok=True)
    with zipfile.ZipFile("ipl_data.zip", "r") as z:
        z.extractall("raw_data/")
    print("Extracted data to raw_data/")


def combine_match_files():
    delivery_files = [f for f in glob.glob("raw_data/*.csv") if "_info" not in f]
    print(f"Found {len(delivery_files)} match files")
    dfs = []
    for file in delivery_files:
        match_id = os.path.basename(file).replace(".csv", "")
        try:
            df = pd.read_csv(file)
            df["match_id"] = match_id
            dfs.append(df)
        except Exception as e:
            print(f"Skipping {file}: {e}")
    combined = pd.concat(dfs, ignore_index=True)
    print(f"Combined {len(combined)} total deliveries")
    return combined


def load_to_snowflake():
    conn = get_snowflake_connection(schema="RAW")
    cursor = conn.cursor()

    matches_df = combine_match_files()
    print(f"Columns: {list(matches_df.columns)}")

    # Uppercase columns for Snowflake
    matches_df.columns = [col.upper() for col in matches_df.columns]

    # Dynamic table creation
    col_defs = ",\n".join([f"{col} VARCHAR" for col in matches_df.columns])
    cursor.execute(f"CREATE OR REPLACE TABLE cricket_db.raw.raw_deliveries ({col_defs})")
    print("Created table raw_deliveries")

    # Clean data
    matches_df = matches_df.astype(str).replace("nan", None)

    # Write using executemany instead of write_pandas
    cols = ", ".join(matches_df.columns)
    placeholders = ", ".join(["%s"] * len(matches_df.columns))
    insert_sql = f"INSERT INTO cricket_db.raw.raw_deliveries ({cols}) VALUES ({placeholders})"

    # Convert to list of tuples
    data = [tuple(row) for row in matches_df.itertuples(index=False)]

    # Insert in chunks of 10000
    chunk_size = 10000
    total = 0
    for i in range(0, len(data), chunk_size):
        chunk = data[i:i + chunk_size]
        cursor.executemany(insert_sql, chunk)
        total += len(chunk)
        print(f"Inserted {total}/{len(data)} rows...")

    print(f"Successfully loaded {total} rows into Snowflake")
    cursor.close()
    conn.close()


if __name__ == "__main__":
    download_cricsheet_data()
    load_to_snowflake()