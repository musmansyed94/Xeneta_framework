-- Example window: 2024-01-01 .. 2024-03-31
WITH w AS (
  SELECT * FROM weeks_between('2024-01-01'::date, '2024-03-31'::date)
),
j AS (
  SELECT w.week_start_date,
         COALESCE(vc.offered_capacity_teu, 0)::bigint AS offered_capacity_teu
  FROM w
  LEFT JOIN v_weekly_capacity vc USING (week_start_date)
),
r AS (
  SELECT week_start_date,
         EXTRACT(week FROM week_start_date)::int AS week_no,
         offered_capacity_teu,
         ROUND(AVG(offered_capacity_teu)
               OVER (ORDER BY week_start_date
                     ROWS BETWEEN 3 PRECEDING AND CURRENT ROW))::bigint
           AS offered_capacity_teu_4wk_rolling
  FROM j
)
SELECT week_start_date, week_no, offered_capacity_teu_4wk_rolling AS offered_capacity_teu
FROM r
ORDER BY week_start_date;
