"""Tests for pricing.order_total_cents, written against SPEC.md."""
import pytest

from pricing import order_total_cents


# --- no discount -----------------------------------------------------------

@pytest.mark.parametrize("qty, price, expected", [
    (1, 100, 100),
    (9, 100, 900),
    (1, 0, 0),
])
def test_order_total_cents_below_ten_units_no_discount(qty, price, expected):
    assert order_total_cents(qty, price) == expected


# --- 5% tier (10..49) ------------------------------------------------------

@pytest.mark.parametrize("qty, price, expected", [
    (10, 100, 950),   # lower boundary: 10 units already discounted
    (11, 100, 1045),
    (49, 100, 4655),  # upper boundary of tier
])
def test_order_total_cents_ten_to_49_units_gets_5_percent_off(qty, price, expected):
    assert order_total_cents(qty, price) == expected


# --- 10% tier (50+) --------------------------------------------------------

@pytest.mark.parametrize("qty, price, expected", [
    (50, 100, 4500),  # lower boundary: 50 units already at 10%
    (51, 100, 4590),
    (1000, 100, 90000),
])
def test_order_total_cents_50_or_more_units_gets_10_percent_off(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_order_total_cents_tier_boundaries_are_monotonic_in_discount():
    # per-unit effective price must never rise when quantity crosses a tier
    assert order_total_cents(10, 100) < order_total_cents(9, 100) + 100
    assert order_total_cents(50, 100) < order_total_cents(49, 100) + 100


# --- rounding (half up to whole cents) -------------------------------------

@pytest.mark.parametrize("qty, price, expected", [
    (11, 10, 105),   # 104.5 -> 105 (exact half rounds up)
    (14, 5, 67),     # 66.5  -> 67
    (30, 1, 29),     # 28.5  -> 29
    (11, 1, 10),     # 10.45 -> 10 (below half rounds down)
    (21, 1, 20),     # 19.95 -> 20 (above half rounds up)
    (59, 1, 53),     # 53.1  -> 53 (10% tier, below half rounds down)
    (55, 1, 50),     # 49.5  -> 50 (10% tier, exact half rounds up)
    (53, 1, 48),     # 47.7  -> 48 (10% tier, above half rounds up)
])
def test_order_total_cents_discounted_total_rounds_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_order_total_cents_undiscounted_total_is_exact_integer():
    assert order_total_cents(3, 33) == 99


def test_order_total_cents_returns_int():
    assert type(order_total_cents(10, 5)) is int


# --- invalid input ---------------------------------------------------------

@pytest.mark.parametrize("qty", [0, -1, -100])
def test_order_total_cents_quantity_below_one_raises_value_error(qty):
    with pytest.raises(ValueError):
        order_total_cents(qty, 100)


@pytest.mark.parametrize("price", [-1, -100])
def test_order_total_cents_negative_unit_price_raises_value_error(price):
    with pytest.raises(ValueError):
        order_total_cents(1, price)


def test_order_total_cents_zero_unit_price_is_allowed():
    assert order_total_cents(10, 0) == 0


def test_order_total_cents_invalid_quantity_and_price_raises_value_error():
    with pytest.raises(ValueError):
        order_total_cents(0, -1)
