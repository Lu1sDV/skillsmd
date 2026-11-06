import pytest

from pricing import order_total_cents


# --- no discount tier ---

def test_order_total_cents_single_unit_returns_unit_price():
    assert order_total_cents(1, 250) == 250


def test_order_total_cents_nine_units_has_no_discount():
    assert order_total_cents(9, 100) == 900


def test_order_total_cents_zero_price_returns_zero():
    assert order_total_cents(100, 0) == 0


# --- 5% tier (10..49) ---

def test_order_total_cents_ten_units_gets_five_percent_off():
    assert order_total_cents(10, 100) == 950


def test_order_total_cents_eleven_units_gets_five_percent_off():
    assert order_total_cents(11, 100) == 1045


def test_order_total_cents_forty_nine_units_gets_five_percent_off():
    assert order_total_cents(49, 100) == 4655


# --- 10% tier (50+) ---

def test_order_total_cents_fifty_units_gets_ten_percent_off():
    assert order_total_cents(50, 100) == 4500


def test_order_total_cents_fifty_one_units_gets_ten_percent_off():
    assert order_total_cents(51, 100) == 4590


def test_order_total_cents_large_order_gets_ten_percent_off():
    assert order_total_cents(1000, 100) == 90000


# --- rounding: half up on discounted totals ---

def test_order_total_cents_five_percent_exact_half_rounds_up():
    # 10 * 5 = 50; 95% = 47.5 -> 48
    assert order_total_cents(10, 5) == 48


def test_order_total_cents_five_percent_below_half_rounds_down():
    # 12 * 1 = 12; 95% = 11.4 -> 11
    assert order_total_cents(12, 1) == 11


def test_order_total_cents_five_percent_second_exact_half_rounds_up():
    # 15 * 2 = 30; 95% = 28.5 -> 29
    assert order_total_cents(15, 2) == 29


def test_order_total_cents_ten_percent_exact_half_rounds_up():
    # 55 * 1 = 55; 90% = 49.5 -> 50
    assert order_total_cents(55, 1) == 50


def test_order_total_cents_ten_percent_below_half_rounds_down():
    # 56 * 1 = 56; 90% = 50.4 -> 50
    assert order_total_cents(56, 1) == 50



# --- invalid input ---

@pytest.mark.parametrize("quantity", [0, -1, -100])
def test_order_total_cents_quantity_below_one_raises_value_error(quantity):
    with pytest.raises(ValueError):
        order_total_cents(quantity, 100)


@pytest.mark.parametrize("price", [-1, -100])
def test_order_total_cents_negative_price_raises_value_error(price):
    with pytest.raises(ValueError):
        order_total_cents(5, price)


def test_order_total_cents_invalid_quantity_and_price_raises_value_error():
    with pytest.raises(ValueError):
        order_total_cents(0, -1)
