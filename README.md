# Payment Revenue & Profitability Intelligence

Payment businesses can process thousands of transactions without having a clear view of how fee reversals, processing costs, and settlement discrepancies affect financial performance.

This project builds a financial analytics API to measure payment performance, merchant contribution profitability, and reconciliation exceptions using synthetic payment data.

**Current status:** FastAPI, PostgreSQL analytics, and automated testing completed. Power BI integration is next.

## Business Problem

The project addresses three financial monitoring questions:

- **Payment performance:** How much payment volume succeeds, and how many attempts fail or are cancelled?
- **Revenue and profitability:** How do fee reversals and processing costs affect net fee revenue and contribution profit?
- **Financial reconciliation:** Which settlement discrepancies and recorded exceptions require further investigation?

## Key Findings

Results from the current synthetic dataset:

| Metric | Result |
|---|---:|
| Payment attempts | 20,000 |
| Successful transactions | 16,994 |
| Failed transactions | 2,057 |
| Cancelled transactions | 949 |
| Payment success rate | 84.97% |
| Total payment volume (TPV) | ₹213,374,487.23 |
| Gross fee revenue | ₹3,663,791.42 |
| Fee reversals | ₹140,539.56 |
| Net fee revenue | ₹3,523,251.86 |
| Processing cost | ₹1,982,289.95 |
| Contribution profit | ₹1,540,961.91 |
| Contribution margin | 43.74% |
| Settlements with recorded variance | 1,595 |
| Absolute settlement variance | ₹85,850 |

**Interpretation:** Fee reversals reduce gross fee revenue, while processing costs further reduce contribution profit. Settlement variances identify discrepancies to investigate; they are not automatically confirmed financial losses.

These figures describe the current synthetic dataset and analytical assumptions, not real payment-provider or merchant performance.

## Financial Metric Definitions

- **TPV:** Sum of successful transaction amounts.
- **Gross fee revenue:** Recorded gross fees before reversals.
- **Net fee revenue:** Gross fee revenue minus fee reversals.
- **Contribution profit:** Net fee revenue minus modelled processing costs.
- **Contribution margin:** Contribution profit divided by net fee revenue, expressed as a percentage.
- **Settlement variance:** Actual settlement amount minus expected settlement amount.

Processing costs are illustrative assumptions by payment method, not actual provider pricing. Settlement expectations currently use successful transaction amounts less gross fees, with an expected settlement date two days after the transaction date. Refunds and chargebacks are analysed separately and are not automatically deducted from this settlement calculation.

## Technical Architecture

```text
Synthetic Payment Data
          |
          v
Python Data Generation and Loading
          |
          v
PostgreSQL Database
          |
          v
SQL Financial Analytics
          |
          v
FastAPI Endpoints
          |
          v
JSON Responses
          |
          v
Power BI Integration — Next
```

### Technology Stack

- **Python** — synthetic data generation, validation, and API implementation
- **FastAPI** — REST API and request validation
- **PostgreSQL** — relational data storage and SQL analytics
- **SQLAlchemy + psycopg** — database connectivity and SQL execution
- **Pydantic** — response schemas and data validation
- **pytest** — automated testing and coverage measurement
- **Power BI** — planned reporting and visual analytics layer

## API Endpoints

| Endpoint | Purpose |
|---|---|
| `GET /health` | Health check |
| `GET /analytics/overview` | Overall payment performance and financial metrics |
| `GET /analytics/merchant-profitability` | Merchant-level profitability rankings with optional date filters |
| `GET /docs` | Interactive Swagger API documentation |

The merchant profitability endpoint supports `limit`, `start_date`, and `end_date` parameters.

Example:

```text
GET /analytics/merchant-profitability?limit=10&start_date=2026-09-01&end_date=2026-09-30
```

Dates use `YYYY-MM-DD` format. The endpoint rejects an end date earlier than the start date and validates the limit.

## Repository Structure

```text
payment-revenue-profitability-intelligence/
├── api/
│   ├── analytics.py
│   ├── config.py
│   ├── database.py
│   ├── main.py
│   ├── schemas.py
│   └── transactions.py
├── data/
│   ├── generate_data.py
│   ├── generate_chargebacks.py
│   ├── generate_exceptions.py
│   ├── generate_refunds.py
│   ├── generate_settlements.py
│   ├── load_data.py
│   ├── update_fee_reversals.py
│   └── *.csv
├── sql/
│   ├── schema.sql
│   ├── 01_data_validation.sql
│   ├── 02_financial_analytics.sql
│   └── sql_docs/
│       └── 00_business_logic.md
├── tests/
│   ├── test_analytics.py
│   ├── test_api.py
│   ├── test_db_connection.py
│   └── test_transactions.py
├── .gitignore
├── requirements.txt
└── README.md
```

