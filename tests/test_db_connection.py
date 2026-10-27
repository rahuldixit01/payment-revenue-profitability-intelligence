
from sqlalchemy import text

from api.database import create_db_engine


def test_database_connection():
    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            database_name = connection.execute(
                text("SELECT current_database()")
            ).scalar_one()

            assert database_name == "payment_intelligence"
            print(f"\nConnected successfully to: {database_name}")
    finally:
        engine.dispose()


def test_database_url_rejects_missing_password(monkeypatch):
    import pytest
    from api.database import get_database_url

    monkeypatch.delenv("DB_PASSWORD", raising=False)

    with pytest.raises(
        RuntimeError,
        match="DB_PASSWORD environment variable is not set",
    ):
        get_database_url()
