"""Shipping costs."""


def shipping_cents(weight_g: int, express: bool = False) -> int:
    """Shipping cost in whole cents.

    Up to 1000 g costs 500. Each additional 500 g, or part of it, adds 200.
    Express shipping adds 50% to the total, rounded down to whole cents.
    weight_g < 1 raises ValueError.
    """
    if weight_g < 1:
        raise ValueError("weight must be positive")
    extra = max(0, weight_g - 1000)
    steps = extra // 500
    cost = 500 + 200 * steps
    if express:
        cost = cost * 3 // 2
    return cost
