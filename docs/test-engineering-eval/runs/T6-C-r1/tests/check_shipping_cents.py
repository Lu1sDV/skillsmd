"""Tests for shipping_cents, with expected values derived by hand from SPEC.md."""
import pytest

from shipping import shipping_cents

# SPEC: a part of an additional 500 g counts as a full step. The implementation floors
# instead, so cases that fall strictly inside a step are expected-fail (strict) until fixed.
PARTIAL_STEP_BUG = pytest.mark.xfail(
    strict=True, reason="defect: partial 500 g step not charged (floor instead of ceil)"
)


@pytest.mark.parametrize(
    "weight_g, cents",
    [
        (1, 500),  # minimum valid weight
        (999, 500),
        (1000, 500),  # upper edge of the base tier
        (1500, 700),  # exactly one full extra step
        (2000, 900),  # exactly two full extra steps
        (3000, 1300),  # four full extra steps
    ],
)
def test_standard_cost_at_whole_steps(weight_g, cents):
    assert shipping_cents(weight_g) == cents


@PARTIAL_STEP_BUG
@pytest.mark.parametrize(
    "weight_g, cents",
    [
        (1001, 700),  # 1 g over the base tier -> one extra step
        (1499, 700),
        (1501, 900),  # 1 g into the second extra step
        (2001, 1100),
    ],
)
def test_standard_cost_rounds_partial_step_up(weight_g, cents):
    assert shipping_cents(weight_g) == cents


@pytest.mark.parametrize(
    "weight_g, cents",
    [
        (1, 750),  # 500 * 1.5
        (1000, 750),
        (1500, 1050),  # 700 * 1.5
        (2000, 1350),  # 900 * 1.5
    ],
)
def test_express_adds_half_to_total(weight_g, cents):
    assert shipping_cents(weight_g, express=True) == cents


@PARTIAL_STEP_BUG
@pytest.mark.parametrize(
    "weight_g, cents",
    [
        (1001, 1050),  # base 700 * 1.5
        (1501, 1350),  # base 900 * 1.5
    ],
)
def test_express_applies_to_total_including_partial_step(weight_g, cents):
    assert shipping_cents(weight_g, express=True) == cents


def test_express_defaults_to_false():
    assert shipping_cents(1500) == shipping_cents(1500, express=False) == 700


@pytest.mark.parametrize("weight_g", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_non_positive_weight_raises_value_error(weight_g, express):
    with pytest.raises(ValueError):
        shipping_cents(weight_g, express=express)
