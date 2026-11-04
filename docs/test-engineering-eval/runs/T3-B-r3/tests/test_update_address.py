import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    return request.param()


def test_update_address_existing_order_changes_address(store):
    store.add_order(1, "old st", ["a"])
    update_address(store, 1, "new st")
    assert store.get_order(1)["address"] == "new st"


def test_update_address_returns_updated_order(store):
    store.add_order(1, "old st", ["a", "b"], status="paid")
    assert update_address(store, 1, "new st") == {
        "id": 1, "address": "new st", "status": "paid", "items": ["a", "b"]}


def test_update_address_keeps_items_in_store(store):
    store.add_order(1, "old st", ["a", "b", "a"])
    update_address(store, 1, "new st")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


@pytest.mark.parametrize("status", ["new", "paid", "shipped"])
def test_update_address_keeps_status(store, status):
    store.add_order(1, "old st", ["a"], status=status)
    update_address(store, 1, "new st")
    assert store.get_order(1)["status"] == status


def test_update_address_order_without_items_still_updates(store):
    store.add_order(1, "old st", [])
    update_address(store, 1, "new st")
    assert store.get_order(1) == {"id": 1, "address": "new st", "status": "new", "items": []}


def test_update_address_only_affects_target_order(store):
    store.add_order(1, "one", ["a"])
    store.add_order(2, "two", ["b"])
    update_address(store, 1, "new st")
    assert store.get_order(2) == {"id": 2, "address": "two", "status": "new", "items": ["b"]}


def test_update_address_same_address_is_noop(store):
    store.add_order(1, "old st", ["a"])
    update_address(store, 1, "old st")
    assert store.get_order(1) == {"id": 1, "address": "old st", "status": "new", "items": ["a"]}


def test_update_address_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "new st")


def test_update_address_unknown_order_does_not_create_order(store):
    store.add_order(1, "old st", ["a"])
    with pytest.raises(KeyError):
        update_address(store, 2, "new st")
    assert store.get_order(2) is None
