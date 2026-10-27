from fastapi import FastAPI, Query, HTTPException
from datetime import date
from typing import Optional

from api.schemas import (
    HealthResponse,
    TransactionResponse,
    PaymentPerformanceResponse,
     MerchantProfitabilityResponse,
)

from api.transactions import validate_transaction

from api.analytics import (
    get_overall_payment_performance,
    get_merchant_profitability,
)

app = FastAPI(
    title="Payment Revenue & Profitability Intelligence API",
    version="1.0.0",
    description="API for payment analytics, profitability, and settlement reconciliation."
)


@app.get("/health", response_model=HealthResponse)
def health_check():
    return {"status": "healthy"}


@app.get("/transactions/sample", response_model=TransactionResponse)
def get_sample_transaction():
    return {
        "transaction_id": "TXN-10001",
        "merchant_id": "MER-001",
        "payment_method": "UPI",
        "amount": 1499.00,
        "currency": "INR",
        "status": "SUCCESS",
        "created_at": "2026-10-01T10:30:00"
    }


@app.get("/transactions/validate")
def check_transaction(
    payment_method: str,
    status: str,
    amount: float,
):
    errors = validate_transaction(
        payment_method=payment_method,
        status=status,
        amount=amount,
    )

    return {
        "valid": len(errors) == 0,
        "errors": errors,
    }


@app.get("/analytics/overview", response_model=PaymentPerformanceResponse,)
def get_analytics_overview():
    return get_overall_payment_performance()



@app.get(
    "/analytics/merchant-profitability",
    response_model=list[MerchantProfitabilityResponse],
)
def get_merchant_profitability_endpoint(
    limit: int = Query(default=10, ge=1, le=100),
    start_date: Optional[date] = None,
    end_date: Optional[date] = None,
):
    if start_date and end_date and start_date > end_date:
        raise HTTPException(
            status_code=422,
            detail="start_date must be on or before end_date.",
        )

    return get_merchant_profitability(
        limit=limit,
        start_date=start_date,
        end_date=end_date,
    )