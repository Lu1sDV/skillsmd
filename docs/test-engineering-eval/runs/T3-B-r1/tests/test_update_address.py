import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    s = request.param()
    s.add_order(1, "old street 1", ["a", "b", "c"], status="shipped")
    s.add_order(2, "other street 2", ["x"], status="new")
    return s


def test_update_address_existingOrder_changesAddress(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["address"] == "new street 9"


def test_update_address_existingOrder_returnsUpdatedOrder(store):
    result = update_address(store, 1, "new street 9")
    assert result == store.get_order(1)


def test_update_address_existingOrder_keepsItems(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["items"] == ["a", "b", "c"]


def test_update_address_existingOrder_keepsStatus(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(1)["status"] == "shipped"


def test_update_address_orderWithoutItems_changesAddress(store):
    store.add_order(3, "empty street", [])
    update_address(store, 3, "new street 9")
    assert store.get_order(3) == {"id": 3, "address": "new street 9",
                                  "status": "new", "items": []}


def test_update_address_otherOrder_isUntouched(store):
    update_address(store, 1, "new street 9")
    assert store.get_order(2) == {"id": 2, "address": "other street 2",
                                  "status": "new", "items": ["x"]}


def test_update_address_sameAddress_leavesOrderUnchanged(store):
    before = store.get_order(1)
    update_address(store, 1, "old street 1")
    assert store.get_order(1) == before


def test_update_address_calledTwice_lastAddressWins(store):
    update_address(store, 1, "first")
    update_address(store, 1, "second")
    order = store.get_order(1)
    assert order["address"] == "second"
    assert order["items"] == ["a", "b", "c"]


def test_update_address_unknownOrder_raisesKeyError(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")


def test_update_address_unknownOrder_doesNotCreateOrder(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")
    assert store.get_order(999) is None
