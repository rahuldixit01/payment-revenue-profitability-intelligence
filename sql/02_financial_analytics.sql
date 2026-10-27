-- Core financial SQL analytics
-- Business Question 1: What is our Total Payment Volume (TPV)?
-- Includes successful transactions only; refunds are tracked separately.

SELECT
    COUNT(*) AS successful_transactions,
    SUM(amount) AS total_payment_volume
FROM transactions
WHERE status = 'SUCCESS';

-- Business Question 2: How much gross fee revenue does the platform earn?

SELECT
    COUNT(*) AS fee_records,
    SUM(gross_fee_revenue) AS gross_fee_revenue
FROM transaction_fees;

-- Business Question 3: What is net revenue after fee reversals?

SELECT
    SUM(gross_fee_revenue) AS gross_fee_revenue,
    SUM(fee_reversal) AS total_fee_reversals,
    SUM(gross_fee_revenue - fee_reversal) AS net_revenue
FROM transaction_fees;

-- Business Question 4: What does it cost to process payments?

SELECT
    SUM(processing_cost) AS total_processing_cost
FROM transaction_fees;

-- Business Question 5: What is the platform's contribution profit?
-- Net revenue = gross fee revenue - fee reversals.
-- Contribution profit = net revenue - processing costs.

SELECT
    SUM(gross_fee_revenue) AS gross_fee_revenue,
    SUM(fee_reversal) AS fee_reversals,
    SUM(gross_fee_revenue - fee_reversal) AS net_revenue,
    SUM(processing_cost) AS processing_cost,
    SUM(gross_fee_revenue - fee_reversal - processing_cost)
        AS contribution_profit
FROM transaction_fees;

-- Business Question 6: Which payment methods generate the highest contribution profit?
-- Fee reversals reduce net revenue and contribution profit.

SELECT
    t.payment_method,
    COUNT(*) AS successful_transactions,
    SUM(t.amount) AS tpv,
    SUM(f.gross_fee_revenue) AS gross_fee_revenue,
    SUM(f.fee_reversal) AS fee_reversals,
    SUM(f.gross_fee_revenue - f.fee_reversal) AS net_revenue,
    SUM(f.processing_cost) AS processing_cost,
    SUM(
        f.gross_fee_revenue
        - f.fee_reversal
        - f.processing_cost
    ) AS contribution_profit
FROM transactions t
INNER JOIN transaction_fees f
    ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY t.payment_method
ORDER BY contribution_profit DESC;

-- Business Question 7: Which payment method has the highest contribution margin?
-- Contribution margin = contribution profit / net revenue * 100.

SELECT
    t.payment_method,
    SUM(f.gross_fee_revenue - f.fee_reversal)
        AS net_revenue,
    SUM(f.processing_cost) AS processing_cost,
    SUM(
        f.gross_fee_revenue
        - f.fee_reversal
        - f.processing_cost
    ) AS contribution_profit,
    ROUND(
        100.0 * SUM(
            f.gross_fee_revenue
            - f.fee_reversal
            - f.processing_cost
        ) / NULLIF(
            SUM(f.gross_fee_revenue - f.fee_reversal), 0
        ),
        2
    ) AS contribution_margin_pct
FROM transactions t
INNER JOIN transaction_fees f
    ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY t.payment_method
ORDER BY contribution_margin_pct DESC;

-- Business Question 8: Which payment methods have the highest fee-reversal rate?
-- Reversal rate = fee reversals / gross fee revenue * 100.

SELECT
    t.payment_method,
    COUNT(*) AS successful_transactions,
    SUM(f.gross_fee_revenue) AS gross_fee_revenue,
    SUM(f.fee_reversal) AS fee_reversals,
    ROUND(
        100.0 * SUM(f.fee_reversal)
        / NULLIF(SUM(f.gross_fee_revenue), 0),
        2
    ) AS fee_reversal_rate_pct
FROM transactions t
INNER JOIN transaction_fees f
    ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY t.payment_method
ORDER BY fee_reversal_rate_pct DESC;

-- Business Question 9: Which merchants generate the highest contribution profit?

