# Payment Revenue & Profitability Intelligence Platform
## Consolidated Business Logic

### 1. Purpose and Scope

This document defines the business rules used to analyze payment transactions, platform revenue, processing costs, merchant profitability, settlements, refunds, chargebacks, and reconciliation exceptions.

The purpose is to maintain consistent financial definitions across SQL analytics, the FastAPI layer, and Power BI dashboards.

- **Dataset:** Synthetic payment-processing data
- **Analysis period:** 1 April 2025 – 30 September 2026
- **Database:** PostgreSQL — `payment_intelligence`
- **Primary analytics implementation:** `sql/02_financial_analytics.sql`

All reported findings are based on synthetic data and should not be interpreted as actual payment-industry performance.

---

### 2. Core Financial Definitions

| Metric | Business definition |
|---|---|
| Total Transactions | Count of all payment attempts, including successful, failed, and cancelled transactions. |
| Successful Transactions | Count of transactions with status `SUCCESS`. |
| Transaction Success Rate | Successful transaction attempts ÷ all transaction attempts × 100. The denominator includes successful, failed, and cancelled attempts. |
| Total Payment Volume (TPV) | Sum of successful transaction amounts. Failed and cancelled transactions are excluded. |
| Gross Fee Revenue | Sum of earned transaction fees before fee reversals. |
| Fee Reversals | Fees reversed or refunded to merchants, including full and partial reversals. |
| Net Fee Revenue | Gross fee revenue − fee reversals. |
| Processing Cost | Sum of direct processing costs associated with transaction fees. |
| Contribution Profit | Net fee revenue − processing cost. |
| Contribution Margin | Contribution profit ÷ net fee revenue × 100. |

**Important distinctions**

- TPV represents payment volume, not platform revenue.
- Refund principal and chargeback principal are tracked separately from fee revenue.
- Contribution profit reflects the costs included in the dataset; it is not equivalent to total company profit.
- Processing costs use illustrative payment-method-specific rates and should be treated as modeling assumptions, not actual provider pricing. Contribution profit and margin are therefore estimates under the project's defined cost model.
- When net fee revenue is zero, contribution margin should be returned as `NULL` or treated as undefined rather than dividing by zero.

---

### 3. Fee Revenue and Reversal Logic

The `transaction_fees` table contains:

- `gross_fee_revenue`
- `processing_cost`
- `fee_reversal`
- `transaction_id`
- `currency`

The financial calculations are:

```text
Net Fee Revenue = Gross Fee Revenue - Fee Reversal

Contribution Profit = Net Fee Revenue - Processing Cost

Contribution Margin (%) =
    Contribution Profit / Net Fee Revenue * 100
```

A fee reversal reduces net fee revenue but does not, by itself, reduce TPV or change the original transaction's success status.

Fee reversals are recorded separately rather than overwriting the original gross fee. Both full and partial reversals are included.

**Validation rules**

- Gross fee revenue must not be negative.
- Fee reversals must not be negative.
- Fee reversals must not exceed the corresponding gross fee revenue.
- Each transaction must have no more than one transaction-fee record in the current dataset.
- Reversal amounts must be deducted exactly once.

---

### 4. Transaction and Merchant Analytics

Transaction-level analysis uses the transaction status and amount to measure payment activity.

Merchant-level profitability is calculated by aggregating successful transaction volume and the associated fee and cost records for each merchant.

Key analytical dimensions include:

- Merchant
- Payment method
- Transaction date and month
- Transaction status

Merchant profitability analysis supports:

- Ranking merchants by contribution profit.
- Identifying merchants with below-platform contribution margins.
- Comparing profitability across payment methods.
- Reviewing fee reversal patterns.
- Evaluating revenue concentration among the highest-revenue merchants.

**Interpretation rule:** A low contribution margin indicates weaker profitability under the defined cost model. It does not, by itself, establish that a merchant is fraudulent or commercially unviable.

---

### 5. Refund Logic

Refund records are evaluated using their status:

| Status | Interpretation |
|---|---|
| `COMPLETED` | Refund is recorded as completed. |
| `PENDING` | Refund is awaiting completion. |
| `FAILED` | Refund attempt failed. |

Refund analysis includes request count, status distribution, completed refund principal, and payment-method or merchant comparisons.

**Business rules**

- Completed refund principal is calculated from records with status `COMPLETED`.
- Pending and failed refund amounts must be reported separately.
- Refund principal is not automatically classified as platform financial loss.
- Refund principal must not be subtracted from TPV or fee revenue unless a separately defined metric explicitly requires that treatment.
- Refunds must be aggregated independently before joining to other one-to-many transaction records.

---

### 6. Chargeback Logic

Chargeback analysis uses the chargeback status, principal amount, and associated fee.

| Status | Interpretation |
|---|---|
| `OPEN` | Case remains open. |
| `UNDER_REVIEW` | Case is under review. |
| `WON` | Case was won. |
| `LOST` | Case was lost. |

Key measures include total chargeback cases, lost cases, lost-case rate, chargeback principal, and chargeback fees.

```text
Lost-Case Rate (%) =
    Lost Chargeback Cases / Total Chargeback Cases * 100
```

**Important distinctions**

