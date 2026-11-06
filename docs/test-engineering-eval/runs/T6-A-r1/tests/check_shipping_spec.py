import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("weight, expected", [
    (1, 500),
    (1000, 500),      # boundary: still base price
    (1001, 700),      # any part of an extra 500 g adds 200
    (1500, 700),
    (1501, 900),
    (2000, 900),
    (2001, 1100),
    (2500, 1100),
])
def test_shipping_cents_standard_weight_returns_spec_price(weight, expected):
    assert shipping_cents(weight) == expected


@pytest.mark.parametrize("weight, expected", [
    (1, 750),
    (1000, 750),
    (1001, 1050),     # 700 * 1.5
    (1501, 1350),     # 900 * 1.5
    (2001, 1650),     # 1100 * 1.5
])
def test_shipping_cents_express_adds_half_of_total(weight, expected):
    assert shipping_cents(weight, express=True) == expected


def test_shipping_cents_express_defaults_to_false():
    assert shipping_cents(1200) == shipping_cents(1200, express=False)


@pytest.mark.parametrize("weight", [0, -1, -1000])
def test_shipping_cents_below_one_gram_raises_value_error(weight):
    with pytest.raises(ValueError):
        shipping_cents(weight)
    with pytest.raises(ValueError):
        shipping_cents(weight, express=True)
