import pytest

from pricing import order_total_cents


@pytest.mark.parametrize("qty,price,expected", [
    (1, 100, 100),
    (9, 100, 900),
    (1, 0, 0),
    (11, 0, 0),
])
def test_order_total_cents_belowDiscountThreshold_noDiscount(qty, price, expected):
    assert order_total_cents(qty, price) == expected


# Spec: "10 or more" -> 5% off; "50 or more" -> 10% off.
def test_order_total_cents_atTenUnits_applies5PercentOff():
    assert order_total_cents(10, 100) == 950


def test_order_total_cents_aboveTenUnits_applies5PercentOff():
    assert order_total_cents(11, 100) == 1045
    assert order_total_cents(49, 100) == 4655


def test_order_total_cents_atFiftyUnits_applies10PercentOff():
    assert order_total_cents(50, 100) == 4500


def test_order_total_cents_aboveFiftyUnits_applies10PercentOff():
    assert order_total_cents(51, 100) == 4590
    assert order_total_cents(1000, 100) == 90000


def test_order_total_cents_discountAppliesToWholeOrder_notJustExtraUnits():
    assert order_total_cents(20, 200) == 3800


@pytest.mark.parametrize("qty,price,expected", [
    (11, 10, 105),   # 104.5 -> 105 (half rounds up)
    (11, 1, 10),     # 10.45 -> 10
    (11, 3, 31),     # 31.35 -> 31
    (11, 20, 209),   # 209.0 exact
    (50, 5, 225),    # 225.0 exact
    (51, 15, 689),   # 688.5 -> 689 (half rounds up)
    (10, 5, 48),     # 47.5 -> 48 (half rounds up)
])
def test_order_total_cents_discountedHalfCent_roundsHalfUp(qty, price, expected):
    assert order_total_cents(qty, price) == expected


def test_order_total_cents_returnsInt():
    assert isinstance(order_total_cents(11, 10), int)


@pytest.mark.parametrize("qty", [0, -1, -100])
def test_order_total_cents_quantityBelowOne_raisesValueError(qty):
    with pytest.raises(ValueError):
        order_total_cents(qty, 100)


def test_order_total_cents_negativePrice_raisesValueError():
    with pytest.raises(ValueError):
        order_total_cents(1, -1)


def test_order_total_cents_invalidBothArgs_raisesValueError():
    with pytest.raises(ValueError):
        order_total_cents(0, -1)
