import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "a"], status="shipped")
    s.add_order(2, "other street", ["z"])
    return s


def test_address_changes(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_returns_updated_order(store):
    result = update_address(store, 1, "new street")
    assert result == store.get_order(1)


def test_items_unchanged(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_status_unchanged(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["status"] == "shipped"


def test_other_orders_untouched(store):
    before = store.get_order(2)
    update_address(store, 1, "new street")
    assert store.get_order(2) == before


def test_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "x")


def test_unknown_order_does_not_create_it(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "x")
    assert store.get_order(999) is None


def test_order_without_items(store):
    store.add_order(3, "addr", [])
    update_address(store, 3, "new")
    assert store.get_order(3) == {"id": 3, "address": "new", "status": "new", "items": []}


def test_repeated_updates(store):
    update_address(store, 1, "one")
    update_address(store, 1, "two")
    order = store.get_order(1)
    assert order["address"] == "two" and order["items"] == ["a", "b", "a"]