The CSV files contain synthetic data. The repository also includes scripts for generating, loading, and updating the datasets.

## Local Setup

### Prerequisites

- Python
- PostgreSQL
- Git

### 1. Clone the repository

```powershell
git clone <YOUR_GITHUB_REPOSITORY_URL>
cd payment-revenue-profitability-intelligence
```

### 2. Create and activate a virtual environment

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
```

### 3. Install dependencies

```powershell
python -m pip install -r requirements.txt
```

### 4. Configure PostgreSQL

Create a PostgreSQL database named `payment_intelligence`, then configure the connection through environment variables.

In PowerShell:

```powershell
$env:DB_USER = "postgres"
$env:DB_HOST = "localhost"
$env:DB_PORT = "5432"
$env:DB_NAME = "payment_intelligence"
```

Set the password securely in the same terminal session:

```powershell
$secure = Read-Host "Enter your PostgreSQL password" -AsSecureString
$env:DB_PASSWORD = (New-Object System.Net.NetworkCredential("", $secure)).Password
```

Never commit database passwords, private credentials, or local environment files.

### 5. Prepare the database

Use the provided SQL schema and data-loading scripts according to the project's existing database setup.

**Important:** The existing loader inserts data into the database. Do not rerun it against an already populated database without first understanding its insert behaviour and preparing a safe reload or reset procedure.

### 6. Start the API

From the project root, in the same terminal where the database environment variables are configured:

```powershell
python -m uvicorn api.main:app --reload
```

Open:

- Health check: `http://127.0.0.1:8000/health`
- Swagger documentation: `http://127.0.0.1:8000/docs`
- Analytics overview: `http://127.0.0.1:8000/analytics/overview`

The API runs locally on port `8000`. PostgreSQL typically listens on port `5432`. Localhost access does not make the API publicly accessible over the internet.

## Testing and Validation

The latest recorded test run completed with:

- **22 tests passed**
- **100% statement coverage**
- 123 statements measured, with zero missed

Coverage measures which statements were executed by the test suite. It does not, by itself, guarantee that every possible scenario is correct.

The tests cover database connectivity, analytics results, API responses, transaction validation, date filters, and invalid inputs.

Run the tests from the project root:

```powershell
python -m pytest
```

To generate a coverage report:

```powershell
python -m pytest --cov=api --cov-report=term-missing
```

## Data and Analytical Limitations

- All generated payment records and associated merchant data are synthetic.
- Processing-cost assumptions are illustrative, not actual payment-provider fee schedules.
- Recorded settlement variances and reconciliation exceptions require investigation; they do not independently establish a realised loss.
- Refunds, chargebacks, and settlement discrepancies are tracked separately from the contribution-profit calculation.
- Results depend on the documented metric definitions and current dataset.

## Project Roadmap

- [x] Generate synthetic payment datasets
- [x] Create the PostgreSQL schema and load data
- [x] Implement SQL financial analytics
- [x] Build FastAPI endpoints
- [x] Add automated tests and validate API responses
- [ ] Connect Power BI to the API
- [ ] Build financial performance and merchant profitability reports
- [ ] Validate the end-to-end reporting workflow

## Project Scope & Future Direction

This project establishes the foundation for a scalable payment financial intelligence platform, combining SQL analytics, API-driven data access, database integration, and automated testing.

The architecture is designed to evolve toward production use through:

- **Reliable data pipelines** with stronger validation, reconciliation, and data-quality controls.
- **Scalable API services** with authentication, structured error handling, logging, and performance monitoring.
- **Financial intelligence** for revenue optimisation, contribution profitability, merchant performance, and financial risk analysis.
- **Integrated reporting** through Power BI for actionable business insights and financial decision-making.
- **Production readiness** through deployment, security controls, automated testing, and operational monitoring.

The current implementation provides a working foundation, using synthetic payment data to develop and validate the analytical workflows before integrating additional production-grade capabilities and real-world data sources.