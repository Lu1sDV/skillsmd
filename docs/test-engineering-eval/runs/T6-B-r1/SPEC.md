# shipping
`shipping_cents(weight_g, express=False)`: up to 1000 g costs 500 cents. Each additional 500 g, or part of it, adds 200 cents. Express shipping adds 50% to the total, rounded down to whole cents. weight_g < 1 raises ValueError.
