from datetime import date

import pytest

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: [Fri 2024-03-01, Mon 2024-03-04) contains only Friday.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_excludes_end_when_end_is_weekday():
    # Mon..Wed (end excluded) = Mon, Tue
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_business_days_between_includes_start_when_start_is_weekday():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1


def test_business_days_between_full_week_returns_five():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 11)) == 5


@pytest.mark.parametrize(
    "start, end",
    [
        (date(2024, 3, 4), date(2024, 3, 4)),  # equal
        (date(2024, 3, 5), date(2024, 3, 4)),  # end before start
    ],
)
def test_business_days_between_end_not_after_start_returns_zero(start, end):
    assert business_days_between(start, end) == 0
