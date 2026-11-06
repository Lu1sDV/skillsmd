from datetime import date

from bizdays import business_days_between


def test_friday_to_monday_excludes_end():
    # [Fri 3/1, Mon 3/4) contains only Friday (Sat/Sun are weekend, Mon excluded)
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_end_excluded_on_weekday():
    # [Mon 3/4, Tue 3/5) contains only Monday
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1


def test_end_le_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 1)) == 0
