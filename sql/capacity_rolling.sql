/* 
===============================================================
Capacity Rolling Average Query
===============================================================
*/

WITH 
-- Step 1: Generate continuous weekly date range between inputs
w AS (
  SELECT *
  FROM weeks_between(%(date_from)s::date, %(date_to)s::date)
),

-- Step 2: Join with aggregated weekly capacity data
--         Ensures all weeks exist even if no sailings (COALESCE -> 0)
j AS (
  SELECT 
    w.week_start_date,
    COALESCE(vc.offered_capacity_teu, 0)::bigint AS offered_capacity_teu
  FROM w
  LEFT JOIN v_weekly_capacity vc 
    USING (week_start_date)
),

-- Step 3: Compute week number and 4-week rolling average
--         Uses window function to average current + 3 preceding weeks
r AS (
  SELECT 
    week_start_date,
    EXTRACT(week FROM week_start_date)::int AS week_no,
    offered_capacity_teu,
    ROUND(
      AVG(offered_capacity_teu)
      OVER (
        ORDER BY week_start_date
        ROWS BETWEEN 3 PRECEDING AND CURRENT ROW
      )
    )::bigint AS offered_capacity_teu_4wk_rolling
  FROM j
)

-- Step 4: Final output - formatted and ordered results
SELECT 
  week_start_date::text,
  week_no,
  offered_capacity_teu_4wk_rolling AS offered_capacity_teu
FROM r
ORDER BY week_start_date;
