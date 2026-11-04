import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "a"], status="shipped")
    s.add_order(2, "other street", ["c"])
    return s


def test_address_changed_and_persisted(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_returns_updated_order(store):
    assert update_address(store, 1, "new street") == store.get_order(1)


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


def test_order_without_items(store):
    store.add_order(3, "x", [])
    update_address(store, 3, "y")
    assert store.get_order(3) == {"id": 3, "address": "y", "status": "new", "items": []}


def test_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 99, "nowhere")


def test_unknown_order_creates_nothing(store):
    with pytest.raises(KeyError):
        update_address(store, 99, "nowhere")
    assert store.get_order(99) is None
