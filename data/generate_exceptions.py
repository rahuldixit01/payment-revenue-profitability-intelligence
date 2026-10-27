
import csv
import os
import random
from datetime import datetime, timedelta

random.seed(404)

DATA_DIR = os.path.dirname(__file__)

TRANSACTIONS_FILE = os.path.join(DATA_DIR, "transactions.csv")
SETTLEMENTS_FILE = os.path.join(DATA_DIR, "settlements.csv")
EXCEPTIONS_FILE = os.path.join(DATA_DIR, "reconciliation_exceptions.csv")

EXCEPTION_RATE = 0.02


def generate_exceptions():
    with open(
        TRANSACTIONS_FILE, newline="", encoding="utf-8"
    ) as file:
        transactions = list(csv.DictReader(file))

    with open(
        SETTLEMENTS_FILE, newline="", encoding="utf-8"
    ) as file:
        settlements = list(csv.DictReader(file))

    successful_transactions = [
        row for row in transactions
        if row["status"] == "SUCCESS"
    ]

    settlement_by_merchant_date = {
        (row["merchant_id"], row["settlement_date"]): row
        for row in settlements
    }

    candidates = [
        row for row in successful_transactions
        if random.random() < EXCEPTION_RATE
    ]

    fields = [
        "exception_id",
        "transaction_id",
        "merchant_id",
        "settlement_id",
        "exception_date",
        "exception_type",
        "exception_amount",
        "severity",
        "status",
        "confirmed_financial_impact",
        "expected_classification",
        "currency",
    ]

    exception_types = [
        "MISSING_SETTLEMENT",
        "AMOUNT_MISMATCH",
        "FEE_MISMATCH",
        "DUPLICATE_RECORD",
        "TIMING_DIFFERENCE",
    ]

    severity_weights = ["LOW", "MEDIUM", "HIGH"]
    status_weights = ["OPEN", "UNDER_REVIEW", "RESOLVED"]

    with open(
        EXCEPTIONS_FILE, "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for index, transaction in enumerate(candidates, start=1):
            transaction_date = datetime.fromisoformat(
                transaction["created_at"]
            )

            settlement_date = (
                transaction_date + timedelta(days=2)
            ).date().isoformat()

            settlement = settlement_by_merchant_date.get(
                (transaction["merchant_id"], settlement_date)
            )

            exception_type = random.choice(exception_types)
            severity = random.choices(
                severity_weights,
                weights=[50, 35, 15],
                k=1,
            )[0]
            status = random.choices(
                status_weights,
                weights=[50, 30, 20],
                k=1,
            )[0]

            original_amount = float(transaction["amount"])

            if exception_type == "MISSING_SETTLEMENT":
                exception_amount = original_amount
            elif exception_type == "AMOUNT_MISMATCH":
                exception_amount = round(
                    original_amount * random.uniform(0.01, 0.10), 2
                )
            elif exception_type == "FEE_MISMATCH":
                exception_amount = round(
                    original_amount * random.uniform(0.001, 0.02), 2
                )
            elif exception_type == "DUPLICATE_RECORD":
                exception_amount = original_amount
            else:
                exception_amount = round(
                    original_amount * random.uniform(0.01, 0.05), 2
                )

            # This is a synthetic scenario label for validation,
            # not an automatically verified financial outcome.
            expected_classification = (
                "EXPOSURE_ONLY"
                if exception_type in [
                    "MISSING_SETTLEMENT",
                    "TIMING_DIFFERENCE",
                ]
                else "REQUIRES_INVESTIGATION"
            )

            confirmed_impact = 0.0

            writer.writerow({
                "exception_id": f"EXC-{index:05d}",
                "transaction_id": transaction["transaction_id"],
                "merchant_id": transaction["merchant_id"],
                "settlement_id": (
                    settlement["settlement_id"] if settlement else ""
                ),
                "exception_date": transaction_date.date().isoformat(),
                "exception_type": exception_type,
                "exception_amount": round(exception_amount, 2),
                "severity": severity,
                "status": status,
                "confirmed_financial_impact": confirmed_impact,
                "expected_classification": expected_classification,
                "currency": "INR",
            })

    print(
        f"Generated {len(candidates):,} reconciliation exceptions: "
        f"{EXCEPTIONS_FILE}"
    )


if __name__ == "__main__":
    generate_exceptions()
