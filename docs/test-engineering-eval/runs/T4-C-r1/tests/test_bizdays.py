from datetime import date

import pytest

from bizdays import business_days_between

# Bug: end date is counted (range treated as closed). Spec says [start, end).
# strict xfail: turns red (XPASS) once src is fixed, prompting removal of the marker.
_BUG = pytest.mark.xfail(strict=True, reason="end date wrongly included; SPEC says [start, end)")


@_BUG
def test_friday_to_following_monday_counts_only_friday():
    # Fri 2024-03-01 included; Sat, Sun weekend; Mon 2024-03-04 excluded -> 1
    assert business_days_between(date(2024, 3, 1), date(2024, 3, 4)) == 1


@_BUG
def test_end_on_weekday_is_excluded():
    # Mon 2024-03-04 .. Fri 2024-03-08 excluded -> Mon, Tue, Wed, Thu = 4
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 8)) == 4


def test_end_not_after_start_returns_zero():
    assert business_days_between(date(2024, 3, 4), date(2024, 3, 4)) == 0
    assert business_days_between(date(2024, 3, 5), date(2024, 3, 4)) == 0
