from api.transactions import validate_transaction


def test_valid_transaction():
    errors = validate_transaction("UPI", "SUCCESS", 1499)
    assert errors == []


def test_invalid_payment_method():
    errors = validate_transaction("BITCOIN", "SUCCESS", 1499)
    assert "Unsupported payment method." in errors


def test_invalid_status():
    errors = validate_transaction("UPI", "PENDING", 1499)
    assert "Unsupported transaction status." in errors


def test_negative_amount():
    errors = validate_transaction("UPI", "SUCCESS", -100)
    assert "Transaction amount must be greater than zero." in errors


def test_zero_amount():
    errors = validate_transaction("UPI", "SUCCESS", 0)
    assert "Transaction amount must be greater than zero." in errors
