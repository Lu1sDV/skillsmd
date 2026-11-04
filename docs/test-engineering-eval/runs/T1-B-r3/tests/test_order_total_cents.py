import pytest

from pricing import order_total_cents


@pytest.mark.parametrize("qty,price,expected", [
    (1, 100, 100),
    (9, 100, 900),
    (5, 0, 0),
])
def test_order_total_cents_below_10_units_no_discount(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty,price,expected", [
    (10, 100, 950),    # lower boundary: 10 units already qualifies
    (11, 100, 1045),
    (49, 100, 4655),   # just below the 10% tier
])
def test_order_total_cents_10_to_49_units_gets_5_percent_off(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty,price,expected", [
    (50, 100, 4500),   # lower boundary: 50 units already qualifies
    (51, 100, 4590),
    (100, 100, 9000),
])
def test_order_total_cents_50_or_more_units_gets_10_percent_off(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty,price,expected", [
    (15, 2, 29),     # 28.5 -> 29
    (30, 1, 29),     # 28.5 -> 29
    (55, 1, 50),     # 49.5 -> 50
    (11, 1, 10),     # 10.45 -> 10
    (12, 1, 11),     # 11.4 -> 11
    (15, 1, 14),     # 14.25 -> 14
])
def test_order_total_cents_discounted_total_rounds_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_order_total_cents_returns_int():
    assert isinstance(order_total_cents(10, 5), int)


@pytest.mark.parametrize("qty,price", [
    (0, 100),
    (-1, 100),
    (1, -1),
    (10, -1),
    (0, -1),
])
def test_order_total_cents_invalid_input_raises_value_error(qty, price):
    with pytest.raises(ValueError):
        order_total_cents(qty, price)