SELECT
    m.merchant_id,
    m.merchant_name,
    COUNT(t.transaction_id) AS successful_transactions,
    SUM(t.amount) AS tpv,
    SUM(f.gross_fee_revenue - f.fee_reversal) AS net_revenue,
    SUM(f.processing_cost) AS processing_cost,
    SUM(
        f.gross_fee_revenue
        - f.fee_reversal
        - f.processing_cost
    ) AS contribution_profit,
    ROUND(
        100.0 * SUM(
            f.gross_fee_revenue
            - f.fee_reversal
            - f.processing_cost
        ) / NULLIF(
            SUM(f.gross_fee_revenue - f.fee_reversal), 0
        ),
        2
    ) AS contribution_margin_pct
FROM merchants m
INNER JOIN transactions t
    ON m.merchant_id = t.merchant_id
INNER JOIN transaction_fees f
    ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY m.merchant_id, m.merchant_name
ORDER BY contribution_profit DESC
LIMIT 10;

-- Business Question 10: Which merchants have the lowest contribution margins?
-- Include only merchants with at least 20 successful transactions.

SELECT
    m.merchant_id,
    m.merchant_name,
    COUNT(t.transaction_id) AS successful_transactions,
    SUM(f.gross_fee_revenue - f.fee_reversal) AS net_revenue,
    SUM(f.processing_cost) AS processing_cost,
    SUM(
        f.gross_fee_revenue
        - f.fee_reversal
        - f.processing_cost
    ) AS contribution_profit,
    ROUND(
        100.0 * SUM(
            f.gross_fee_revenue
            - f.fee_reversal
            - f.processing_cost
        ) / NULLIF(
            SUM(f.gross_fee_revenue - f.fee_reversal), 0
        ),
        2
    ) AS contribution_margin_pct
FROM merchants m
INNER JOIN transactions t
    ON m.merchant_id = t.merchant_id
INNER JOIN transaction_fees f
    ON t.transaction_id = f.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY m.merchant_id, m.merchant_name
HAVING COUNT(t.transaction_id) >= 20
ORDER BY contribution_margin_pct ASC
LIMIT 10;

-- Business Question 11: Which merchants underperform the platform margin?
-- Compare merchant contribution margin with the overall platform margin.

WITH merchant_metrics AS (
    SELECT
        m.merchant_id,
        m.merchant_name,
        COUNT(t.transaction_id) AS successful_transactions,
        SUM(f.gross_fee_revenue - f.fee_reversal) AS net_revenue,
        SUM(f.processing_cost) AS processing_cost,
        SUM(
            f.gross_fee_revenue
            - f.fee_reversal
            - f.processing_cost
        ) AS contribution_profit
    FROM merchants m
    INNER JOIN transactions t
        ON m.merchant_id = t.merchant_id
    INNER JOIN transaction_fees f
        ON t.transaction_id = f.transaction_id
    WHERE t.status = 'SUCCESS'
    GROUP BY m.merchant_id, m.merchant_name
    HAVING COUNT(t.transaction_id) >= 20
),
platform_margin AS (
    SELECT
        100.0 * SUM(
            gross_fee_revenue - fee_reversal - processing_cost
        ) / NULLIF(
            SUM(gross_fee_revenue - fee_reversal), 0
        ) AS platform_margin_pct
    FROM transaction_fees
)
SELECT
    mm.merchant_id,
    mm.merchant_name,
    mm.successful_transactions,
    ROUND(mm.net_revenue, 2) AS net_revenue,
    ROUND(mm.contribution_profit, 2) AS contribution_profit,
    ROUND(
        100.0 * mm.contribution_profit
        / NULLIF(mm.net_revenue, 0),
        2
    ) AS merchant_margin_pct,
    ROUND(pm.platform_margin_pct, 2) AS platform_margin_pct,
    ROUND(
        100.0 * mm.contribution_profit
        / NULLIF(mm.net_revenue, 0)
        - pm.platform_margin_pct,
        2
    ) AS margin_gap_pp
FROM merchant_metrics mm
CROSS JOIN platform_margin pm
ORDER BY margin_gap_pp ASC
LIMIT 10;

