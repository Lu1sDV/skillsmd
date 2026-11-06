"""Tests for orders.update_address, written from SPEC.md.

Run against both store implementations; the SQLite one is a real in-memory
database because the cascade/replace behaviour only exists at that boundary.
"""
import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address

STORES = [InMemoryOrderStore, SqliteOrderStore]


@pytest.fixture(params=STORES, ids=lambda c: c.__name__)
def store(request):
    s = request.param()
    s.add_order(1, "old street 1", ["a", "b", "c"], status="shipped")
    s.add_order(2, "other street 2", ["x"], status="new")
    return s


def test_address_is_changed_and_persisted(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["address"] == "new street 9"


def test_returns_updated_order(store):
    assert update_address(store, 1, "new street 9")["address"] == "new street 9"


def test_status_is_unchanged(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["status"] == "shipped"


def test_items_are_unchanged(store, request):
    if isinstance(store, SqliteOrderStore):
        request.applymarker(pytest.mark.xfail(
            strict=True,
            reason="defect: save_order uses INSERT OR REPLACE, which deletes the "
                   "order row and cascades the delete to its items"))
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["items"] == ["a", "b", "c"]


def test_other_orders_are_untouched(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(2) == {"id": 2, "address": "other street 2",
                                  "status": "new", "items": ["x"]}


def test_unknown_order_raises_key_error(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")


def test_unknown_order_is_not_created(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")
    assert store.get_order(999) is None
