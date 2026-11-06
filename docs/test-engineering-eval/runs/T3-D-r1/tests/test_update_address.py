import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "c"], status="shipped")
    s.add_order(2, "other street", ["x"])
    return s


def test_address_changed_and_persisted(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_returns_updated_order(store):
    assert update_address(store, 1, "new street")["address"] == "new street"


def test_items_unchanged(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["items"] == ["a", "b", "c"]


def test_status_unchanged(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["status"] == "shipped"


def test_other_orders_untouched(store):
    update_address(store, 1, "new street")
    assert store.get_order(2) == {"id": 2, "address": "other street",
                                  "status": "new", "items": ["x"]}


def test_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "new street")


def test_unknown_order_creates_nothing(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "new street")
    assert store.get_order(999) is None


def test_order_without_items(store):
    store.add_order(3, "empty", [])
    update_address(store, 3, "moved")
    assert store.get_order(3)["items"] == []
    assert store.get_order(3)["address"] == "moved"
