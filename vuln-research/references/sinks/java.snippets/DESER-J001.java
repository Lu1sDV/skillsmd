// sun.rmi.server.UnicastRef implements Externalizable
// readExternal() → LiveRef.read() → DGCClient registration → outgoing JRMP
// Attacker's JRMPListener responds with CommonsCollections → RCE