-- Business Question 12: What settlement discrepancies require investigation?
-- Variance = actual settlement amount - expected settlement amount.
-- Non-zero variance is not automatically a confirmed financial loss.

SELECT
    COUNT(*) AS total_settlements,
    COUNT(*) FILTER (
        WHERE ABS(COALESCE(actual_amount, 0) - expected_amount) > 0.01
    ) AS settlements_with_variance,
    ROUND(
        SUM(actual_amount - expected_amount),
        2
    ) AS net_settlement_variance,
    ROUND(
        SUM(ABS(actual_amount - expected_amount)),
        2
    ) AS absolute_settlement_variance
FROM settlements;

-- Business Question 13: Are settlement variances short, excess, or matched?
-- Variance = actual amount - expected amount.

SELECT
    CASE
        WHEN ABS(actual_amount - expected_amount) <= 0.01
            THEN 'MATCHED'
        WHEN actual_amount < expected_amount
            THEN 'SHORT_SETTLEMENT'
        ELSE 'EXCESS_SETTLEMENT'
    END AS reconciliation_status,
    COUNT(*) AS settlement_count,
    ROUND(SUM(actual_amount - expected_amount), 2)
        AS net_variance,
    ROUND(SUM(ABS(actual_amount - expected_amount)), 2)
        AS absolute_variance
FROM settlements
GROUP BY 1
ORDER BY absolute_variance DESC;

-- Business Question 14: Which merchants have the largest settlement variances?
-- Settlement records are aggregated at merchant level.
-- Absolute variance measures discrepancy magnitude, not confirmed loss.

SELECT
    s.merchant_id,
    m.merchant_name,
    COUNT(*) AS settlement_count,
    COUNT(*) FILTER (
        WHERE ABS(s.actual_amount - s.expected_amount) > 0.01
    ) AS settlements_with_variance,
    ROUND(
        SUM(s.actual_amount - s.expected_amount),
        2
    ) AS net_variance,
    ROUND(
        SUM(ABS(s.actual_amount - s.expected_amount)),
        2
    ) AS absolute_variance
FROM settlements s
LEFT JOIN merchants m
    ON s.merchant_id = m.merchant_id
GROUP BY s.merchant_id, m.merchant_name
ORDER BY absolute_variance DESC
LIMIT 10;

-- Business Question 15: What is the volume and value of refunds by status?

SELECT
    status AS refund_status,
    COUNT(*) AS refund_count,
    ROUND(SUM(refund_amount), 2) AS refund_amount
FROM refunds
GROUP BY status
ORDER BY refund_amount DESC;

-- Business Question 16: What is the volume and financial exposure of chargebacks by status?

SELECT
    status AS chargeback_status,
    COUNT(*) AS chargeback_count,
    ROUND(SUM(chargeback_amount), 2) AS chargeback_amount,
    ROUND(SUM(chargeback_fee), 2) AS chargeback_fees
FROM chargebacks
GROUP BY status
ORDER BY chargeback_amount DESC;

-- Business Question 17: What percentage of chargeback cases were lost?

SELECT
    COUNT(*) AS total_chargebacks,
    COUNT(*) FILTER (
        WHERE status = 'LOST'
    ) AS lost_chargebacks,
    ROUND(
        COUNT(*) FILTER (WHERE status = 'LOST') * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS lost_case_rate_pct,
    ROUND(
        SUM(chargeback_amount) FILTER (WHERE status = 'LOST'),
        2
    ) AS lost_principal_amount,
    ROUND(
        SUM(chargeback_fee) FILTER (WHERE status = 'LOST'),
        2
    ) AS fees_on_lost_cases
FROM chargebacks;

-- Business Question 18: How do net revenue and contribution profit trend monthly?

SELECT
    DATE_TRUNC('month', t.created_at)::date AS revenue_month,
    ROUND(SUM(tf.gross_fee_revenue), 2) AS gross_fee_revenue,
    ROUND(SUM(tf.fee_reversal), 2) AS fee_reversals,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal), 2
    ) AS net_revenue,
    ROUND(SUM(tf.processing_cost), 2) AS processing_cost,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal - tf.processing_cost),
        2
    ) AS contribution_profit,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal - tf.processing_cost)
        * 100.0
        / NULLIF(SUM(tf.gross_fee_revenue - tf.fee_reversal), 0),
        2
    ) AS contribution_margin_pct
