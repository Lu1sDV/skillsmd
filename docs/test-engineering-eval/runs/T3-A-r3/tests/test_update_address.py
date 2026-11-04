import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "a"], status="shipped")
    s.add_order(2, "other street", ["c"])
    return s


def test_update_address_existing_order_changes_address(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_update_address_existing_order_returns_updated_order(store):
    assert update_address(store, 1, "new street") == store.get_order(1)


def test_update_address_existing_order_keeps_status(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["status"] == "shipped"


def test_update_address_existing_order_keeps_items(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_update_address_existing_order_leaves_other_orders_untouched(store):
    update_address(store, 1, "new street")
    assert store.get_order(2) == {"id": 2, "address": "other street",
                                  "status": "new", "items": ["c"]}


def test_update_address_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "x")


def test_update_address_unknown_order_creates_nothing(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "x")
    assert store.get_order(999) is None


def test_update_address_same_address_is_noop(store):
    before = store.get_order(1)
    update_address(store, 1, "old street")
    assert store.get_order(1) == before


def test_update_address_twice_keeps_last_address_and_items(store):
    update_address(store, 1, "first")
    update_address(store, 1, "second")
    order = store.get_order(1)
    assert (order["address"], order["items"]) == ("second", ["a", "b", "a"])
