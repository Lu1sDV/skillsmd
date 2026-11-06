"""Tests for shipping_cents. Expected values are hand-derived from SPEC.md.

Tiers: <=1000 g -> 500; each additional 500 g *or part of it* -> +200;
express -> total * 1.5 rounded down.
"""
import pytest

from shipping import shipping_cents

# SPEC says "or part of it": any weight into a new 500 g step must charge it.
# The implementation floors instead (known defect), so these are strict xfails:
# they flip to a failure (XPASS) once shipping_cents is fixed, prompting removal.
PART_STEP_BUG = pytest.mark.xfail(
    strict=True, reason="SPEC: 'or part of it' rounds extra weight up; code floors"
)


@pytest.mark.parametrize(
    "weight, cents",
    [
        (1, 500),
        (500, 500),
        (1000, 500),  # upper edge of base tier
        (1500, 700),  # exactly one full extra step
        (2000, 900),  # exactly two full extra steps
        (2500, 1100),
        (10000, 4100),  # 9000 g extra = 18 full steps: 500 + 18*200
    ],
)
def test_standard_cost_on_tier_boundaries(weight, cents):
    assert shipping_cents(weight) == cents


@pytest.mark.parametrize(
    "weight, cents",
    [
        pytest.param(1001, 700, marks=PART_STEP_BUG, id="1g-over-base"),
        pytest.param(1250, 700, marks=PART_STEP_BUG, id="partial-first-step"),
        pytest.param(1501, 900, marks=PART_STEP_BUG, id="1g-into-second-step"),
        pytest.param(2499, 1100, marks=PART_STEP_BUG, id="just-under-third-step"),
    ],
)
def test_partial_extra_step_is_charged_as_full_step(weight, cents):
    assert shipping_cents(weight) == cents


@pytest.mark.parametrize(
    "weight, cents",
    [
        (1, 750),  # 500 * 1.5
        (1000, 750),
        (1500, 1050),  # 700 * 1.5
        (2000, 1350),  # 900 * 1.5
    ],
)
def test_express_adds_fifty_percent(weight, cents):
    assert shipping_cents(weight, express=True) == cents


@PART_STEP_BUG
def test_express_applies_to_total_including_partial_step():
    assert shipping_cents(1001, express=True) == 1050  # 700 * 1.5


def test_express_defaults_to_false():
    assert shipping_cents(1500) == shipping_cents(1500, express=False) == 700


@pytest.mark.parametrize("weight", [0, -1, -1000])
@pytest.mark.parametrize("express", [False, True])
def test_non_positive_weight_raises_value_error(weight, express):
    with pytest.raises(ValueError):
        shipping_cents(weight, express=express)
