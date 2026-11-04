import pytest

from pricing import order_total_cents


@pytest.mark.parametrize("qty,price,expected", [
    (1, 100, 100),
    (9, 100, 900),      # just below the 5% tier
    (1, 0, 0),
    (10, 100, 950),     # 5% tier starts at 10
    (11, 100, 1045),
    (49, 100, 4655),    # just below the 10% tier
    (50, 100, 4500),    # 10% tier starts at 50
    (51, 100, 4590),
    (100, 1, 90),
])
def test_tiers_and_boundaries(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty,price,expected", [
    (10, 5, 48),    # 47.5 -> 48 (half up, not banker's/floor)
    (10, 1, 10),    # 9.5 -> 10
    (10, 3, 29),    # 28.5 -> 29
    (10, 7, 67),    # 66.5 -> 67
    (50, 1, 45),    # exact
    (50, 3, 135),   # 135.0 exact
    (50, 5, 225),   # exact
    (11, 1, 10),    # 10.45 -> 10 (below half rounds down)
    (10, 2, 19),    # 19.0 exact
    (10, 4, 38),    # 38.0 exact
])
def test_rounding_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_returns_int():
    assert isinstance(order_total_cents(10, 5), int)


@pytest.mark.parametrize("qty,price", [
    (0, 100),
    (-1, 100),
    (1, -1),
    (10, -1),
    (0, -1),
])
def test_invalid_raises_value_error(qty, price):
    with pytest.raises(ValueError):
        order_total_cents(qty, price)
