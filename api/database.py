
import os

from sqlalchemy import create_engine
from sqlalchemy.engine import URL


def get_database_url() -> URL:
    username = os.getenv("DB_USER", "postgres")
    password = os.getenv("DB_PASSWORD")
    host = os.getenv("DB_HOST", "localhost")
    port = int(os.getenv("DB_PORT", "5432"))
    database = os.getenv("DB_NAME", "payment_intelligence")

    if not password:
        raise RuntimeError(
            "DB_PASSWORD environment variable is not set."
        )

    return URL.create(
        "postgresql+psycopg",
        username=username,
        password=password,
        host=host,
        port=port,
        database=database,
    )


def create_db_engine():
    return create_engine(
        get_database_url(),
        pool_pre_ping=True,
    )
