"""Tests for pricing.order_total_cents; expected values are hand-computed from SPEC.md."""
import pytest

from pricing import order_total_cents

# Bug discovery: SPEC says ">= 10" / ">= 50" but src/pricing.py uses ">" (see report).
# strict xfail: turns into a failure (XPASS) once the code is fixed, prompting removal.
spec_boundary_bug = pytest.mark.xfail(
    strict=True, reason="src/pricing.py uses > 10 / > 50; SPEC says >= 10 / >= 50"
)


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (1, 100, 100),
        (9, 100, 900),  # just below the 5% tier
        (1, 0, 0),  # free item
        (5, 0, 0),
    ],
)
def test_no_discount_below_10_units(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (11, 100, 1045),  # 1100 * 0.95
        (49, 100, 4655),  # 4900 * 0.95, just below the 10% tier
        (20, 1000, 19000),
    ],
)
def test_five_percent_off_between_11_and_49_units(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (51, 100, 4590),  # 5100 * 0.90
        (100, 250, 22500),  # 25000 * 0.90
    ],
)
def test_ten_percent_off_above_50_units(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@spec_boundary_bug
def test_exactly_10_units_get_5_percent_off():
    assert order_total_cents(10, 100) == 950  # 1000 * 0.95


@spec_boundary_bug
def test_exactly_50_units_get_10_percent_off():
    assert order_total_cents(50, 100) == 4500  # 5000 * 0.90


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (11, 10, 105),  # 104.5 -> half up
        (11, 1, 10),  # 10.45 -> 10
        (12, 1, 11),  # 11.4 -> 11
        (13, 1, 12),  # 12.35 -> 12
        (21, 10, 200),  # 199.5 -> 200
        (51, 5, 230),  # 229.5 -> 230
        (51, 1, 46),  # 45.9 -> 46
        (52, 1, 47),  # 46.8 -> 47
    ],
)
def test_discounted_totals_round_half_up(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize("quantity", [0, -1, -100])
def test_quantity_below_one_raises(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, 100)


@pytest.mark.parametrize("price", [-1, -100])
def test_negative_price_raises(price):
    with pytest.raises(ValueError):
        order_total_cents(1, price)


def test_invalid_quantity_and_price_together_raises():
    with pytest.raises(ValueError):
        order_total_cents(0, -1)
