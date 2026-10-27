from api.config import PAYMENT_METHODS, TRANSACTION_STATUSES


def validate_transaction(
    payment_method: str,
    status: str,
    amount: float,
) -> list[str]:
    errors = []

    if payment_method not in PAYMENT_METHODS:
        errors.append("Unsupported payment method.")

    if status not in TRANSACTION_STATUSES:
        errors.append("Unsupported transaction status.")

    if amount <= 0:
        errors.append("Transaction amount must be greater than zero.")

    return errors
