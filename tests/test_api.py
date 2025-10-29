"""
Unit tests for the Capacity API (FastAPI + PostgreSQL).

Covers:
1. Basic health endpoint check
2. Capacity endpoint structure validation (mocked DB)
3. Verification of the SQL weeks_between() function
"""

import pytest
import psycopg
from psycopg.rows import dict_row
from config.config import DB_DSN
from fastapi.testclient import TestClient
from api.main import app

# Create a reusable test client for the FastAPI app
client = TestClient(app)


def test_health_check():
    """
    Verify that the /health endpoint works correctly.

    Expected:
    - Status code: 200
    - JSON response: {"status": "ok"}
    """
    response = client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


def test_capacity_endpoint_structure(monkeypatch):
    """
    Validate that the /capacity endpoint returns a correctly structured JSON response.

    This test uses monkeypatching to replace the real PostgreSQL connection
    with a mock connection that simulates expected query results.
    """
    # Mocked query output
    sample_data = [
        {"week_start_date": "2024-01-01", "week_no": 1, "offered_capacity_teu": 120000},
        {"week_start_date": "2024-01-08", "week_no": 2, "offered_capacity_teu": 130000}
    ]

    # Define a simple mock connection and cursor class
    import api.main as main

    class MockConn:
        def cursor(self): return self
        def __enter__(self): return self
        def __exit__(self, *args): pass
        def execute(self, *args, **kwargs): pass
        def fetchall(self): return sample_data

    # Replace psycopg.connect with our mock connection
    monkeypatch.setattr(main.psycopg, "connect", lambda *a, **kw: MockConn())

    # Make a test request
    response = client.get("/capacity?date_from=2024-01-01&date_to=2024-03-31")

    # Validate response
    assert response.status_code == 200
    result = response.json()
    assert isinstance(result, list)
    assert all("week_start_date" in i for i in result)
    assert all("offered_capacity_teu" in i for i in result)


def test_weeks_between_function():
    """
    Test the weeks_between() SQL function directly in PostgreSQL.

    Ensures that the function generates one entry per Monday between the
    given date range (inclusive of start week).
    """
    print("DB_DSN =", DB_DSN)
    with psycopg.connect(DB_DSN, row_factory=dict_row) as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*) AS cnt
                FROM weeks_between('2024-01-01', '2024-01-29');
            """)
            result = cur.fetchone()
            assert result["cnt"] == 5  # Expect 5 Mondays between Jan 1–29
