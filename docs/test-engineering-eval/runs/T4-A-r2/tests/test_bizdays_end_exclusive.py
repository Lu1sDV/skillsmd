from datetime import date

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: [Fri 2024-03-01, Mon 2024-03-04) contains one business day.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_end_on_weekday_is_excluded():
    # [Mon, Wed) = Mon, Tue
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_business_days_between_start_included_end_excluded_single_day():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1


def test_business_days_between_end_not_after_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
    assert business_days_between(date(2024, 3, 5), date(2024, 3, 4)) == 0
