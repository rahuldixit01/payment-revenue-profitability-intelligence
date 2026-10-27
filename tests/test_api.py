
from fastapi.testclient import TestClient

from api.main import app

client = TestClient(app)


def test_health_endpoint():
    response = client.get("/health")

    assert response.status_code == 200
    assert response.json()["status"] == "healthy"


def test_analytics_overview_endpoint():
    response = client.get("/analytics/overview")

    assert response.status_code == 200

    data = response.json()

    assert data["total_attempts"] == 20000
    assert data["successful_transactions"] == 16994
    assert data["failed_transactions"] == 2057
    assert data["cancelled_transactions"] == 949

    assert data["success_rate_pct"] == 84.97
    assert data["total_payment_volume"] == 213374487.23
    assert data["net_fee_revenue"] == 3523251.86
    assert data["contribution_profit"] == 1540961.91
    assert data["contribution_margin_pct"] == 43.74


def test_analytics_response_contains_expected_fields():
    response = client.get("/analytics/overview")

    assert response.status_code == 200

    expected_fields = {
        "total_attempts",
        "successful_transactions",
        "failed_transactions",
        "cancelled_transactions",
        "total_payment_volume",
        "gross_fee_revenue",
        "fee_reversals",
        "net_fee_revenue",
        "processing_cost",
        "success_rate_pct",
        "contribution_profit",
        "contribution_margin_pct",
    }

    assert expected_fields.issubset(response.json().keys())

def test_merchant_profitability_endpoint():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability?limit=10"
        )

    assert response.status_code == 200

    data = response.json()
    assert len(data) == 10

    required_fields = {
        "merchant_id",
        "merchant_name",
        "successful_transactions",
        "tpv",
        "net_fee_revenue",
        "processing_cost",
        "contribution_profit",
        "contribution_margin_pct",
    }

    assert required_fields.issubset(data[0].keys())

    profits = [merchant["contribution_profit"] for merchant in data]
    assert profits == sorted(profits, reverse=True)


def test_merchant_profitability_rejects_invalid_limit():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability?limit=0"
        )

    assert response.status_code == 422



def test_merchant_profitability_with_date_range():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability",
            params={
                "limit": 10,
                "start_date": "2026-09-01",
                "end_date": "2026-09-30",
            },
        )

    assert response.status_code == 200
    assert len(response.json()) <= 10


def test_merchant_profitability_without_date_filters():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability",
            params={"limit": 10},
        )

    assert response.status_code == 200
    assert len(response.json()) == 10


def test_merchant_profitability_rejects_reversed_dates():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability",
            params={
                "start_date": "2026-09-30",
                "end_date": "2026-09-01",
            },
        )

    assert response.status_code == 422
    assert "start_date must be on or before end_date" in response.text


def test_merchant_profitability_date_filter_matches_sql():
    from fastapi.testclient import TestClient
    from sqlalchemy import text
    from api.main import app
    from api.database import create_db_engine

    start_date = "2026-09-01"
    end_date = "2026-09-30"

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability",
            params={
                "limit": 10,
                "start_date": start_date,
                "end_date": end_date,
            },
        )

    assert response.status_code == 200
    api_data = response.json()

    query = text("""
        SELECT
            m.merchant_id,
            ROUND(
                SUM(
                    f.gross_fee_revenue
                    - f.fee_reversal
                    - f.processing_cost
                )::numeric,
                2
            ) AS contribution_profit
        FROM merchants m
        INNER JOIN transactions t
            ON m.merchant_id = t.merchant_id
        INNER JOIN transaction_fees f
            ON t.transaction_id = f.transaction_id
        WHERE t.status = 'SUCCESS'
            AND t.created_at >= CAST(:start_date AS date)
            AND t.created_at < (
                CAST(:end_date AS date) + INTERVAL '1 day'
            )
        GROUP BY m.merchant_id
        ORDER BY contribution_profit DESC
        LIMIT :limit
    """)

    engine = create_db_engine()
    try:
        with engine.connect() as connection:
            result = connection.execute(
                query,
                {
                    "start_date": start_date,
                    "end_date": end_date,
                    "limit": 10,
                },
            ).mappings().all()
            sql_data = [dict(row) for row in result]
    finally:
        engine.dispose()

    assert len(api_data) == len(sql_data)

    for api_row, sql_row in zip(api_data, sql_data):
        assert api_row["merchant_id"] == sql_row["merchant_id"]
        assert abs(
            api_row["contribution_profit"]
            - float(sql_row["contribution_profit"])
        ) < 0.01



def test_merchant_profitability_rejects_invalid_date_format():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/analytics/merchant-profitability",
            params={"start_date": "2026-99-99"},
        )

    assert response.status_code == 422



def test_transaction_validation_endpoint_rejects_invalid_input():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get(
            "/transactions/validate",
            params={
                "payment_method": "INVALID",
                "status": "SUCCESS",
                "amount": 100,
            },
        )

    assert response.status_code == 200
    data = response.json()
    assert data["valid"] is False
    assert len(data["errors"]) > 0



def test_sample_transaction_endpoint():
    from fastapi.testclient import TestClient
    from api.main import app

    with TestClient(app) as client:
        response = client.get("/transactions/sample")

    assert response.status_code == 200

    data = response.json()
    assert data["transaction_id"] == "TXN-10001"
    assert data["merchant_id"] == "MER-001"
    assert data["payment_method"] == "UPI"
    assert data["currency"] == "INR"
    assert data["status"] == "SUCCESS"
