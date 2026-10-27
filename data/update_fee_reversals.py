
import csv
import getpass
from pathlib import Path

from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL

DATA_DIR = Path(__file__).resolve().parent
CSV_FILE = DATA_DIR / "transaction_fees.csv"


def main():
    username = input("PostgreSQL username: ")
    password = getpass.getpass("PostgreSQL password: ")

    url = URL.create(
        "postgresql+psycopg",
        username=username,
        password=password,
        host="localhost",
        port=5432,
        database="payment_intelligence",
    )

    engine = create_engine(url)

    try:
        with CSV_FILE.open(
            "r", encoding="utf-8-sig", newline=""
        ) as file:
            rows = [
                {
                    "transaction_id": row["transaction_id"],
                    "fee_reversal": row["fee_reversal"],
                }
                for row in csv.DictReader(file)
            ]

        
        with engine.begin() as connection:
            db_name = connection.execute(
                text("SELECT current_database()")
            ).scalar_one()

            if db_name != "payment_intelligence":
                raise RuntimeError(f"Unexpected database: {db_name}")

            csv_ids = [row["transaction_id"] for row in rows]

            if len(rows) != 16994 or len(set(csv_ids)) != 16994:
                raise RuntimeError(
                    "CSV validation failed: expected 16,994 unique records."
                )

            existing_count = connection.execute(
                text("""
                    SELECT COUNT(*)
                    FROM transaction_fees
                    WHERE transaction_id = ANY(:ids)
                """),
                {"ids": csv_ids},
            ).scalar_one()

            if existing_count != 16994:
                raise RuntimeError(
                    f"Only {existing_count} CSV IDs matched the database. "
                    "No update performed."
                )

            updated = connection.execute(
                text("""
                    UPDATE transaction_fees AS target
                    SET fee_reversal = source.fee_reversal
                    FROM jsonb_to_recordset(CAST(:rows AS jsonb))
                    AS source(
                        transaction_id TEXT,
                        fee_reversal NUMERIC(12, 2)
                    )
                    WHERE target.transaction_id = source.transaction_id
                """),
                {"rows": __import__("json").dumps(rows)},
            )

            if updated.rowcount != 16994:
                raise RuntimeError(
                    f"Expected 16,994 updates; got {updated.rowcount}."
                )

            result = connection.execute(text("""
                SELECT
                    COUNT(*) AS fee_records,
                    COUNT(DISTINCT transaction_id) AS unique_ids,
                    SUM(gross_fee_revenue) AS gross_fee_revenue,
                    SUM(fee_reversal) AS total_reversals,
                    SUM(gross_fee_revenue - fee_reversal) AS net_revenue
                FROM transaction_fees
            """)).one()

            print(f"Rows updated: {updated.rowcount:,}")
            print(f"Fee records: {result.fee_records:,}")
            print(f"Unique transactions: {result.unique_ids:,}")
            print(f"Gross fee revenue: ₹{result.gross_fee_revenue:,.2f}")
            print(f"Fee reversals: ₹{result.total_reversals:,.2f}")
            print(f"Net revenue: ₹{result.net_revenue:,.2f}")


    finally:
        engine.dispose()


if __name__ == "__main__":
    main()
