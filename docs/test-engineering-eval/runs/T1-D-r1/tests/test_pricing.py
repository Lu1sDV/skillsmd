import pytest

from pricing import order_total_cents


@pytest.mark.parametrize("qty,price,expected", [
    (1, 100, 100),
    (9, 100, 900),
    (10, 100, 950),    # 10 units: 5% off (SPEC: "10 or more")
    (11, 100, 1045),
    (49, 100, 4655),
    (50, 100, 4500),   # 50 units: 10% off (SPEC: "50 or more")
    (51, 100, 4590),
    (1, 0, 0),
    (10, 0, 0),
])
def test_totals_and_tier_boundaries(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty,price,expected", [
    (10, 1, 10),       # 9.5 -> half up -> 10
    (10, 3, 29),       # 28.5 -> 29
    (10, 7, 67),       # 66.5 -> 67
    (10, 5, 48),       # 47.5 -> 48
    (50, 1, 45),       # 45.0 exact
    (50, 11, 495),     # 495.0 exact
    (11, 1, 10),       # 10.45 -> 10
    (30, 1, 29),       # 28.5 -> 29 (not on a tier boundary)
    (15, 2, 29),       # 28.5 -> 29
    (55, 1, 50),       # 49.5 -> 50
    (51, 1, 46),       # 45.9 -> 46
    (20, 1, 19),       # 19.0 exact
])
def test_discounted_rounding_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_returns_int():
    assert isinstance(order_total_cents(10, 3), int)


@pytest.mark.parametrize("qty,price", [(0, 100), (-1, 100), (1, -1), (10, -1), (0, -1)])
def test_invalid_raises_value_error(qty, price):
    with pytest.raises(ValueError):
        order_total_cents(qty, price)
