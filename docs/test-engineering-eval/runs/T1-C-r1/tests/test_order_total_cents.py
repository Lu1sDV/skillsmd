"""Tests for pricing.order_total_cents; expected values are hand-computed from SPEC.md."""
import pytest

from pricing import order_total_cents

# SPEC says "10 or more" / "50 or more"; the code uses > (see SPEC.md vs src/pricing.py).
BOUNDARY_BUG = pytest.mark.xfail(
    strict=True,
    reason="defect: code uses quantity > 10 / > 50 but SPEC says >= 10 / >= 50",
)


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (1, 100, 100),
        (9, 100, 900),
        (1, 0, 0),
        (9, 0, 0),
    ],
)
def test_no_discount_below_10_units(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (11, 100, 1045),  # 1100 * 0.95
        (49, 100, 4655),  # 4900 * 0.95
    ],
)
def test_5_percent_off_between_11_and_49_units(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (51, 100, 4590),  # 5100 * 0.90
        (100, 100, 9000),
    ],
)
def test_10_percent_off_above_50_units(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@BOUNDARY_BUG
def test_exactly_10_units_get_5_percent_off():
    assert order_total_cents(10, 100) == 950  # 1000 * 0.95


@BOUNDARY_BUG
def test_exactly_50_units_get_10_percent_off():
    assert order_total_cents(50, 100) == 4500  # 5000 * 0.90


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (11, 10, 105),  # 110 * 0.95 = 104.5 -> half up
        (11, 1, 10),  # 10.45 -> down
        (55, 1, 50),  # 55 * 0.90 = 49.5 -> half up
        (51, 5, 230),  # 255 * 0.90 = 229.5 -> half up
        (13, 1, 12),  # 12.35 -> down
        (60, 1, 54),  # 54.0 exact
    ],
)
def test_discounted_totals_round_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@BOUNDARY_BUG
def test_rounding_half_up_at_10_units():
    assert order_total_cents(10, 5) == 48  # 50 * 0.95 = 47.5 -> 48; undiscounted would be 50


def test_returns_int():
    assert type(order_total_cents(11, 10)) is int


@pytest.mark.parametrize("qty", [0, -1, -100])
def test_quantity_below_1_raises(qty):
    with pytest.raises(ValueError):
        order_total_cents(qty, 100)


@pytest.mark.parametrize("price", [-1, -100])
def test_negative_unit_price_raises(price):
    with pytest.raises(ValueError):
        order_total_cents(1, price)


def test_zero_unit_price_is_valid():
    assert order_total_cents(5, 0) == 0
