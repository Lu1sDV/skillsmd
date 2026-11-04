from datetime import date

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: Fri 2024-03-01 -> Mon 2024-03-04, [start, end) => only Friday.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_excludes_weekday_end():
    # Mon -> Wed covers Mon, Tue only; Wed (end) is excluded.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_business_days_between_end_equal_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
