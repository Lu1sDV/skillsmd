import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("weight", [1, 500, 999, 1000])
def test_shipping_cents_up_to_1000g_costs_base_rate(weight):
    assert shipping_cents(weight) == 500


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1001, 700),   # 1 g over -> a part of a 500 g step
        (1499, 700),
        (1500, 700),   # exactly one full step
        (1501, 900),   # part of a second step
        (2000, 900),   # exactly two steps
        (2001, 1100),
    ],
)
def test_shipping_cents_over_1000g_adds_200_per_started_500g(weight, expected):
    assert shipping_cents(weight) == expected


def test_shipping_cents_5000g_costs_2100():
    # 4000 g extra = 8 full steps
    assert shipping_cents(5000) == 500 + 8 * 200


@pytest.mark.parametrize(
    "weight, expected",
    [(1, 750), (1000, 750), (1500, 1050), (2000, 1350)],
)
def test_shipping_cents_express_adds_50_percent(weight, expected):
    assert shipping_cents(weight, express=True) == expected


def test_shipping_cents_express_partial_step_uses_rounded_up_total():
    # 1001 g -> 700 base, express 1050
    assert shipping_cents(1001, express=True) == 1050


def test_shipping_cents_express_false_equals_default():
    assert shipping_cents(1200, express=False) == shipping_cents(1200)


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_shipping_cents_below_one_gram_raises_value_error(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
