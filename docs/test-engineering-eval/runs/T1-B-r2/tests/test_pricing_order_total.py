import pytest

from pricing import order_total_cents


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (1, 100, 100),
        (9, 100, 900),
        (3, 0, 0),
    ],
)
def test_order_total_cents_below_10_units_no_discount(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (10, 100, 950),  # boundary: 10 units gets 5% off
        (11, 100, 1045),
        (49, 100, 4655),  # last quantity at 5%
    ],
)
def test_order_total_cents_10_to_49_units_5_percent_off(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (50, 100, 4500),  # boundary: 50 units gets 10% off
        (51, 100, 4590),
        (100, 100, 9000),
    ],
)
def test_order_total_cents_50_or_more_units_10_percent_off(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


def test_order_total_cents_discount_applies_to_whole_order_not_extra_units():
    assert order_total_cents(20, 1000) == 19000


@pytest.mark.parametrize(
    "quantity, price, expected",
    [
        (10, 15, 143),  # 142.5 -> 143 (half up, not banker's rounding)
        (11, 10, 105),  # 104.5 -> 105
        (55, 1, 50),  # 49.5 -> 50
        (10, 11, 105),  # 104.5 -> 105
        (10, 13, 124),  # 123.5 -> 124
    ],
)
def test_order_total_cents_exact_half_cent_rounds_up(quantity, price, expected):
    assert order_total_cents(quantity, price) == expected


def test_order_total_cents_fraction_below_half_rounds_down():
    # 36 * 0.95 = 34.2 -> 34
    assert order_total_cents(12, 3) == 34


def test_order_total_cents_fraction_above_half_rounds_up():
    # 84 * 0.95 = 79.8 -> 80
    assert order_total_cents(12, 7) == 80


@pytest.mark.parametrize("quantity", [0, -1, -100])
def test_order_total_cents_quantity_below_1_raises_value_error(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, 100)


@pytest.mark.parametrize("price", [-1, -100])
def test_order_total_cents_negative_price_raises_value_error(price):
    with pytest.raises(ValueError):
        order_total_cents(1, price)


def test_order_total_cents_zero_price_is_valid():
    assert order_total_cents(1, 0) == 0


def test_order_total_cents_returns_int():
    assert isinstance(order_total_cents(10, 15), int)
