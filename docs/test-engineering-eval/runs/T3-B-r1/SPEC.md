# orders
`update_address(store, order_id, new_address)` changes the shipping address of an existing order. Everything else about the order, including its items and status, is left unchanged. An unknown order raises KeyError. Both `SqliteOrderStore` and `InMemoryOrderStore` implement the store interface.
