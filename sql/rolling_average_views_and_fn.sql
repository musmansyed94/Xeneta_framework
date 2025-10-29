/* 
=====================================================================
  VIEWS & FUNCTION SETUP FOR WEEKLY CAPACITY CALCULATION
=====================================================================
*/


/* ------------------------------------------------------------
   1)  Create a view for the latest departure per unique trip
   ------------------------------------------------------------
   Purpose:
     - Identify the most recent sailing record for each unique
       vessel and service combination.
     - Limit to corridor: china_main - north_europe_main
     - Ensures no duplicate vessel trips are included.
------------------------------------------------------------- */

DROP VIEW IF EXISTS v_latest_departures CASCADE;

CREATE VIEW v_latest_departures AS
SELECT DISTINCT ON (
  service_version_and_roundtrip_identifiers,
  origin_service_version_and_master,
  destination_service_version_and_master
)
  service_version_and_roundtrip_identifiers,
  origin_service_version_and_master,
  destination_service_version_and_master,
  origin,
  destination,
  origin_port_code,
  destination_port_code,
  origin_at_utc,
  offered_capacity_teu
FROM sailing_level_raw
WHERE origin = 'china_main'
  AND destination = 'north_europe_main'
ORDER BY
  service_version_and_roundtrip_identifiers,
  origin_service_version_and_master,
  destination_service_version_and_master,
  origin_at_utc DESC;



/* ------------------------------------------------------------
   2)  Create a view to aggregate weekly capacity
   ------------------------------------------------------------
   Purpose:
     - Aggregate total offered capacity (TEU) per week.
     - Uses UTC timezone alignment to standardize week grouping.
     - Weeks start on Monday (via date_trunc('week', ...)).
------------------------------------------------------------- */

DROP VIEW IF EXISTS v_weekly_capacity CASCADE;

CREATE VIEW v_weekly_capacity AS
WITH base AS (
  SELECT
    (date_trunc('week', origin_at_utc AT TIME ZONE 'UTC'))::date AS week_start_date,
    offered_capacity_teu
  FROM v_latest_departures
)
SELECT
  week_start_date,
  SUM(offered_capacity_teu)::bigint AS offered_capacity_teu
FROM base
GROUP BY week_start_date
ORDER BY week_start_date;



/* ------------------------------------------------------------
   3)  Helper function: weeks_between()
   ------------------------------------------------------------
   Purpose:
     - Generate a continuous series of weekly start dates
       between two given dates.
     - Ensures missing weeks (no sailings) still appear in the
       output for rolling average calculations.
------------------------------------------------------------- */

DROP FUNCTION IF EXISTS weeks_between(date, date);

CREATE FUNCTION weeks_between(dfrom date, dto date)
RETURNS TABLE(week_start_date date)
LANGUAGE sql AS $$
  SELECT gs::date
  FROM generate_series(
         date_trunc('week', dfrom::timestamp)::date,  -- Round start date to week start (Monday)
         date_trunc('week', dto::timestamp)::date,    -- Round end date to week start (Monday)
         interval '1 week'                            -- Increment by 1 week
       ) gs
$$;
