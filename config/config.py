import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Database connection string (from .env)
DB_DSN = os.getenv("DB_DSN")
if not DB_DSN:
    raise ValueError("DB_DSN not found. Please set it in your .env file.")

# SQL file path (from .env or default)
SQL_FILE_PATH = os.getenv("SQL_FILE_PATH", "sql/capacity_rolling.sql")

# Resolve and read SQL file
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SQL_FILE = os.path.join(BASE_DIR, SQL_FILE_PATH)

with open(SQL_FILE, "r", encoding="utf-8") as f:
    QUERY = f.read()
