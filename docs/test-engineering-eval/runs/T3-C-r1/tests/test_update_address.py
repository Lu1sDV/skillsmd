import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address

STORES = [InMemoryOrderStore, SqliteOrderStore]
# Spec: update_address leaves items unchanged. SqliteOrderStore.save_order uses
# INSERT OR REPLACE, which deletes the order row and cascades to its items.
SQLITE_ITEMS_BUG = pytest.mark.xfail(
    strict=True, reason="defect: SqliteOrderStore.save_order INSERT OR REPLACE cascades delete of items"
)


@pytest.fixture(params=STORES, ids=lambda c: c.__name__)
def store(request):
    s = request.param()
    s.add_order(1, "1 Old St", ["a", "b", "a"], status="shipped")
    s.add_order(2, "2 Other St", ["c"])
    return s


def test_new_address_is_persisted(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["address"] == "9 New Ave"


def test_returned_order_has_new_address(store):
    assert update_address(store, 1, "9 New Ave")["address"] == "9 New Ave"


def test_status_unchanged(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["status"] == "shipped"


def test_items_unchanged(request, store):
    if isinstance(store, SqliteOrderStore):
        request.applymarker(SQLITE_ITEMS_BUG)
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_other_orders_unchanged(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(2) == {"id": 2, "address": "2 Other St", "status": "new", "items": ["c"]}


def test_unknown_order_raises_keyerror_and_changes_nothing(store):
    with pytest.raises(KeyError):
        update_address(store, 99, "9 New Ave")
    assert store.get_order(99) is None
    assert store.get_order(1)["address"] == "1 Old St"


def test_same_address_is_a_noop(store):
    update_address(store, 2, "2 Other St")
    assert store.get_order(2)["address"] == "2 Other St"
    assert store.get_order(2)["status"] == "new"


def test_order_without_items_gets_new_address(store):
    store.add_order(3, "3 Empty St", [])
    update_address(store, 3, "x")
    assert store.get_order(3) == {"id": 3, "address": "x", "status": "new", "items": []}
