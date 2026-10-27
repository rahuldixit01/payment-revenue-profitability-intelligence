--1. Validated row counts after CSV ingestion

SELECT 'merchants' AS table_name, COUNT(*) AS row_count FROM merchants
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions
UNION ALL
SELECT 'transaction_fees', COUNT(*) FROM transaction_fees
UNION ALL
SELECT 'settlements', COUNT(*) FROM settlements
UNION ALL
SELECT 'refunds', COUNT(*) FROM refunds
UNION ALL
SELECT 'chargebacks', COUNT(*) FROM chargebacks
UNION ALL
SELECT 'reconciliation_exceptions', COUNT(*) FROM reconciliation_exceptions;

-- 2. Transaction ID uniqueness
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT transaction_id) AS unique_transactions
FROM transactions;

-- 3. Transaction-to-merchant referential integrity
SELECT COUNT(*) AS orphan_transactions
FROM transactions t
LEFT JOIN merchants m ON t.merchant_id = m.merchant_id
WHERE m.merchant_id IS NULL;

-- 4. Fee record integrity
SELECT
    COUNT(*) AS total_fee_records,
    COUNT(DISTINCT transaction_id) AS unique_fee_transactions
FROM transaction_fees;

-- 5. Fee records linked to missing transactions
SELECT COUNT(*) AS orphan_fee_records
FROM transaction_fees f
LEFT JOIN transactions t ON f.transaction_id = t.transaction_id
WHERE t.transaction_id IS NULL;

-- 6. Successful transactions without fee records
SELECT COUNT(*) AS successful_transactions_without_fees
FROM transactions t
LEFT JOIN transaction_fees f ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
  AND f.transaction_id IS NULL;

-- 7. Settlement variance summary
SELECT
    COUNT(*) AS total_settlements,
    COUNT(*) FILTER (WHERE actual_amount <> expected_amount)
        AS settlements_with_variance,
    SUM(actual_amount - expected_amount) AS net_variance,
    SUM(ABS(actual_amount - expected_amount)) AS absolute_variance
FROM settlements;

