"""Tests for pricing.order_total_cents, written against SPEC.md."""
import pytest

from pricing import order_total_cents


def test_order_total_cents_below_first_tier_no_discount():
    assert order_total_cents(1, 250) == 250
    assert order_total_cents(9, 100) == 900


def test_order_total_cents_zero_price_returns_zero():
    assert order_total_cents(5, 0) == 0
    assert order_total_cents(100, 0) == 0


@pytest.mark.parametrize(
    "quantity, unit_price, expected",
    [
        (10, 100, 950),    # exactly 10 units: 5% off (spec: "10 or more")
        (11, 100, 1045),
        (49, 100, 4655),   # still 5% tier
        (50, 100, 4500),   # exactly 50 units: 10% off (spec: "50 or more")
        (51, 100, 4590),
        (100, 100, 9000),
    ],
)
def test_order_total_cents_tier_boundaries_apply_spec_discount(quantity, unit_price, expected):
    assert order_total_cents(quantity, unit_price) == expected


def test_order_total_cents_discount_applies_to_whole_order():
    # 20 units * 1000 = 20000, 5% off the whole order -> 19000
    assert order_total_cents(20, 1000) == 19000


@pytest.mark.parametrize(
    "quantity, unit_price, expected",
    [
        (11, 10, 105),   # 104.5 -> 105 (exact half rounds up)
        (11, 30, 314),   # 313.5 -> 314
        (21, 10, 200),   # 199.5 -> 200
        (11, 1, 10),     # 10.45 -> 10 (below half rounds down)
        (15, 1, 14),     # 14.25 -> 14
        (12, 1, 11),     # 11.4 -> 11
        (11, 3, 31),     # 31.35 -> 31
        (20, 3, 57),     # 57.0 exact
    ],
)
def test_order_total_cents_five_percent_tier_rounds_half_up(quantity, unit_price, expected):
    assert order_total_cents(quantity, unit_price) == expected


@pytest.mark.parametrize(
    "quantity, unit_price, expected",
    [
        (55, 1, 50),     # 49.5 -> 50 (exact half rounds up)
        (51, 5, 230),    # 229.5 -> 230
        (51, 1, 46),     # 45.9 -> 46
        (60, 1, 54),     # 54.0 exact
    ],
)
def test_order_total_cents_ten_percent_tier_rounds_half_up(quantity, unit_price, expected):
    assert order_total_cents(quantity, unit_price) == expected


def test_order_total_cents_ten_units_rounds_half_up():
    # 10 * 3 = 30; 5% off = 28.5 -> 29
    assert order_total_cents(10, 3) == 29


@pytest.mark.parametrize("quantity", [0, -1, -100])
def test_order_total_cents_quantity_below_one_raises_value_error(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, 100)


def test_order_total_cents_negative_price_raises_value_error():
    with pytest.raises(ValueError):
        order_total_cents(1, -1)


def test_order_total_cents_returns_int():
    assert isinstance(order_total_cents(10, 99), int)
    assert isinstance(order_total_cents(3, 99), int)