- The lost-case rate is a case-count metric, not a financial loss rate.
- Lost chargeback principal and chargeback fees must be reported separately.
- Open and under-review cases must not be treated as confirmed losses.
- Chargeback principal must not automatically be classified as platform loss.
- A merchant chargeback rate based on chargeback records divided by successful transactions is only a record-count proxy unless chargebacks are deduplicated to distinct transactions.

---

### 7. Settlement and Reconciliation Logic

Settlement analysis compares the actual settlement amount with the expected settlement amount.

```text
Settlement Variance = Actual Settlement - Expected Settlement
```

| Condition | Classification |
|---|---|
| Variance < 0 | Short settlement |
| Variance > 0 | Excess settlement |
| Variance = 0 | Matched settlement |

The analysis tracks settlement count, settlements with variance, net variance, absolute variance, and merchant-level discrepancies.

- **Net variance** is the signed sum of settlement variances.
- **Absolute variance** is the sum of the absolute values of individual settlement variances.
- A negative net variance can coexist with a larger absolute variance because positive and negative discrepancies offset each other.

A settlement variance indicates a discrepancy requiring investigation. It is not automatically a confirmed financial loss.

The current synthetic expected-settlement logic is based on successful transaction amount less **gross fee revenue**, with an expected settlement date two days after the transaction. Refund and chargeback effects are not incorporated into this expected-settlement calculation.

Because the settlement calculation deducts gross fee revenue rather than net fee revenue after reversals, settlement variance is measured against this defined synthetic baseline and may not represent a fully adjusted real-world settlement obligation.

Reconciliation exceptions are categorized as:

- `AMOUNT_MISMATCH`
- `TIMING_DIFFERENCE`
- `MISSING_SETTLEMENT`
- `FEE_MISMATCH`
- `DUPLICATE_RECORD`

Exception amount represents the recorded amount associated with an exception. It must not be presented as confirmed financial impact unless that impact has been independently validated.

The synthetic exception categories are generated independently. Therefore, category labels alone do not prove that an operational failure or duplicate actually occurred.

---

### 8. Aggregation, Joins, and Date Rules

To maintain financial accuracy:

1. **Prevent join multiplication.** Refunds, chargebacks, settlements, and other related records may contain multiple rows per transaction. Aggregate each table to the required reporting grain before joining it to another one-to-many table.
2. **Use the correct transaction date.** Transaction-based monthly analysis uses `transactions.created_at`.
3. **Use fee-table column names as defined.** The gross fee field is `transaction_fees.gross_fee_revenue`, not `gross_fee`.
4. **Use consistent reporting grains.** Transaction, merchant, payment-method, monthly, settlement, refund, chargeback, and exception analyses are not interchangeable.
5. **Preserve metric-specific populations.** TPV and fee revenue use successful transactions and their associated fee records. Transaction success rate uses all transaction attempts.
6. **Avoid unsupported assumptions.** Do not infer causation, confirmed loss, fraud, or operational failure from a correlation, discrepancy, or synthetic category alone.

---

### 9. Reconciliation and Quality Checks

The following checks should be maintained as the project evolves:

- Transaction and fee record counts reconcile to the expected dataset.
- Transaction IDs are unique in the transaction table.
- Fee records map to valid transactions.
- Fee reversal amounts are valid and deducted once.
- Overall revenue and profitability reconcile with the monthly totals.
- Refund and chargeback statuses reconcile with their respective totals.
- Settlement classifications reconcile to the total settlement count.
- Exception totals reconcile to category counts.
- Recorded exception amounts remain separate from confirmed financial impact.
- Merchant and payment-method totals reconcile to platform totals when they use the same population and definitions.

---

### 10. Current Validated Financial Baseline

The following figures represent the current synthetic dataset and serve as reconciliation checkpoints.

| Metric | Validated value |
|---|---:|
| Total transaction attempts | 20,000 |
| Successful transactions | 16,994 |
| Transaction success rate | 84.97% |
| Total payment volume | ₹213,374,487.23 |
| Gross fee revenue | ₹3,663,791.42 |
| Fee reversals | ₹140,539.56 |
| Net fee revenue | ₹3,523,251.86 |
| Processing cost | ₹1,982,289.95 |
| Contribution profit | ₹1,540,961.91 |
| Contribution margin | 43.74% |
| Settlements with variance | 1,595 |
| Absolute settlement variance | ₹85,850.00 |
| Completed refund principal | ₹6,023,583.38 |
| Lost chargeback principal | ₹525,738.74 |
| Lost chargeback fees | ₹12,192.85 |
| Recorded exception amount | ₹1,580,213.47 |
| Confirmed exception financial impact | ₹0.00 |

These values are checkpoints for validating SQL and downstream API responses. They should be updated if the source data or business rules change.

---

### 11. How to Use This Document

Read this document before reviewing `sql/02_financial_analytics.sql`.

- **This document** defines the business meaning and rules.
- **The SQL file** implements the calculations and analytical queries.
- **The FastAPI layer** will expose selected metrics through endpoints, using these definitions consistently.
- **Power BI** will present the validated metrics and business findings.

If a metric definition changes, update this document and the corresponding SQL implementation together.
