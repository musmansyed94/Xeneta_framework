# Capacity API (FastAPI + PostgreSQL)

This project provides a small API that returns **weekly offered capacity (TEU)** and its **4-week rolling average** from shipping data stored in PostgreSQL.

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

---

## Environment variables

Create a `.env` file in the project root:

```
DB_DSN=postgresql://ship_eng:shipsec@localhost/shipping_capacity
SQL_FILE_PATH=sql/capacity_rolling.sql
```

---

## Step 1: Create database and user

Open PowerShell and connect as the `postgres` user:

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

Then run the schema file to create the base table:

```sql
\i 'C:/path/to/project/sql/schema_design.sql'
```

This creates the table `sailing_level_raw`.

---

## Step 3: Load data

If you have a CSV file in a folder named `data`:

```sql
\copy sailing_level_raw(
  origin,
  destination,
  origin_port_code,
  destination_port_code,
  service_version_and_roundtrip_identifiers,
  origin_service_version_and_master,
  destination_service_version_and_master,
  origin_at_utc,
  offered_capacity_teu
)
FROM 'C:/path/to/your/data/sailing_level_raw.csv'
WITH (FORMAT csv, HEADER true);
```

Check your data:

```sql
SELECT COUNT(*) FROM sailing_level_raw;
SELECT * FROM sailing_level_raw LIMIT 5;
```

---

## Step 4: Run SQL scripts to create views and functions

After loading the CSV file, run the SQL files that create the views and helper functions used by the API.
This ensures views like `v_latest_departures`, `v_weekly_capacity`, and the function `weeks_between()` are available.

From inside `psql`:

```sql
\i 'C:/path/to/project/sql/rolling_average_views_and_fn.sql'
\i 'C:/path/to/project/sql/sample_query.sql'
```

If you see messages such as:

```
NOTICE:  view "v_latest_departures" does not exist, skipping
NOTICE:  view "v_weekly_capacity" does not exist, skipping
```

Thats normal. It means the views didnt exist before and were created fresh.

Verify that everything loaded correctly:

```sql
\dv
\df weeks_between
```

---

## Step 5: Run the API

Create a virtual environment and install dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
```

Start the API server:

```powershell
python -m uvicorn api.main:app --reload
```

You should see:

```
INFO:     Uvicorn running on http://127.0.0.1:8000
```

---

## Step 6: Test endpoints

### Health check

```
GET http://127.0.0.1:8000/health
```

Expected result:

```
{"status": "ok"}
```

### Main capacity endpoint

```
GET http://127.0.0.1:8000/capacity?date_from=2024-01-01&date_to=2024-03-31
```

---

## SQL file overview

| File | Description |
|------|--------------|
| `schema_design.sql` | Creates base table (`sailing_level_raw`) |
| `rolling_average_views_and_fn.sql` | Defines helper functions and intermediate views |
| `capacity_rolling.sql` | Final query used by the API |
| `sample_query.sql` | Manual test queries |
