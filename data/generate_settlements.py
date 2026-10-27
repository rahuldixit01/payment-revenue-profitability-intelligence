
import csv
import os
import random
from collections import defaultdict
from datetime import datetime, timedelta

random.seed(101)

DATA_DIR = os.path.dirname(__file__)

TRANSACTIONS_FILE = os.path.join(DATA_DIR, "transactions.csv")
FEES_FILE = os.path.join(DATA_DIR, "transaction_fees.csv")
SETTLEMENTS_FILE = os.path.join(DATA_DIR, "settlements.csv")


def generate_settlements():
    with open(TRANSACTIONS_FILE, newline="", encoding="utf-8") as file:
        transactions = list(csv.DictReader(file))

    with open(FEES_FILE, newline="", encoding="utf-8") as file:
        fees = list(csv.DictReader(file))

    fee_by_transaction = {
        row["transaction_id"]: row for row in fees
    }

    # Group successful payments by merchant and settlement date.
    groups = defaultdict(list)

    for transaction in transactions:
        if transaction["status"] != "SUCCESS":
            continue

        fee = fee_by_transaction[transaction["transaction_id"]]
        transaction_date = datetime.fromisoformat(
            transaction["created_at"]
        ).date()

        settlement_date = transaction_date + timedelta(days=2)

        groups[
            (transaction["merchant_id"], settlement_date)
        ].append((transaction, fee))

    fields = [
        "settlement_id",
        "merchant_id",
        "settlement_date",
        "transaction_count",
        "expected_amount",
        "actual_amount",
        "currency",
    ]

    settlement_count = 0

    with open(
        SETTLEMENTS_FILE, "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for (merchant_id, settlement_date), items in sorted(groups.items()):
            expected_amount = sum(
                float(transaction["amount"])
                - float(fee["gross_fee_revenue"])
                for transaction, fee in items
            )

            # Controlled settlement differences for reconciliation testing.
            variance = random.choices(
                [0.00, -25.00, 25.00, -100.00, 100.00],
                weights=[90, 3, 3, 2, 2],
                k=1,
            )[0]

            actual_amount = round(expected_amount + variance, 2)

            settlement_count += 1
            writer.writerow({
                "settlement_id": f"SET-{settlement_count:06d}",
                "merchant_id": merchant_id,
                "settlement_date": settlement_date.isoformat(),
                "transaction_count": len(items),
                "expected_amount": round(expected_amount, 2),
                "actual_amount": actual_amount,
                "currency": "INR",
            })

    print(
        f"Generated {settlement_count:,} settlement records: "
        f"{SETTLEMENTS_FILE}"
    )


if __name__ == "__main__":
    generate_settlements()
