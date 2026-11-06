import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    s = request.param()
    s.add_order(1, "old street 1", ["a", "b", "a"], status="shipped")
    s.add_order(2, "other street 2", ["c"])
    return s


def test_update_address_existing_order_changes_address(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["address"] == "new street 9"


def test_update_address_existing_order_returns_updated_order(store):
    result = update_address(store, 1, "new street 9")
    assert result == store.get_order(1)
    assert result["address"] == "new street 9"


def test_update_address_existing_order_keeps_status(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["status"] == "shipped"


def test_update_address_existing_order_keeps_items(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_update_address_order_without_items_stays_empty(store):
    store.add_order(3, "x", [])
    update_address(store, 3, "y")
    assert store.get_order(3) == {"id": 3, "address": "y", "status": "new", "items": []}


def test_update_address_existing_order_leaves_other_orders_untouched(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(2) == {"id": 2, "address": "other street 2",
                                  "status": "new", "items": ["c"]}


def test_update_address_same_address_is_noop(store):
    update_address(store, 1, "old street 1")
    assert store.get_order(1) == {"id": 1, "address": "old street 1",
                                  "status": "shipped", "items": ["a", "b", "a"]}


def test_update_address_called_twice_keeps_last_address_and_items(store):
    update_address(store, 1, "first")
    update_address(store, 1, "second")
    order = store.get_order(1)
    assert order["address"] == "second"
    assert order["items"] == ["a", "b", "a"]


def test_update_address_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")


def test_update_address_unknown_order_does_not_create_order(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")
    assert store.get_order(999) is None
