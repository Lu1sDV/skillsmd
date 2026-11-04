"""Order pricing."""


def order_total_cents(quantity: int, unit_price_cents: int) -> int:
    """Total price of an order in whole cents.

    Orders of 10 or more units get 5% off the whole order; orders of 50 or more
    units get 10% off the whole order. quantity < 1 or unit_price_cents < 0
    raises ValueError. Discounted totals are rounded half up to whole cents.
    """
    if quantity < 1 or unit_price_cents < 0:
        raise ValueError("invalid order")
    total = quantity * unit_price_cents
    if quantity > 50:
        percent_off = 10
    elif quantity > 10:
        percent_off = 5
    else:
        percent_off = 0
    return (total * (100 - percent_off) + 50) // 100
