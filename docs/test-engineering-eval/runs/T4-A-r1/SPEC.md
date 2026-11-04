# bizdays
`business_days_between(start, end)` counts Monday-to-Friday days in the half-open range [start, end): start is included, end is excluded. Returns 0 when end <= start.

## Bug report
`business_days_between(date(2024, 3, 1), date(2024, 3, 4))` (Friday to the following Monday) returns 2; the reporter expected 1.
