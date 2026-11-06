from datetime import date

from bizdays import business_days_between


def test_business_days_between_friday_to_monday_counts_only_friday():
    # Bug report: [Fri 2024-03-01, Mon 2024-03-04) contains only Friday; end excluded.
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_business_days_between_end_on_weekday_is_excluded():
    # Mon..Fri, end is Fri (excluded): Mon-Thu = 4
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 8)) == 4


def test_business_days_between_end_not_after_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
    assert business_days_between(date(2024, 3, 5), date(2024, 3, 4)) == 0
