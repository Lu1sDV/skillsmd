from shipping import shipping_cents


def test_light_parcel():
    assert shipping_cents(500) == 500
