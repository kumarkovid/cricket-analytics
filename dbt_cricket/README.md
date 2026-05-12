# dbt Cricket Models

dbt transformation layer for the cricket analytics pipeline.

## Model Layers
- **staging/** — cleans and casts raw Snowflake data
- **intermediate/** — business logic, player match aggregations  
- **marts/** — final analytics tables (fct_batting, fct_bowling)

## Run
```bash
dbt run        # build all models
dbt test       # run data quality tests
dbt docs serve # view lineage graph
```
