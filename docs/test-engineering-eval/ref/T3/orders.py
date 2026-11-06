"""Order storage and the address-change service."""
import sqlite3

SCHEMA = """
CREATE TABLE IF NOT EXISTS orders (
    id INTEGER PRIMARY KEY, address TEXT NOT NULL, status TEXT NOT NULL);
CREATE TABLE IF NOT EXISTS items (
    order_id INTEGER NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    sku TEXT NOT NULL);
"""


class SqliteOrderStore:
    def __init__(self, path=":memory:"):
        self.conn = sqlite3.connect(path)
        self.conn.execute("PRAGMA foreign_keys = ON")
        self.conn.executescript(SCHEMA)

    def add_order(self, order_id, address, items, status="new"):
        self.conn.execute("INSERT INTO orders (id, address, status) VALUES (?, ?, ?)",
                          (order_id, address, status))
        self.conn.executemany("INSERT INTO items (order_id, sku) VALUES (?, ?)",
                              [(order_id, sku) for sku in items])
        self.conn.commit()

    def get_order(self, order_id):
        row = self.conn.execute("SELECT id, address, status FROM orders WHERE id = ?",
                                (order_id,)).fetchone()
        if row is None:
            return None
        skus = [r[0] for r in self.conn.execute(
            "SELECT sku FROM items WHERE order_id = ? ORDER BY rowid", (order_id,))]
        return {"id": row[0], "address": row[1], "status": row[2], "items": skus}

    def save_order(self, order):
        """Write the address and status of an existing order."""
        self.conn.execute("UPDATE orders SET address = ?, status = ? WHERE id = ?",
                          (order["address"], order["status"], order["id"]))
        self.conn.commit()


class InMemoryOrderStore:
    def __init__(self):
        self._orders = {}

    def add_order(self, order_id, address, items, status="new"):
        self._orders[order_id] = {"id": order_id, "address": address,
                                  "status": status, "items": list(items)}

    def get_order(self, order_id):
        order = self._orders.get(order_id)
        return None if order is None else {**order, "items": list(order["items"])}

    def save_order(self, order):
        self._orders[order["id"]]["address"] = order["address"]
        self._orders[order["id"]]["status"] = order["status"]


def update_address(store, order_id, new_address):
    """Change the shipping address of an existing order.

    Everything else about the order, including its items and status, is left
    unchanged. Raises KeyError for an unknown order. Returns the updated order.
    """
    order = store.get_order(order_id)
    if order is None:
        raise KeyError(order_id)
    order["address"] = new_address
    store.save_order(order)
    return order
