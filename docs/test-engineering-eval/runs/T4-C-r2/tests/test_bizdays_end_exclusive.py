from datetime import date

import pytest

from bizdays import business_days_between


@pytest.mark.xfail(
    strict=True,
    reason="bug report in SPEC.md: end date is counted (loop uses <= end); "
    "remove this marker when fixed",
)
def test_end_date_is_excluded_when_it_is_a_weekday():
    # Fri 2024-03-01 .. Mon 2024-03-04, half-open: Fri counts, Sat/Sun don't,
    # Mon (the end) is excluded -> 1.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1