FROM transactions t
JOIN transaction_fees tf
    ON t.transaction_id = tf.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY DATE_TRUNC('month', t.created_at)::date
ORDER BY revenue_month;

-- Business Question 19: Reconcile monthly revenue totals to platform totals.

SELECT
    COUNT(*) AS successful_transactions,
    ROUND(SUM(tf.gross_fee_revenue), 2) AS gross_fee_revenue,
    ROUND(SUM(tf.fee_reversal), 2) AS fee_reversals,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal), 2
    ) AS net_revenue,
    ROUND(SUM(tf.processing_cost), 2) AS processing_cost,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal - tf.processing_cost),
        2
    ) AS contribution_profit
FROM transactions t
JOIN transaction_fees tf
    ON t.transaction_id = tf.transaction_id
WHERE t.status = 'SUCCESS';

-- Business Question 20: How does monthly profitability vary by payment method?

SELECT
    DATE_TRUNC('month', t.created_at)::date AS revenue_month,
    t.payment_method,
    COUNT(*) AS successful_transactions,
    ROUND(SUM(tf.gross_fee_revenue), 2) AS gross_fee_revenue,
    ROUND(SUM(tf.fee_reversal), 2) AS fee_reversals,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal), 2
    ) AS net_revenue,
    ROUND(SUM(tf.processing_cost), 2) AS processing_cost,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal - tf.processing_cost),
        2
    ) AS contribution_profit,
    ROUND(
        SUM(tf.gross_fee_revenue - tf.fee_reversal - tf.processing_cost)
        * 100.0
        / NULLIF(SUM(tf.gross_fee_revenue - tf.fee_reversal), 0),
        2
    ) AS contribution_margin_pct
FROM transactions t
JOIN transaction_fees tf
    ON t.transaction_id = tf.transaction_id
WHERE t.status = 'SUCCESS'
GROUP BY
    DATE_TRUNC('month', t.created_at)::date,
    t.payment_method
ORDER BY
    revenue_month,
    t.payment_method;

-- Business Question 21: Which payment methods have the highest refund volume and value?

SELECT
    t.payment_method,
    COUNT(r.refund_id) AS total_refund_requests,

    COUNT(r.refund_id) FILTER (
        WHERE r.status = 'COMPLETED'
    ) AS completed_refunds,

    COUNT(r.refund_id) FILTER (
        WHERE r.status = 'PENDING'
    ) AS pending_refunds,

    COUNT(r.refund_id) FILTER (
        WHERE r.status = 'FAILED'
    ) AS failed_refunds,

    ROUND(
        SUM(r.refund_amount) FILTER (
            WHERE r.status = 'COMPLETED'
        ),
        2
    ) AS completed_refund_amount,

    ROUND(
        SUM(r.refund_amount) FILTER (
            WHERE r.status = 'PENDING'
        ),
        2
    ) AS pending_refund_amount

FROM refunds r
JOIN transactions t
    ON r.transaction_id = t.transaction_id

GROUP BY t.payment_method
ORDER BY completed_refund_amount DESC;

-- Business Question 22: What is the completed refund rate by payment method?

WITH successful_transactions AS (
    SELECT
        payment_method,
        COUNT(*) AS successful_transaction_count
    FROM transactions
    WHERE status = 'SUCCESS'
    GROUP BY payment_method
),
refund_summary AS (
    SELECT
        t.payment_method,
        COUNT(*) FILTER (
            WHERE r.status = 'COMPLETED'
        ) AS completed_refund_count,
        SUM(r.refund_amount) FILTER (
            WHERE r.status = 'COMPLETED'
        ) AS completed_refund_amount
    FROM refunds r
    JOIN transactions t
        ON r.transaction_id = t.transaction_id
    GROUP BY t.payment_method
)
SELECT
    s.payment_method,
    s.successful_transaction_count,
    COALESCE(r.completed_refund_count, 0) AS completed_refund_count,
    ROUND(
        COALESCE(r.completed_refund_count, 0) * 100.0
        / NULLIF(s.successful_transaction_count, 0),
        2
    ) AS completed_refund_rate_pct,
    ROUND(
        COALESCE(r.completed_refund_amount, 0),
        2
    ) AS completed_refund_amount
