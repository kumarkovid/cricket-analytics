{{ config(materialized='table') }}

WITH player_match AS (
    SELECT * FROM {{ ref('int_player_match_stats') }}
)

SELECT
    match_id,
    match_date,
    season,
    player_name,
    team,
    balls_bowled,
    runs_conceded,
    wickets,
    economy_rate,
    SUM(wickets) OVER (PARTITION BY player_name ORDER BY match_date) AS career_wickets,
    ROUND(AVG(economy_rate) OVER (PARTITION BY player_name), 2) AS career_economy
FROM player_match
WHERE balls_bowled > 0
