// Module A: opens harmless.pkg to attacker;
// Attacker defines class in harmless.pkg via Lookup.defineClass()
// That class calls MethodHandles.lookup() → private lookup with
// full access to ALL victim module packages (including closed ones)
MethodHandles.Lookup privateLookup =
    MethodHandles.privateLookupIn(victimSecretClass, injectedLookup);
