# Capacity API (FastAPI + PostgreSQL)

This project provides a small API that returns **weekly offered capacity (TEU)** and its **4-week rolling average** from shipping data stored in PostgreSQL.  
It includes unit and integration tests to validate database logic, API behavior, and endpoint structure.

---

## Folder structure

```
.
├─ api/
│  └─ main.py
├─ config/
│  └─ config.py
├─ sql/
│  ├─ capacity_rolling.sql
│  ├─ rolling_average_views_and_fn.sql
│  ├─ sample_query.sql
│  └─ schema_design.sql
├─ tests/
│  └─ test_api.py
├─ .env
├─ requirements.txt
└─ README.md
```

---

## Requirements

- Python **3.10 or newer**
- PostgreSQL **14 or newer** (make sure `psql` works from terminal)
- PowerShell (if using Windows)
- Virtual environment support (`venv`)
- Optional for tests: `pytest`, `pytest-cov`, `httpx`

---

## Environment variables

Create a `.env` file in the project root:

```
DB_DSN=postgresql://ship_eng:shipsec@localhost/shipping_capacity
SQL_FILE_PATH=sql/capacity_rolling.sql
```

---

## Step 1: Create database and user

Open PowerShell and connect as the `postgres` user or superuser if different:

```powershell
psql -U postgres
```

Then run:

```sql
DROP DATABASE IF EXISTS shipping_capacity;
DROP ROLE IF EXISTS ship_eng;

CREATE USER ship_eng WITH PASSWORD 'shipsec';
CREATE DATABASE shipping_capacity OWNER ship_eng;
GRANT ALL PRIVILEGES ON DATABASE shipping_capacity TO ship_eng;
\q
```

---

## Step 2: Set up base schema

You must already be inside `psql` and connected to your database:

```bash
psql -U ship_eng -d shipping_capacity
```

Then run the schema file to create the base table. Please update the below path accordingly:

```sql
\i '<path_to_project>/sql/schema_design.sql'
```

This creates the table `sailing_level_raw`.

---

## Step 3: Load data

If you have a CSV file in a folder named `data`. Please update the DB path accordingly:

```sql
\copy sailing_level_raw(origin,destination,origin_port_code,destination_port_code,service_version_and_roundtrip_identifiers,origin_service_version_and_master,destination_service_version_and_master,origin_at_utc,offered_capacity_teu) FROM '<path_to_dataset>/sailing_level_raw.csv' WITH (FORMAT csv, HEADER true);
```

Check your data:

```sql
SELECT COUNT(*) FROM sailing_level_raw;
SELECT * FROM sailing_level_raw LIMIT 5;
```

---

## Step 4: Run SQL scripts to create views and functions

After loading the CSV file, run the SQL files that create the views and helper functions used by the API.  
This ensures that views like `v_latest_departures`, `v_weekly_capacity`, and the function `weeks_between()` are properly created.
Please update the below path accordingly.

From inside `psql`:

```sql
\i '<path_to_project>/sql/rolling_average_views_and_fn.sql'
\i '<path_to_project>/sql/sample_query.sql'
```

If you see messages such as:

```
NOTICE:  view "v_latest_departures" does not exist, skipping
NOTICE:  view "v_weekly_capacity" does not exist, skipping
```

That is normal. It means the views didnt exist before and were created fresh.

You can verify that everything loaded correctly:

```sql
\dv
\df weeks_between
```

---

## Step 5: Run the API

Create a virtual environment and install dependencies from root directory:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Start the API server from root directory:

```powershell
python -m uvicorn api.main:app --reload
```

You should see:

```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

---

## Step 6: Test endpoints manually

### Health check

```
GET http://127.0.0.1:8000/health
```

Expected result:

```json
{"status": "ok"}
```

### Main capacity endpoint

```
GET http://127.0.0.1:8000/capacity?date_from=2024-01-01&date_to=2024-03-31
```

---

## Step 7: Running automated tests

Tests are located in the `tests/` folder and use `pytest` and `FastAPI`’s built-in `TestClient`.

### Install test dependencies

```bash
python -m pip install pytest httpx pytest-cov
```

### Run all tests

From the root level, run all tests:

```bash
python -m pytest -v
```

You should see:

```
tests/test_api.py::test_health_check PASSED
tests/test_api.py::test_capacity_endpoint_structure PASSED
tests/test_api.py::test_weeks_between_function PASSED
================== 3 passed in 0.45s ==================
```

---

### Run with coverage report

You can also check code coverage from root level:

```bash
python -m pytest --cov=api --cov-report=term-missing
```

---

### Test overview

| Test | Purpose |
|------|----------|
| `test_health_check` | Ensures `/health` endpoint returns `200 OK` and valid JSON. |
| `test_capacity_endpoint_structure` | Validates that `/capacity` returns correct JSON keys (`week_start_date`, `week_no`, `offered_capacity_teu`). Uses mocked database calls for isolation. |
| `test_weeks_between_function` | Integration test for PostgreSQL function `weeks_between()` ensuring correct weekly sequence generation. |

---

## Step 8: SQL file overview

| File | Description |
|------|--------------|
| `schema_design.sql` | Creates base table (`sailing_level_raw`). |
| `rolling_average_views_and_fn.sql` | Defines helper functions and intermediate views. |
| `capacity_rolling.sql` | Final query used by the API. |
| `sample_query.sql` | Manual test queries. |

---

## Step 9: Common issues

| Problem | Solution |
|----------|-----------|
| `.env` not loading | Ensure `python-dotenv` is installed and you start from project root. |
| `ModuleNotFoundError: No module named 'config'` | Run with `python -m uvicorn api.main:app --reload` (not from inside `/api`). |
| Encoding errors | Save SQL files as UTF-8. |
| All zeros in output | Check if data exists with `SELECT COUNT(*) FROM sailing_level_raw;`. |
| Permission denied for view | Run: `GRANT SELECT ON ALL TABLES IN SCHEMA public TO ship_eng; GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO ship_eng;`. |
