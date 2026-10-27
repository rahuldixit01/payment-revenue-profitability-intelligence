from datetime import datetime
from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str = Field(
        ...,
        description="Current API health status"
    )


class TransactionResponse(BaseModel):
    transaction_id: str
    merchant_id: str
    payment_method: str
    amount: float = Field(gt=0, description="Transaction amount in INR")
    currency: str = "INR"
    status: str
    created_at: datetime


class PaymentPerformanceResponse(BaseModel):
    total_attempts: int
    successful_transactions: int
    failed_transactions: int
    cancelled_transactions: int

    total_payment_volume: float
    gross_fee_revenue: float
    fee_reversals: float
    net_fee_revenue: float
    processing_cost: float

    success_rate_pct: float
    contribution_profit: float
    contribution_margin_pct: float


class MerchantProfitabilityResponse(BaseModel):
    merchant_id: str
    merchant_name: str
    successful_transactions: int
    tpv: float
    net_fee_revenue: float
    processing_cost: float
    contribution_profit: float
    contribution_margin_pct: float
