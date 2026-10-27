
import csv
import os
import random
from datetime import datetime, timedelta

random.seed(202)

DATA_DIR = os.path.dirname(__file__)

TRANSACTIONS_FILE = os.path.join(DATA_DIR, "transactions.csv")
REFUNDS_FILE = os.path.join(DATA_DIR, "refunds.csv")

REFUND_RATE = 0.04


def generate_refunds():
    with open(
        TRANSACTIONS_FILE, newline="", encoding="utf-8"
    ) as file:
        transactions = list(csv.DictReader(file))

    successful_transactions = [
        row for row in transactions
        if row["status"] == "SUCCESS"
    ]

    refund_candidates = [
        row for row in successful_transactions
        if random.random() < REFUND_RATE
    ]

    fields = [
        "refund_id",
        "transaction_id",
        "merchant_id",
        "refund_date",
        "refund_amount",
        "refund_type",
        "status",
        "currency",
    ]

    with open(
        REFUNDS_FILE, "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for index, transaction in enumerate(refund_candidates, start=1):
            original_amount = float(transaction["amount"])

            refund_type = random.choices(
                ["FULL", "PARTIAL"],
                weights=[70, 30],
                k=1,
            )[0]

            if refund_type == "FULL":
                refund_amount = original_amount
            else:
                refund_amount = round(
                    original_amount * random.uniform(0.10, 0.80), 2
                )

            transaction_date = datetime.fromisoformat(
                transaction["created_at"]
            )

            refund_date = transaction_date + timedelta(
                days=random.randint(1, 30)
            )

            status = random.choices(
                ["COMPLETED", "PENDING", "FAILED"],
                weights=[85, 10, 5],
                k=1,
            )[0]

            writer.writerow({
                "refund_id": f"REF-{index:06d}",
                "transaction_id": transaction["transaction_id"],
                "merchant_id": transaction["merchant_id"],
                "refund_date": refund_date.isoformat(),
                "refund_amount": round(refund_amount, 2),
                "refund_type": refund_type,
                "status": status,
                "currency": "INR",
            })

    print(
        f"Generated {len(refund_candidates):,} refund records: "
        f"{REFUNDS_FILE}"
    )


if __name__ == "__main__":
    generate_refunds()
