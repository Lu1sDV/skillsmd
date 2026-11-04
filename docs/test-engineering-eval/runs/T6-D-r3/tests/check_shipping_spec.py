import pytest

from shipping import shipping_cents


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 500),
        (999, 500),
        (1000, 500),
        (1001, 700),  # part of an additional 500 g counts
        (1500, 700),
        (1501, 900),
        (2000, 900),
        (2001, 1100),
        (5000, 2100),  # 8 extra steps of 500 g
    ],
)
def test_standard(weight, expected):
    assert shipping_cents(weight) == expected


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 750),
        (1000, 750),
        (1001, 1050),  # 700 * 1.5
        (1501, 1350),  # 900 * 1.5
        (2001, 1650),  # 1100 * 1.5
    ],
)
def test_express(weight, expected):
    assert shipping_cents(weight, express=True) == expected


def test_express_is_keyword_and_defaults_false():
    assert shipping_cents(1000, express=False) == shipping_cents(1000) == 500


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_non_positive_weight_raises(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
