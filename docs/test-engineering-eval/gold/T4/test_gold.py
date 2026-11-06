from datetime import date
from bizdays import business_days_between as f
def test_fri_to_mon(): assert f(date(2024,3,1),date(2024,3,4))==1
