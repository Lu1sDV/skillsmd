import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("weight", [1, 500, 999, 1000])
def test_shipping_cents_upToBase_costs500(weight):
    assert shipping_cents(weight) == 500


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1001, 700),  # part of an additional 500 g counts as a full step
        (1500, 700),  # exactly one additional 500 g
        (1501, 900),
        (2000, 900),
        (2001, 1100),
        (3000, 1300),
        (10000, 4100),
    ],
)
def test_shipping_cents_overBase_addsPerStartedHalfKilo(weight, expected):
    assert shipping_cents(weight) == expected


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 750),
        (1000, 750),
        (1001, 1050),
        (1500, 1050),
        (1501, 1350),
        (2001, 1650),
    ],
)
def test_shipping_cents_express_adds50Percent(weight, expected):
    assert shipping_cents(weight, express=True) == expected


def test_shipping_cents_expressDefaultsToFalse():
    assert shipping_cents(1200) == shipping_cents(1200, express=False)


def test_shipping_cents_express_returnsInt():
    assert isinstance(shipping_cents(1200, express=True), int)


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_shipping_cents_belowOneGram_raisesValueError(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
