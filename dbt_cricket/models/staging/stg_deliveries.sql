WITH source AS (
    SELECT * FROM {{ source('raw', 'raw_deliveries') }}
),

cleaned AS (
    SELECT
        match_id,
        season,
        TRY_TO_DATE(start_date) AS match_date,
        venue,
        innings::INTEGER AS innings,
        ball::FLOAT AS ball,
        batting_team,
        bowling_team,
        striker AS batter,
        bowler,
        COALESCE(runs_off_bat::INTEGER, 0) AS runs_off_bat,
        COALESCE(extras::INTEGER, 0) AS extras,
        COALESCE(wides::INTEGER, 0) AS wides,
        COALESCE(noballs::INTEGER, 0) AS noballs,
        COALESCE(runs_off_bat::INTEGER, 0) + COALESCE(extras::INTEGER, 0) AS total_runs,
        CASE WHEN wicket_type IS NOT NULL AND wicket_type != 'None' THEN 1 ELSE 0 END AS is_wicket,
        wicket_type,
        player_dismissed
    FROM source
    WHERE match_id IS NOT NULL
)

SELECT * FROM cleaned
