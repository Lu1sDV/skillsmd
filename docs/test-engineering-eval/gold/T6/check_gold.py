import pytest
from shipping import shipping_cents as f
@pytest.mark.parametrize("w,e,want",[(1000,False,500),(1001,False,700),(1500,False,700),(1501,False,900),(1001,True,1050)])
def test_gold(w,e,want): assert f(w,e)==want
