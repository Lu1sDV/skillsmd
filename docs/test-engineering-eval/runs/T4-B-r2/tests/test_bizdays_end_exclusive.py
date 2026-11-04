from datetime import date

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: [Fri, Mon) = Fri, Sat, Sun -> 1 business day (was 2).
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_end_on_weekday_is_excluded():
    # [Mon, Wed) = Mon, Tue -> 2
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_business_days_between_start_on_weekday_is_included():
    # [Fri, Sat) = Fri -> 1
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 2)) == 1


def test_business_days_between_end_equals_start_returns_zero():
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 1)) == 0
