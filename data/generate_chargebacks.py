
import csv
import os
import random
from datetime import datetime, timedelta

random.seed(303)

DATA_DIR = os.path.dirname(__file__)

TRANSACTIONS_FILE = os.path.join(DATA_DIR, "transactions.csv")
CHARGEBACKS_FILE = os.path.join(DATA_DIR, "chargebacks.csv")

CHARGEBACK_RATE = 0.01


def generate_chargebacks():
    with open(
        TRANSACTIONS_FILE, newline="", encoding="utf-8"
    ) as file:
        transactions = list(csv.DictReader(file))

    successful_transactions = [
        row for row in transactions
        if row["status"] == "SUCCESS"
    ]

    candidates = [
        row for row in successful_transactions
        if random.random() < CHARGEBACK_RATE
    ]

    fields = [
        "chargeback_id",
        "transaction_id",
        "merchant_id",
        "chargeback_date",
        "chargeback_amount",
        "chargeback_fee",
        "reason",
        "status",
        "currency",
    ]

    reasons = [
        "FRAUD",
        "DUPLICATE",
        "PRODUCT_NOT_RECEIVED",
        "CUSTOMER_DISPUTE",
    ]

    statuses = ["OPEN", "WON", "LOST", "UNDER_REVIEW"]

    with open(
        CHARGEBACKS_FILE, "w", newline="", encoding="utf-8"
    ) as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for index, transaction in enumerate(candidates, start=1):
            original_amount = float(transaction["amount"])

            transaction_date = datetime.fromisoformat(
                transaction["created_at"]
            )

            chargeback_date = transaction_date + timedelta(
                days=random.randint(7, 60)
            )

            status = random.choices(
                statuses,
                weights=[25, 20, 30, 25],
                k=1,
            )[0]

            writer.writerow({
                "chargeback_id": f"CB-{index:05d}",
                "transaction_id": transaction["transaction_id"],
                "merchant_id": transaction["merchant_id"],
                "chargeback_date": chargeback_date.isoformat(),
                "chargeback_amount": round(original_amount, 2),
                "chargeback_fee": round(random.uniform(100, 500), 2),
                "reason": random.choice(reasons),
                "status": status,
                "currency": "INR",
            })

    print(
        f"Generated {len(candidates):,} chargeback records: "
        f"{CHARGEBACKS_FILE}"
    )


if __name__ == "__main__":
    generate_chargebacks()
