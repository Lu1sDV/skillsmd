import pytest

from pricing import order_total_cents


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (1, 100, 100),
        (9, 100, 900),
        (5, 0, 0),
        # 5% tier: 10..49 units
        (10, 100, 950),  # boundary: exactly 10 gets the discount
        (11, 100, 1045),
        (49, 100, 4655),
        # 10% tier: 50+ units
        (50, 100, 4500),  # boundary: exactly 50 gets the bigger discount
        (51, 100, 4590),
        (100, 100, 9000),
    ],
)
def test_totals_and_tier_boundaries(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize(
    "qty, price, expected",
    [
        (11, 10, 105),  # 104.5 -> 105 (half up, not banker's 104)
        (10, 15, 143),  # 142.5 -> 143
        (55, 1, 50),  # 49.5 -> 50
        (10, 1, 10),  # 9.5 -> 10
        (11, 1, 10),  # 10.45 -> 10 (below half rounds down)
        (50, 1, 45),  # exact 45.0
    ],
)
def test_discounted_total_rounds_half_up(qty, price, expected):
    assert order_total_cents(qty, price) == expected


@pytest.mark.parametrize("qty, price", [(0, 100), (-1, 100), (1, -1), (10, -5), (0, -1)])
def test_invalid_input_raises_value_error(qty, price):
    with pytest.raises(ValueError):
        order_total_cents(qty, price)
