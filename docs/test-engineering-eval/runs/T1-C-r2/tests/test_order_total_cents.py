"""Tests for pricing.order_total_cents; expected values are hand-computed from SPEC.md."""
import pytest

from pricing import order_total_cents

# SPEC: "10 or more" / "50 or more" are inclusive. The code uses > so the exact
# thresholds are discounted one tier too low. Strict xfail: turns red when fixed.
BUG_THRESHOLD = pytest.mark.xfail(
    strict=True, reason="defect: thresholds 10 and 50 are exclusive in code, SPEC says inclusive"
)


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (1, 100, 100),  # no discount
        (9, 100, 900),  # just under the 5% tier
        (11, 100, 1045),  # inside 5% tier: 1100 * 0.95
        (49, 100, 4655),  # just under the 10% tier: 4900 * 0.95
        (51, 100, 4590),  # inside 10% tier: 5100 * 0.90
        (100, 250, 22500),  # 25000 * 0.90
        (10, 0, 0),  # free item is valid
        (1, 0, 0),
        (10**6, 10**6, 9 * 10**11),  # large values stay exact (no float): 1e12 * 0.9
    ],
)
def test_total_by_tier(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        pytest.param(10, 100, 950, marks=BUG_THRESHOLD, id="10-units-get-5pct"),  # 1000 * 0.95
        pytest.param(50, 100, 4500, marks=BUG_THRESHOLD, id="50-units-get-10pct"),  # 5000 * 0.90
    ],
)
def test_threshold_quantities_are_discounted(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (11, 10, 105),  # 110 * 0.95 = 104.5 -> half up
        (11, 1, 10),  # 10.45 -> rounds down
        (11, 3, 31),  # 31.35 -> rounds down
        (11, 9, 94),  # 94.05 -> rounds down
        (55, 1, 50),  # 55 * 0.90 = 49.5 -> half up
        (51, 1, 46),  # 45.9 -> rounds up
        (60, 1, 54),  # 54.0 exact
    ],
)
def test_discounted_totals_round_half_up(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize("quantity", [0, -1, -100])
def test_quantity_below_one_raises(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, 100)


@pytest.mark.parametrize("quantity", [1, 10, 50])
def test_negative_price_raises(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, -1)