FROM successful_transactions s
LEFT JOIN refund_summary r
    ON s.payment_method = r.payment_method
ORDER BY completed_refund_rate_pct DESC;

-- Business Question 23: What percentage of successful transactions
-- have at least one completed refund?

WITH completed_refunded_transactions AS (
    SELECT DISTINCT transaction_id
    FROM refunds
    WHERE status = 'COMPLETED'
),
successful_transactions AS (
    SELECT
        transaction_id,
        payment_method
    FROM transactions
    WHERE status = 'SUCCESS'
)
SELECT
    t.payment_method,
    COUNT(*) AS successful_transactions,
    COUNT(r.transaction_id) AS transactions_with_completed_refund,
    ROUND(
        COUNT(r.transaction_id) * 100.0
        / NULLIF(COUNT(*), 0),
        2
    ) AS transaction_refund_rate_pct
FROM successful_transactions t
LEFT JOIN completed_refunded_transactions r
    ON t.transaction_id = r.transaction_id
GROUP BY t.payment_method
ORDER BY transaction_refund_rate_pct DESC;


-- Business Question 24: Which merchants have the highest chargeback rates?
-- Proxy rate = chargeback records / successful transactions.
-- This is a record-count proxy, not necessarily a distinct-transaction rate.

WITH merchant_transactions AS (
    SELECT
        merchant_id,
        COUNT(*) AS successful_transactions
    FROM transactions
    WHERE status = 'SUCCESS'
    GROUP BY merchant_id
),
merchant_chargebacks AS (
    SELECT
        merchant_id,
        COUNT(*) AS chargeback_count,
        COUNT(*) FILTER (
            WHERE status = 'LOST'
        ) AS lost_chargeback_count,
        SUM(chargeback_amount) AS chargeback_principal,
        SUM(chargeback_fee) AS chargeback_fees
    FROM chargebacks
    GROUP BY merchant_id
)
SELECT
    mt.merchant_id,
    m.merchant_name,
    mt.successful_transactions,
    COALESCE(mc.chargeback_count, 0) AS chargeback_count,
    COALESCE(mc.lost_chargeback_count, 0)
        AS lost_chargeback_count,
    ROUND(
        COALESCE(mc.chargeback_count, 0) * 100.0
        / NULLIF(mt.successful_transactions, 0),
        2
    ) AS chargeback_count_rate_pct,
    ROUND(
        COALESCE(mc.chargeback_principal, 0), 2
    ) AS chargeback_principal,
    ROUND(
        COALESCE(mc.chargeback_fees, 0), 2
    ) AS chargeback_fees
FROM merchant_transactions mt
LEFT JOIN merchant_chargebacks mc
    ON mt.merchant_id = mc.merchant_id
LEFT JOIN merchants m
    ON mt.merchant_id = m.merchant_id
WHERE mt.successful_transactions >= 20
ORDER BY
    chargeback_count_rate_pct DESC,
    chargeback_principal DESC
LIMIT 10;


-- Q25: Validate reconciliation exceptions by category
-- Checks settlement linkage, transaction linkage, severity,
-- status, and recorded financial impact.

