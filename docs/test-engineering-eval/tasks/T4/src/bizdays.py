"""Business-day arithmetic."""
from datetime import date, timedelta


def business_days_between(start: date, end: date) -> int:
    """Number of business days (Monday to Friday) in [start, end).

    start is included, end is excluded. Returns 0 when end <= start.
    """
    if end <= start:
        return 0
    count = 0
    day = start
    while day <= end:
        if day.weekday() < 5:
            count += 1
        day += timedelta(days=1)
    return count
