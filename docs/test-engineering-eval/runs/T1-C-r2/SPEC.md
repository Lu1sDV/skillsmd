# pricing
`order_total_cents(quantity, unit_price_cents)` returns the order total in whole cents.
- Orders of 10 or more units get 5% off the whole order.
- Orders of 50 or more units get 10% off the whole order.
- quantity < 1 or unit_price_cents < 0 raises ValueError.
- Discounted totals are rounded half up to whole cents.
