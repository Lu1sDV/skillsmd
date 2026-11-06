import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("w", [1, 999, 1000])
def test_shipping_cents_upToBase_costs500(w):
    assert shipping_cents(w) == 500


@pytest.mark.parametrize("w, cents", [(1500, 700), (2000, 900), (3000, 1300)])
def test_shipping_cents_exactMultiplesOf500Extra_addsPerStep(w, cents):
    assert shipping_cents(w) == cents


@pytest.mark.parametrize(
    "w, cents",
    [(1001, 700), (1499, 700), (1501, 900), (1999, 900), (2001, 1100)],
)
def test_shipping_cents_partialExtraStep_roundsUpToNextStep(w, cents):
    assert shipping_cents(w) == cents


@pytest.mark.parametrize(
    "w, cents",
    [(1, 750), (1000, 750), (1500, 1050), (2000, 1350), (1001, 1050)],
)
def test_shipping_cents_express_adds50Percent(w, cents):
    assert shipping_cents(w, express=True) == cents


def test_shipping_cents_expressFalseExplicit_sameAsDefault():
    assert shipping_cents(1500, express=False) == shipping_cents(1500)


@pytest.mark.parametrize("w", [0, -1, -1000])
def test_shipping_cents_nonPositiveWeight_raisesValueError(w):
    with pytest.raises(ValueError):
        shipping_cents(w)


@pytest.mark.parametrize("express", [False, True])
def test_shipping_cents_nonPositiveWeightExpress_raisesValueError(express):
    with pytest.raises(ValueError):
        shipping_cents(0, express=express)
