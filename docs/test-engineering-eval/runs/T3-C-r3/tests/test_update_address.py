import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address

STORES = [InMemoryOrderStore, SqliteOrderStore]


@pytest.fixture(params=STORES, ids=lambda c: c.__name__)
def store(request):
    s = request.param()
    s.add_order(1, "1 Old St", ["a", "b", "a"], status="shipped")
    s.add_order(2, "2 Other St", ["z"], status="new")
    return s


def test_address_is_changed(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["address"] == "9 New Ave"


def test_returned_order_has_new_address(store):
    assert update_address(store, 1, "9 New Ave")["address"] == "9 New Ave"


def test_status_is_unchanged(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["status"] == "shipped"


# Spec: items are left unchanged. SqliteOrderStore.save_order uses INSERT OR REPLACE,
# which with foreign_keys=ON cascades and deletes the order's items (real defect).
# strict xfail: runs for real; turns red (XPASS) once the defect is fixed.
@pytest.mark.parametrize("store", [
    InMemoryOrderStore,
    pytest.param(SqliteOrderStore, marks=pytest.mark.xfail(
        strict=True, reason="defect: SqliteOrderStore.save_order INSERT OR REPLACE cascade-deletes items")),
], indirect=True, ids=lambda c: c.__name__)
def test_items_are_unchanged(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_returned_order_keeps_items(store):
    assert update_address(store, 1, "9 New Ave")["items"] == ["a", "b", "a"]


def test_other_orders_are_untouched(store):
    update_address(store, 1, "9 New Ave")
    assert store.get_order(2) == {"id": 2, "address": "2 Other St",
                                  "status": "new", "items": ["z"]}


def test_unknown_order_raises_keyerror(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "9 New Ave")


def test_unknown_order_does_not_create_it(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "9 New Ave")
    assert store.get_order(999) is None
