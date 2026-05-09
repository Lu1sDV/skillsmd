// RMI registry filter allows RemoteObject → RemoteObjectInvocationHandler
// → UnicastRef.invoke() → outgoing JRMP to attacker
// → attacker responds with CommonsCollections → UNFILTERED readObject()
