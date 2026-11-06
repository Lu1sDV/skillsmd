import pytest

from shipping import shipping_cents


@pytest.mark.parametrize("w", [1, 500, 999, 1000])
def test_base_tier(w):
    assert shipping_cents(w) == 500


@pytest.mark.parametrize(
    "w, cents",
    [
        (1001, 700),  # part of an additional 500 g
        (1499, 700),
        (1500, 700),  # exactly one additional 500 g
        (1501, 900),
        (2000, 900),
        (2001, 1100),
        (5000, 2100),
    ],
)
def test_additional_steps_round_up(w, cents):
    assert shipping_cents(w) == cents


@pytest.mark.parametrize(
    "w, cents",
    [(1, 750), (1000, 750), (1001, 1050), (1500, 1050), (2001, 1650)],
)
def test_express_adds_half(w, cents):
    assert shipping_cents(w, express=True) == cents
    assert shipping_cents(w, True) == cents


@pytest.mark.parametrize("w", [0, -1, -1000])
def test_non_positive_weight_raises(w):
    with pytest.raises(ValueError):
        shipping_cents(w)
    with pytest.raises(ValueError):
        shipping_cents(w, express=True)


def test_returns_int():
    assert isinstance(shipping_cents(1200, express=True), int)
