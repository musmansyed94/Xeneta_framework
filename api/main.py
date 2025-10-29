from fastapi import FastAPI, HTTPException, Query
from typing import List, Dict, Any
from datetime import date
import psycopg
from psycopg.rows import dict_row
from config.config import DB_DSN, QUERY

app = FastAPI(title="Capacity API")

def validate_dates(df: date, dt: date):
    """
    Make sure the provided date range is valid.

    Args:
        df (date): Starting date from the API query.
        dt (date): Ending date from the API query.

    Raises:
        HTTPException: If start date is greater than end date.
    """
    if df > dt:
        raise HTTPException(status_code=400, detail="date_from must be <= date_to")


@app.get("/capacity")
def capacity(
    date_from: date = Query(..., description="Start date in YYYY-MM-DD format"),
    date_to: date = Query(..., description="End date in YYYY-MM-DD format")
) -> List[Dict[str, Any]]:
    """
    API endpoint to get 4-week rolling average of offered capacity (TEU).

    This function connects to the PostgreSQL database, runs the main SQL query
    that calculates weekly offered capacity, and returns a list of results
    between the given date range.

    Args:
        date_from (date): Start date for the capacity calculation.
        date_to (date): End date for the capacity calculation.

    Returns:
        List[Dict[str, Any]]: JSON-style list of weekly capacity records with:
            - week_start_date
            - week_no
            - offered_capacity_teu (4-week rolling average)

    Raises:
        HTTPException: If the database query fails or invalid parameters are given.
    """
    validate_dates(date_from, date_to)
    try:
        with psycopg.connect(DB_DSN, row_factory=dict_row) as conn:
            with conn.cursor() as cur:
                cur.execute(QUERY, {"date_from": date_from, "date_to": date_to})
                return cur.fetchall()
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/health")
def health():
    """
    Simple health check endpoint.

    Returns:
        dict: Status message to confirm the API is running.
    """
    return {"status": "ok"}
