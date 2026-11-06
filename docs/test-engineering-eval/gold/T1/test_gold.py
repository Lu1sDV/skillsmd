import pytest
from pricing import order_total_cents as f
@pytest.mark.parametrize("q,p,want",[(9,100,900),(10,100,950),(49,100,4655),(50,100,4500),(1,1,1),(10,5,48)])
def test_tiers(q,p,want): assert f(q,p)==want
def test_invalid():
    with pytest.raises(ValueError): f(0,1)
