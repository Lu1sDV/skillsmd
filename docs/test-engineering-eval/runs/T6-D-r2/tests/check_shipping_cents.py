import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("w", [1, 500, 999, 1000])
def test_base_tier(w):
    assert shipping_cents(w) == 500


@pytest.mark.parametrize(
    "w, cents",
    [
        (1001, 700),  # part of an additional 500 g counts as a full step
        (1499, 700),
        (1500, 700),
        (1501, 900),
        (2000, 900),
        (2001, 1100),
        (3000, 1300),
    ],
)
def test_additional_steps_round_up(w, cents):
    assert shipping_cents(w) == cents


@pytest.mark.parametrize(
    "w, cents",
    [
        (1, 750),
        (1000, 750),
        (1001, 1050),
        (1501, 1350),
        (2001, 1650),
    ],
)
def test_express_adds_50_percent(w, cents):
    assert shipping_cents(w, express=True) == cents


def test_express_default_is_false():
    assert shipping_cents(1200) == shipping_cents(1200, express=False)


@pytest.mark.parametrize("w", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_non_positive_weight_raises(w, express):
    with pytest.raises(ValueError):
        shipping_cents(w, express=express)
