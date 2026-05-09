// Kryo reads any class — not just Serializable
// Private constructors invoked via reflection
// finalize() triggered on GC — attacker controls all fields
