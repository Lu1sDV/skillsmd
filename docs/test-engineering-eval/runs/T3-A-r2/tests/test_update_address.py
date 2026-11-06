import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "c"], status="shipped")
    s.add_order(2, "other street", ["x"])
    return s


def test_update_address_existing_order_changes_address(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_update_address_returns_updated_order(store):
    result = update_address(store, 1, "new street")
    assert result == store.get_order(1)
    assert result["address"] == "new street"


def test_update_address_keeps_status(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["status"] == "shipped"


def test_update_address_keeps_items_in_order(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["items"] == ["a", "b", "c"]


def test_update_address_order_without_items_stays_empty(store):
    store.add_order(3, "empty", [])
    update_address(store, 3, "somewhere")
    assert store.get_order(3)["items"] == []
    assert store.get_order(3)["address"] == "somewhere"


def test_update_address_does_not_touch_other_orders(store):
    update_address(store, 1, "new street")
    assert store.get_order(2) == {"id": 2, "address": "other street",
                                  "status": "new", "items": ["x"]}


def test_update_address_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")


def test_update_address_unknown_order_creates_nothing(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")
    assert store.get_order(999) is None


def test_update_address_same_address_is_noop(store):
    before = store.get_order(1)
    update_address(store, 1, "old street")
    assert store.get_order(1) == before


def test_update_address_twice_last_wins(store):
    update_address(store, 1, "first")
    update_address(store, 1, "second")
    assert store.get_order(1)["address"] == "second"
    assert store.get_order(1)["items"] == ["a", "b", "c"]
