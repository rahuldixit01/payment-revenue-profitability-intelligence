
import pytest

from api.analytics import get_overall_payment_performance


@pytest.fixture(scope="module")
def performance():
    return get_overall_payment_performance()


def test_transaction_counts(performance):
    assert performance["total_attempts"] == 20000
    assert performance["successful_transactions"] == 16994
    assert performance["failed_transactions"] == 2057
    assert performance["cancelled_transactions"] == 949


def test_payment_success_rate(performance):
    assert performance["success_rate_pct"] == 84.97


def test_revenue_and_profitability(performance):
    assert performance["total_payment_volume"] == pytest.approx(
        213374487.23, abs=0.01
    )
    assert performance["gross_fee_revenue"] == pytest.approx(
        3663791.42, abs=0.01
    )
    assert performance["fee_reversals"] == pytest.approx(
        140539.56, abs=0.01
    )
    assert performance["net_fee_revenue"] == pytest.approx(
        3523251.86, abs=0.01
    )
    assert performance["processing_cost"] == pytest.approx(
        1982289.95, abs=0.01
    )
    assert performance["contribution_profit"] == pytest.approx(
        1540961.91, abs=0.01
    )
    assert performance["contribution_margin_pct"] == 43.74
