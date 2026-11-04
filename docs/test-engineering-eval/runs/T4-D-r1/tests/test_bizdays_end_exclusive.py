from datetime import date

from bizdays import business_days_between


def test_friday_to_following_monday_counts_only_friday():
    # Bug report: returned 2 (end date Monday wrongly included).
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


def test_end_is_excluded():
    # Mon -> Tue: only Monday counts.
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 5)) == 1
