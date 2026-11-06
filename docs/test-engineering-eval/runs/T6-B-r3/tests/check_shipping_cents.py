import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("weight", [1, 500, 999, 1000])
def test_shipping_cents_upToBaseLimit_costs500(weight):
    assert shipping_cents(weight) == 500


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1001, 700),   # 1 g over: a partial step still counts
        (1499, 700),
        (1500, 700),   # exactly one full extra step
        (1501, 900),
        (2000, 900),   # exactly two full extra steps
        (2001, 1100),
        (5000, 2100),  # 8 full extra steps
    ],
)
def test_shipping_cents_aboveBaseLimit_addsPerStartedStep(weight, expected):
    assert shipping_cents(weight) == expected


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 750),
        (1000, 750),
        (1001, 1050),
        (1500, 1050),
        (1501, 1350),
        (2000, 1350),
    ],
)
def test_shipping_cents_express_adds50Percent(weight, expected):
    assert shipping_cents(weight, express=True) == expected


def test_shipping_cents_expressFalseExplicit_sameAsDefault():
    assert shipping_cents(1200, express=False) == shipping_cents(1200)


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_shipping_cents_belowOneGram_raisesValueError(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
