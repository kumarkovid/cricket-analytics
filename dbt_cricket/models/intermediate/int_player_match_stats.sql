WITH deliveries AS (
    SELECT * FROM {{ ref('stg_deliveries') }}
),

batting AS (
    SELECT
        match_id,
        match_date,
        season,
        batter AS player_name,
        batting_team AS team,
        COUNT(*) AS balls_faced,
        SUM(runs_off_bat) AS runs_scored,
        SUM(CASE WHEN runs_off_bat = 4 THEN 1 ELSE 0 END) AS fours,
        SUM(CASE WHEN runs_off_bat = 6 THEN 1 ELSE 0 END) AS sixes,
        ROUND(SUM(runs_off_bat) / NULLIF(COUNT(*), 0) * 100, 2) AS strike_rate
    FROM deliveries
    GROUP BY 1, 2, 3, 4, 5
),

bowling AS (
    SELECT
        match_id,
        bowler AS player_name,
        COUNT(*) AS balls_bowled,
        SUM(total_runs) AS runs_conceded,
        SUM(is_wicket) AS wickets,
        ROUND(SUM(total_runs) / NULLIF(COUNT(*) / 6.0, 0), 2) AS economy_rate
    FROM deliveries
    WHERE wides = 0 AND noballs = 0
    GROUP BY 1, 2
)

SELECT
    b.match_id,
    b.match_date,
    b.season,
    b.player_name,
    b.team,
    b.balls_faced,
    b.runs_scored,
    b.fours,
    b.sixes,
    b.strike_rate,
    bw.balls_bowled,
    bw.runs_conceded,
    bw.wickets,
    bw.economy_rate
FROM batting b
LEFT JOIN bowling bw
    ON b.match_id = bw.match_id
    AND b.player_name = bw.player_name
