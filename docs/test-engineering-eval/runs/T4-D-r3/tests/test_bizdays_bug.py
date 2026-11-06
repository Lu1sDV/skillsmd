from datetime import date

from bizdays import business_days_between


def test_friday_to_following_monday_excludes_end():
    # [Fri 2024-03-01, Mon 2024-03-04) contains only Friday.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_end_weekday_is_excluded():
    # Mon..Wed (end Wed excluded) -> Mon, Tue.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 6)) == 2


def test_end_not_after_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
    assert business_days_between(date(2024, 3, 5), date(2024, 3, 4)) == 0
