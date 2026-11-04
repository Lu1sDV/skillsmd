import pytest

from orders import InMemoryOrderStore, SqliteOrderStore, update_address


@pytest.fixture(params=[InMemoryOrderStore, SqliteOrderStore], ids=["memory", "sqlite"])
def store(request):
    s = request.param()
    s.add_order(1, "old street", ["a", "b", "a"], status="shipped")
    s.add_order(2, "other street", ["c"])
    return s


def test_update_address_existingOrder_changesAddress(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["address"] == "new street"


def test_update_address_existingOrder_returnsUpdatedOrder(store):
    assert update_address(store, 1, "new street") == store.get_order(1)


def test_update_address_existingOrder_preservesItems(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["items"] == ["a", "b", "a"]


def test_update_address_existingOrder_preservesStatus(store):
    update_address(store, 1, "new street")
    assert store.get_order(1)["status"] == "shipped"


def test_update_address_existingOrder_leavesOtherOrdersUntouched(store):
    update_address(store, 1, "new street")
    assert store.get_order(2) == {"id": 2, "address": "other street",
                                  "status": "new", "items": ["c"]}


def test_update_address_orderWithNoItems_staysEmptyAndUpdates(store):
    store.add_order(3, "x", [])
    update_address(store, 3, "y")
    assert store.get_order(3) == {"id": 3, "address": "y", "status": "new", "items": []}


def test_update_address_sameAddress_isNoOp(store):
    before = store.get_order(1)
    update_address(store, 1, "old street")
    assert store.get_order(1) == before


def test_update_address_calledTwice_lastAddressWins(store):
    update_address(store, 1, "first")
    update_address(store, 1, "second")
    order = store.get_order(1)
    assert order["address"] == "second"
    assert order["items"] == ["a", "b", "a"]


def test_update_address_unknownOrder_raisesKeyError(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")


def test_update_address_unknownOrder_doesNotCreateOrder(store):
    with pytest.raises(KeyError):
        update_address(store, 999, "nowhere")
    assert store.get_order(999) is None