SELECT
    re.exception_type,
    COUNT(*) AS exception_count,

    COUNT(*) FILTER (
        WHERE re.transaction_id IS NULL
           OR TRIM(re.transaction_id) = ''
    ) AS missing_transaction_id,

    COUNT(*) FILTER (
        WHERE re.settlement_id IS NULL
           OR TRIM(re.settlement_id) = ''
    ) AS missing_settlement_id,

    COUNT(*) FILTER (
        WHERE re.settlement_id IS NOT NULL
          AND TRIM(re.settlement_id) <> ''
          AND s.settlement_id IS NULL
    ) AS settlement_id_not_found,

    COUNT(*) FILTER (
        WHERE re.transaction_id IS NOT NULL
          AND TRIM(re.transaction_id) <> ''
          AND t.transaction_id IS NULL
    ) AS transaction_id_not_found,

    COUNT(*) FILTER (
        WHERE re.exception_type = 'MISSING_SETTLEMENT'
          AND (
              re.settlement_id IS NULL
              OR TRIM(re.settlement_id) = ''
          )
    ) AS missing_settlement_with_no_id,

    COUNT(*) FILTER (
        WHERE re.exception_type = 'MISSING_SETTLEMENT'
          AND s.settlement_id IS NOT NULL
    ) AS missing_settlement_with_existing_id,

    COUNT(*) FILTER (
        WHERE re.exception_type = 'DUPLICATE_RECORD'
    ) AS duplicate_category_records,

    ROUND(
        COALESCE(SUM(re.exception_amount), 0), 2
    ) AS total_exception_amount,

    ROUND(
        COALESCE(SUM(re.confirmed_financial_impact), 0), 2
    ) AS recorded_confirmed_financial_impact

FROM reconciliation_exceptions re
LEFT JOIN settlements s
    ON re.settlement_id = s.settlement_id
LEFT JOIN transactions t
    ON re.transaction_id = t.transaction_id
GROUP BY re.exception_type
ORDER BY exception_count DESC;


-- Business Question 26: Which transactions have both
-- completed refund activity and chargeback activity?

WITH completed_refunds AS (
    SELECT
        transaction_id,
        COUNT(*) AS completed_refund_count,
        SUM(refund_amount) AS completed_refund_amount
    FROM refunds
    WHERE status = 'COMPLETED'
    GROUP BY transaction_id
),
chargeback_summary AS (
    SELECT
        transaction_id,
        COUNT(*) AS chargeback_count,
        SUM(chargeback_amount) AS chargeback_principal,
        SUM(chargeback_fee) AS chargeback_fees
    FROM chargebacks
    GROUP BY transaction_id
)
SELECT
    t.transaction_id,
    t.merchant_id,
    t.payment_method,
    t.amount AS transaction_amount,
    r.completed_refund_count,
    ROUND(r.completed_refund_amount, 2)
        AS completed_refund_amount,
    c.chargeback_count,
    ROUND(c.chargeback_principal, 2)
        AS chargeback_principal,
    ROUND(c.chargeback_fees, 2)
        AS chargeback_fees
FROM transactions t
JOIN completed_refunds r
    ON t.transaction_id = r.transaction_id
JOIN chargeback_summary c
    ON t.transaction_id = c.transaction_id
ORDER BY c.chargeback_principal DESC;


-- Business Question 27: Which merchants combine
-- below-platform profitability with elevated chargeback activity?

WITH merchant_profitability AS (
    SELECT
        t.merchant_id,
        COUNT(*) AS successful_transactions,
        SUM(tf.gross_fee_revenue - tf.fee_reversal)
            AS net_revenue,
        SUM(
            tf.gross_fee_revenue
            - tf.fee_reversal
            - tf.processing_cost
        ) AS contribution_profit
    FROM transactions t
    JOIN transaction_fees tf
        ON t.transaction_id = tf.transaction_id
    WHERE t.status = 'SUCCESS'
    GROUP BY t.merchant_id
),
platform_margin AS (
    SELECT
        100.0 * SUM(
            gross_fee_revenue - fee_reversal - processing_cost
        ) / NULLIF(
            SUM(gross_fee_revenue - fee_reversal), 0
        ) AS platform_margin_pct
    FROM transaction_fees
),
merchant_risk AS (
    SELECT
        merchant_id,
        COUNT(*) AS chargeback_count,
        COUNT(*) FILTER (
            WHERE status = 'LOST'
        ) AS lost_chargeback_count,
        SUM(chargeback_amount) AS chargeback_principal
    FROM chargebacks
    GROUP BY merchant_id
)
SELECT
    mp.merchant_id,
    m.merchant_name,
    mp.successful_transactions,
    ROUND(mp.net_revenue, 2) AS net_revenue,
    ROUND(mp.contribution_profit, 2) AS contribution_profit,
    ROUND(
        100.0 * mp.contribution_profit
        / NULLIF(mp.net_revenue, 0), 2
    ) AS merchant_margin_pct,
    ROUND(pm.platform_margin_pct, 2) AS platform_margin_pct,
    COALESCE(mr.chargeback_count, 0) AS chargeback_count,
    COALESCE(mr.lost_chargeback_count, 0)
        AS lost_chargeback_count,
    ROUND(COALESCE(mr.chargeback_principal, 0), 2)
        AS chargeback_principal,
    ROUND(
        COALESCE(mr.chargeback_count, 0) * 100.0
        / NULLIF(mp.successful_transactions, 0), 2
    ) AS chargeback_count_rate_pct
