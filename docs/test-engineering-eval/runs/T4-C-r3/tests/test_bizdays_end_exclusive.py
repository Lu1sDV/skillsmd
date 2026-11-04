from datetime import date

import pytest

from bizdays import business_days_between


def test_friday_to_following_monday_counts_only_friday():
    # Bug report: [Fri 2024-03-01, Mon 2024-03-04) = Fri, Sat, Sun -> 1 business day.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_end_date_is_excluded_when_it_is_a_weekday():
    # [Mon 2024-03-04, Wed 2024-03-06) = Mon, Tue -> 2 (Wed excluded).
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_one_day_range_counts_start_only():
    # [Mon, Tue) = Mon -> 1.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1


@pytest.mark.parametrize("end", [date(2024, 3, 4), date(2024, 3, 1)])
def test_returns_zero_when_end_not_after_start(end):
    assert business_days_between(date(2024, 3, 4), end) == 0
