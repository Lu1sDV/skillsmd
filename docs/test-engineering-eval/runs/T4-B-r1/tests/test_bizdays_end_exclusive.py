from datetime import date

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: returned 2 (Fri + Mon); end is exclusive so only Fri counts.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_excludes_weekday_end():
    # Mon -> Wed: Mon, Tue only.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_business_days_between_includes_weekday_start():
    # Mon -> Tue: just Monday.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1


def test_business_days_between_end_equal_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
