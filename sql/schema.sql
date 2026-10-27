
CREATE TABLE merchants (
    merchant_id VARCHAR(20) PRIMARY KEY,
    merchant_name VARCHAR(100) NOT NULL,
    city VARCHAR(50),
    state VARCHAR(50),
    onboarding_date DATE,
    fee_rate_pct NUMERIC(5,2),
    segment VARCHAR(30),
    merchant_type VARCHAR(50)
);

CREATE TABLE transactions (
    transaction_id VARCHAR(30) PRIMARY KEY,
    merchant_id VARCHAR(20) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    amount NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',
    status VARCHAR(20) NOT NULL,
    created_at TIMESTAMP NOT NULL,

    FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id)
);

CREATE TABLE transaction_fees (
    fee_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_id VARCHAR(30) NOT NULL UNIQUE,
    gross_fee_revenue NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (gross_fee_revenue >= 0),
    processing_cost NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (processing_cost >= 0),
    fee_reversal NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (fee_reversal >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id)
);

CREATE TABLE settlements (
    settlement_id VARCHAR(30) PRIMARY KEY,
    merchant_id VARCHAR(20) NOT NULL,
    settlement_date DATE NOT NULL,
    transaction_count INT NOT NULL CHECK (transaction_count > 0),
    expected_amount NUMERIC(14,2) NOT NULL
        CHECK (expected_amount >= 0),
    actual_amount NUMERIC(14,2) NOT NULL
        CHECK (actual_amount >= 0),
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id)
);

CREATE TABLE refunds (
    refund_id VARCHAR(30) PRIMARY KEY,
    transaction_id VARCHAR(30) NOT NULL UNIQUE,
    merchant_id VARCHAR(20) NOT NULL,
    refund_date TIMESTAMP NOT NULL,
    refund_amount NUMERIC(12,2) NOT NULL
        CHECK (refund_amount > 0),
    refund_type VARCHAR(20) NOT NULL,
    status VARCHAR(20) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id),
    FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id)
);

CREATE TABLE chargebacks (
    chargeback_id VARCHAR(30) PRIMARY KEY,
    transaction_id VARCHAR(30) NOT NULL UNIQUE,
    merchant_id VARCHAR(20) NOT NULL,
    chargeback_date TIMESTAMP NOT NULL,
    chargeback_amount NUMERIC(12,2) NOT NULL
        CHECK (chargeback_amount > 0),
    chargeback_fee NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (chargeback_fee >= 0),
    reason VARCHAR(50) NOT NULL,
    status VARCHAR(30) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id),
    FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id)
);

CREATE TABLE reconciliation_exceptions (
    exception_id VARCHAR(30) PRIMARY KEY,
    transaction_id VARCHAR(30) NOT NULL,
    merchant_id VARCHAR(20) NOT NULL,
    settlement_id VARCHAR(30),
    exception_date DATE NOT NULL,
    exception_type VARCHAR(40) NOT NULL,
    exception_amount NUMERIC(12,2) NOT NULL
        CHECK (exception_amount > 0),
    severity VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL,
    confirmed_financial_impact NUMERIC(12,2) NOT NULL DEFAULT 0
        CHECK (confirmed_financial_impact >= 0),
    expected_classification VARCHAR(40) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'INR',

    FOREIGN KEY (transaction_id)
        REFERENCES transactions(transaction_id),
    FOREIGN KEY (merchant_id)
        REFERENCES merchants(merchant_id),
    FOREIGN KEY (settlement_id)
        REFERENCES settlements(settlement_id)
);
