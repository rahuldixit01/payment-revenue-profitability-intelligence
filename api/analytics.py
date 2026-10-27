
from sqlalchemy import text

from api.database import create_db_engine

from datetime import date


def get_overall_payment_performance():
    query = text("""
        SELECT
            COUNT(*) AS total_attempts,

            COUNT(*) FILTER (
                WHERE t.status = 'SUCCESS'
            ) AS successful_transactions,

            COUNT(*) FILTER (
                WHERE t.status = 'FAILED'
            ) AS failed_transactions,

            COUNT(*) FILTER (
                WHERE t.status = 'CANCELLED'
            ) AS cancelled_transactions,

            COALESCE(
                SUM(t.amount) FILTER (
                    WHERE t.status = 'SUCCESS'
                ),
                0
            ) AS total_payment_volume,

            COALESCE(SUM(f.gross_fee_revenue), 0)
                AS gross_fee_revenue,

            COALESCE(SUM(f.fee_reversal), 0)
                AS fee_reversals,

            COALESCE(
                SUM(f.gross_fee_revenue - f.fee_reversal),
                0
            ) AS net_fee_revenue,

            COALESCE(SUM(f.processing_cost), 0)
                AS processing_cost

        FROM transactions t
        LEFT JOIN transaction_fees f
            ON t.transaction_id = f.transaction_id;
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            result = connection.execute(query).mappings().one()
            metrics = dict(result)

        total_attempts = metrics["total_attempts"]
        successful_transactions = metrics["successful_transactions"]
        net_fee_revenue = float(metrics["net_fee_revenue"])
        processing_cost = float(metrics["processing_cost"])

        metrics["success_rate_pct"] = (
            round(successful_transactions / total_attempts * 100, 2)
            if total_attempts else 0
        )

        metrics["contribution_profit"] = round(
            net_fee_revenue - processing_cost, 2
        )

        metrics["contribution_margin_pct"] = (
            round(
                metrics["contribution_profit"] / net_fee_revenue * 100,
                2,
            )
            if net_fee_revenue else 0
        )

        for field in (
            "total_payment_volume",
            "gross_fee_revenue",
            "fee_reversals",
            "net_fee_revenue",
            "processing_cost",
        ):
            metrics[field] = round(float(metrics[field]), 2)

        return metrics

    
    finally:
        engine.dispose()



def get_merchant_profitability(limit: int = 10, start_date: date = None,
    end_date: date = None,):
    query = text("""
        SELECT
            m.merchant_id,
            m.merchant_name,
            COUNT(t.transaction_id) AS successful_transactions,
            SUM(t.amount) AS tpv,
            SUM(f.gross_fee_revenue - f.fee_reversal)
                AS net_fee_revenue,
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
                    SUM(f.gross_fee_revenue - f.fee_reversal),
                    0
                ),
                2
            ) AS contribution_margin_pct
        FROM merchants m
        INNER JOIN transactions t
            ON m.merchant_id = t.merchant_id
        INNER JOIN transaction_fees f
            ON t.transaction_id = f.transaction_id
        WHERE t.status = 'SUCCESS'
            AND (
                    CAST(:start_date AS date) IS NULL
                    OR t.created_at >= CAST(:start_date AS date)
                )
                AND (
                    CAST(:end_date AS date) IS NULL
                    OR t.created_at < (
                        CAST(:end_date AS date) + INTERVAL '1 day'
                    )
                )
        GROUP BY m.merchant_id, m.merchant_name
        ORDER BY contribution_profit DESC
        LIMIT :limit;
    """)

    engine = create_db_engine()

    try:
        with engine.connect() as connection:
            result = connection.execute(
                query, {
                        "limit": limit,
                        "start_date": start_date,
                        "end_date": end_date,
                                },
                        ).mappings().all()

            merchants = [dict(row) for row in result]

        money_fields = (
            "tpv",
            "net_fee_revenue",
            "processing_cost",
            "contribution_profit",
        )

        for merchant in merchants:
            for field in money_fields:
                merchant[field] = round(float(merchant[field]), 2)

            merchant["contribution_margin_pct"] = float(
                merchant["contribution_margin_pct"] or 0
            )

        return merchants

    finally:
        engine.dispose()
