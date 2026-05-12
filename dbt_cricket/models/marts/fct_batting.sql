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
    runs_scored,
    balls_faced,
    strike_rate,
    fours,
    sixes,
    SUM(runs_scored) OVER (PARTITION BY player_name ORDER BY match_date) AS career_runs,
    COUNT(match_id) OVER (PARTITION BY player_name ORDER BY match_date) AS matches_played,
    ROUND(AVG(runs_scored) OVER (PARTITION BY player_name), 2) AS career_average
FROM player_match
WHERE balls_faced > 0
