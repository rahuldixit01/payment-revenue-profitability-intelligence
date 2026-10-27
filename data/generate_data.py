
import csv
import os
import random
from datetime import date, datetime, time, timedelta

random.seed(42)

DATA_DIR = os.path.dirname(__file__)
MERCHANT_COUNT = 300
TRANSACTION_COUNT = 20_000

START_DATE = date(2025, 4, 1)
END_DATE = date(2026, 9, 30)

SEGMENTS = ["Small", "Medium", "Large", "Enterprise"]
CITIES = [
    ("Indore", "Madhya Pradesh"),
    ("Mumbai", "Maharashtra"),
    ("Bengaluru", "Karnataka"),
    ("Delhi", "Delhi"),
    ("Hyderabad", "Telangana"),
    ("Pune", "Maharashtra"),
    ("Jaipur", "Rajasthan"),
    ("Lucknow", "Uttar Pradesh"),
    ("Chennai", "Tamil Nadu"),
    ("Ahmedabad", "Gujarat"),
]
MERCHANT_TYPES = [
    "Retail", "Electronics", "Fashion", "Food",
    "Healthcare", "Travel", "Education", "Home"
]
PAYMENT_METHODS = ["UPI", "CARD", "NET_BANKING", "WALLET"]


def generate_merchants():
    merchants = []
    file_path = os.path.join(DATA_DIR, "merchants.csv")

    with open(file_path, "w", newline="", encoding="utf-8") as file:
        fields = [
            "merchant_id", "merchant_name", "segment",
            "merchant_type", "city", "state",
            "onboarding_date", "fee_rate_pct",
        ]
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for number in range(1, MERCHANT_COUNT + 1):
            city, state = random.choice(CITIES)
            onboarding = START_DATE + timedelta(
                days=random.randint(0, (END_DATE - START_DATE).days)
            )
            segment = random.choice(SEGMENTS)

            merchant = {
                "merchant_id": f"MER-{number:04d}",
                "merchant_name": f"Merchant {number:03d}",
                "segment": segment,
                "merchant_type": random.choice(MERCHANT_TYPES),
                "city": city,
                "state": state,
                "onboarding_date": onboarding.isoformat(),
                "fee_rate_pct": round(random.uniform(1.2, 2.2), 2),
            }
            merchants.append(merchant)
            writer.writerow(merchant)

    return merchants


def generate_transactions(merchants):
    file_path = os.path.join(DATA_DIR, "transactions.csv")
    total_days = (END_DATE - START_DATE).days

    fields = [
        "transaction_id", "merchant_id", "payment_method",
        "amount", "currency", "status", "created_at",
    ]

    with open(file_path, "w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=fields)
        writer.writeheader()

        for number in range(1, TRANSACTION_COUNT + 1):
            merchant = random.choice(merchants)
            transaction_date = START_DATE + timedelta(
                days=random.randint(0, total_days)
            )
            transaction_time = datetime.combine(
                transaction_date,
                time(
                    hour=random.randint(0, 23),
                    minute=random.randint(0, 59),
                    second=random.randint(0, 59),
                ),
            )

            # Deliberately varied payment outcomes; not all attempts succeed.
            status = random.choices(
                ["SUCCESS", "FAILED", "CANCELLED"],
                weights=[85, 10, 5],
                k=1,
            )[0]

            amount = round(random.uniform(100, 25_000), 2)

            writer.writerow({
                "transaction_id": f"TXN-{number:06d}",
                "merchant_id": merchant["merchant_id"],
                "payment_method": random.choice(PAYMENT_METHODS),
                "amount": amount,
                "currency": "INR",
                "status": status,
                "created_at": transaction_time.isoformat(),
            })

    print(f"Generated {TRANSACTION_COUNT:,} payment attempts: {file_path}")




def generate_transaction_fees():
    transactions_path = os.path.join(DATA_DIR, "transactions.csv")
    merchants_path = os.path.join(DATA_DIR, "merchants.csv")
    fees_path = os.path.join(DATA_DIR, "transaction_fees.csv")

    with open(merchants_path, newline="", encoding="utf-8") as source:
        merchants = {
            row["merchant_id"]: row
            for row in csv.DictReader(source)
        }

    with open(transactions_path, newline="", encoding="utf-8") as source:
        transactions = list(csv.DictReader(source))

    fee_fields = [
        "fee_id",
        "transaction_id",
        "gross_fee_revenue",
        "processing_cost",
        "fee_reversal",
    ]

    processing_cost_rates = {
        "UPI": 0.005,
        "CARD": 0.014,
        "NET_BANKING": 0.008,
        "WALLET": 0.010,
    }

    # Use a separate random generator so reversal scenarios
    # remain reproducible without affecting other generators.
    reversal_rng = random.Random(20261026)
    reversal_share = 0.05

    fee_records = []

    for transaction in transactions:
        if transaction["status"] != "SUCCESS":
            continue

        amount = float(transaction["amount"])
        merchant = merchants[transaction["merchant_id"]]
        fee_rate = float(merchant["fee_rate_pct"]) / 100

        gross_fee = round(amount * fee_rate, 2)
        processing_cost = round(
            amount * processing_cost_rates[
                transaction["payment_method"]
            ],
            2,
        )

        fee_records.append({
            "fee_id": f"FEE-{len(fee_records) + 1:06d}",
            "transaction_id": transaction["transaction_id"],
            "gross_fee_revenue": gross_fee,
            "processing_cost": processing_cost,
            "fee_reversal": 0.00,
        })

    # Select 5% of eligible fee records for reversal.
    reversal_count = round(len(fee_records) * reversal_share)
    selected_indices = reversal_rng.sample(
        range(len(fee_records)),
        reversal_count,
    )

    full_count = 0
    partial_count = 0

    for index in selected_indices:
        record = fee_records[index]
        gross_fee = float(record["gross_fee_revenue"])

        # Mix full and partial reversals.
        if reversal_rng.random() < 0.5:
            reversal_amount = gross_fee
            full_count += 1
        else:
            reversal_amount = round(
                gross_fee * reversal_rng.uniform(0.20, 0.80),
                2,
            )

            # Keep partial reversals strictly below the full fee.
            reversal_amount = min(
                reversal_amount,
                round(gross_fee - 0.01, 2),
            )
            partial_count += 1

        record["fee_reversal"] = reversal_amount

    with open(fees_path, "w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=fee_fields)
        writer.writeheader()
        writer.writerows(fee_records)

    print(f"Generated {len(fee_records):,} fee records: {fees_path}")
    print(f"Records with reversals: {reversal_count:,}")
    print(f"Full reversals: {full_count:,}")
    print(f"Partial reversals: {partial_count:,}")


if __name__ == "__main__":
    merchant_data = generate_merchants()
    generate_transactions(merchant_data)
    generate_transaction_fees()
    print(f"Generated {len(merchant_data)} merchants.")
