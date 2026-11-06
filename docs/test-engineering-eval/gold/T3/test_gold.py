from orders import SqliteOrderStore, update_address
def test_items_survive_in_db():
    s=SqliteOrderStore(); s.add_order(1,"A",["x","y"],status="paid")
    update_address(s,1,"B")
    o=s.get_order(1); assert o["address"]=="B" and o["items"]==["x","y"] and o["status"]=="paid"