FROM merchant_profitability mp
JOIN merchants m
    ON mp.merchant_id = m.merchant_id
CROSS JOIN platform_margin pm
LEFT JOIN merchant_risk mr
    ON mp.merchant_id = mr.merchant_id
WHERE mp.successful_transactions >= 20
  AND 100.0 * mp.contribution_profit
      / NULLIF(mp.net_revenue, 0) < pm.platform_margin_pct
  AND COALESCE(mr.chargeback_count, 0) > 0
ORDER BY
    chargeback_count_rate_pct DESC,
    merchant_margin_pct ASC
LIMIT 10;


-- Business Question 28: How does transaction success rate
-- change month by month?

SELECT
    DATE_TRUNC('month', created_at)::date AS transaction_month,
    COUNT(*) AS total_transactions,

    COUNT(*) FILTER (
        WHERE status = 'SUCCESS'
    ) AS successful_transactions,

    COUNT(*) FILTER (
        WHERE status = 'FAILED'
    ) AS failed_transactions,

    COUNT(*) FILTER (
        WHERE status = 'CANCELLED'
    ) AS cancelled_transactions,

    ROUND(
        COUNT(*) FILTER (
            WHERE status = 'SUCCESS'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS success_rate_pct,

    ROUND(
        COUNT(*) FILTER (
            WHERE status = 'FAILED'
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS failure_rate_pct

FROM transactions
GROUP BY DATE_TRUNC('month', created_at)::date
ORDER BY transaction_month;


-- Business Question 29: How concentrated is net fee revenue
-- among the top 10 merchants?

WITH merchant_revenue AS (
    SELECT
        t.merchant_id,
        m.merchant_name,
        SUM(tf.gross_fee_revenue - tf.fee_reversal)
            AS net_fee_revenue
    FROM transactions t
    JOIN transaction_fees tf
        ON t.transaction_id = tf.transaction_id
    JOIN merchants m
        ON t.merchant_id = m.merchant_id
    WHERE t.status = 'SUCCESS'
    GROUP BY t.merchant_id, m.merchant_name
),
ranked_merchants AS (
    SELECT
        merchant_id,
        merchant_name,
        net_fee_revenue,
        ROW_NUMBER() OVER (
            ORDER BY net_fee_revenue DESC
        ) AS revenue_rank
    FROM merchant_revenue
),
platform_revenue AS (
    SELECT SUM(net_fee_revenue) AS total_net_fee_revenue
    FROM merchant_revenue
)
SELECT
    rm.revenue_rank,
    rm.merchant_id,
    rm.merchant_name,
    ROUND(rm.net_fee_revenue, 2) AS net_fee_revenue,
    ROUND(
        100.0 * rm.net_fee_revenue
        / NULLIF(pr.total_net_fee_revenue, 0),
        2
    ) AS share_of_platform_revenue_pct,
    ROUND(
        100.0 * SUM(rm.net_fee_revenue) OVER (
            ORDER BY rm.revenue_rank
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) / NULLIF(pr.total_net_fee_revenue, 0),
        2
    ) AS cumulative_revenue_share_pct
FROM ranked_merchants rm
CROSS JOIN platform_revenue pr
WHERE rm.revenue_rank <= 10
ORDER BY rm.revenue_rank;


-- Business Question 30: What is the platform's executive
-- financial and operational summary?

WITH transaction_summary AS (
    SELECT
        COUNT(*) AS total_transactions,
        COUNT(*) FILTER (
            WHERE status = 'SUCCESS'
        ) AS successful_transactions,
        COUNT(*) FILTER (
            WHERE status = 'FAILED'
        ) AS failed_transactions,
        COUNT(*) FILTER (
            WHERE status = 'CANCELLED'
        ) AS cancelled_transactions,
        SUM(amount) FILTER (
            WHERE status = 'SUCCESS'
        ) AS tpv
    FROM transactions
),
financial_summary AS (
    SELECT
        SUM(gross_fee_revenue) AS gross_fee_revenue,
        SUM(fee_reversal) AS fee_reversals,
        SUM(gross_fee_revenue - fee_reversal)
            AS net_fee_revenue,
        SUM(processing_cost) AS processing_cost,
        SUM(
            gross_fee_revenue
            - fee_reversal
            - processing_cost
        ) AS contribution_profit
    FROM transaction_fees
),
settlement_summary AS (
    SELECT
        COUNT(*) AS total_settlements,
        COUNT(*) FILTER (
            WHERE ABS(actual_amount - expected_amount) > 0.01
        ) AS settlements_with_variance,
        SUM(ABS(actual_amount - expected_amount))
            AS absolute_settlement_variance
    FROM settlements
),
chargeback_summary AS (
    SELECT
        COUNT(*) AS total_chargebacks,
        COUNT(*) FILTER (
            WHERE status = 'LOST'
        ) AS lost_chargebacks,
        SUM(chargeback_amount) FILTER (
            WHERE status = 'LOST'
        ) AS lost_chargeback_principal,
        SUM(chargeback_fee) FILTER (
            WHERE status = 'LOST'
        ) AS lost_chargeback_fees
    FROM chargebacks
),
refund_summary AS (
    SELECT
        COUNT(*) FILTER (
            WHERE status = 'COMPLETED'
        ) AS completed_refunds,
        SUM(refund_amount) FILTER (
            WHERE status = 'COMPLETED'
        ) AS completed_refund_principal
    FROM refunds
),
exception_summary AS (
    SELECT
        COUNT(*) AS exception_count,
        SUM(exception_amount) AS recorded_exception_amount,
        SUM(confirmed_financial_impact)
            AS confirmed_financial_impact
    FROM reconciliation_exceptions
)
SELECT
    ts.total_transactions,
    ts.successful_transactions,
    ts.failed_transactions,
    ts.cancelled_transactions,
    ROUND(ts.tpv, 2) AS tpv,

    ROUND(
        100.0 * ts.successful_transactions
        / NULLIF(ts.total_transactions, 0),
        2
    ) AS transaction_success_rate_pct,

    ROUND(fs.gross_fee_revenue, 2) AS gross_fee_revenue,
    ROUND(fs.fee_reversals, 2) AS fee_reversals,
    ROUND(fs.net_fee_revenue, 2) AS net_fee_revenue,
    ROUND(fs.processing_cost, 2) AS processing_cost,
    ROUND(fs.contribution_profit, 2) AS contribution_profit,

    ROUND(
        100.0 * fs.contribution_profit
        / NULLIF(fs.net_fee_revenue, 0),
        2
    ) AS contribution_margin_pct,

    ss.total_settlements,
    ss.settlements_with_variance,
    ROUND(ss.absolute_settlement_variance, 2)
        AS absolute_settlement_variance,

    cs.total_chargebacks,
    cs.lost_chargebacks,
    ROUND(cs.lost_chargeback_principal, 2)
        AS lost_chargeback_principal,
    ROUND(cs.lost_chargeback_fees, 2)
        AS lost_chargeback_fees,

    rs.completed_refunds,
    ROUND(rs.completed_refund_principal, 2)
        AS completed_refund_principal,

    es.exception_count,
    ROUND(es.recorded_exception_amount, 2)
        AS recorded_exception_amount,
    ROUND(es.confirmed_financial_impact, 2)
        AS confirmed_financial_impact

FROM transaction_summary ts
CROSS JOIN financial_summary fs
CROSS JOIN settlement_summary ss
CROSS JOIN chargeback_summary cs
CROSS JOIN refund_summary rs
CROSS JOIN exception_summary es;
