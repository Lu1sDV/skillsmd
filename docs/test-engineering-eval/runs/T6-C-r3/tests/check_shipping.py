"""Tests for shipping_cents. Expected values are worked by hand from SPEC.md.

Express costs are always whole cents (base is 500 + 200*k, always even), so the
"rounded down" clause cannot be observed through this function and is not tested.
"""
import pytest

from shipping import shipping_cents

# Spec: "Each additional 500 g, or part of it, adds 200 cents" -> ceiling.
# src/shipping.py uses floor division, so partial steps are not charged.
partial_step_bug = pytest.mark.xfail(
    strict=True,
    reason="defect: partial 500 g step not charged (floor instead of ceiling)",
)


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 500),      # minimum valid weight
        (999, 500),
        (1000, 500),   # upper edge of base tier
        (1500, 700),   # exactly one extra 500 g
        (2000, 900),   # exactly two extra
        (5000, 2100),  # eight extra: 500 + 8*200
    ],
)
def test_standard_whole_steps(weight, expected):
    assert shipping_cents(weight) == expected


@pytest.mark.parametrize(
    "weight, expected",
    [
        (1, 750),
        (1000, 750),
        (1500, 1050),  # 700 * 1.5
        (2000, 1350),  # 900 * 1.5
    ],
)
def test_express_whole_steps(weight, expected):
    assert shipping_cents(weight, express=True) == expected


@partial_step_bug
@pytest.mark.parametrize(
    "weight, expected",
    [
        (1001, 700),   # 1 g over -> one extra step
        (1499, 700),
        (1501, 900),   # 1 g into the second step
        (2001, 1100),
        (4999, 2100),  # 3999 g over -> eight steps
    ],
)
def test_standard_partial_step_is_charged(weight, expected):
    assert shipping_cents(weight) == expected


@partial_step_bug
@pytest.mark.parametrize(
    "weight, expected",
    [
        (1001, 1050),  # 700 * 1.5
        (1501, 1350),  # 900 * 1.5
    ],
)
def test_express_partial_step_is_charged(weight, expected):
    assert shipping_cents(weight, express=True) == expected


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_non_positive_weight_raises(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
