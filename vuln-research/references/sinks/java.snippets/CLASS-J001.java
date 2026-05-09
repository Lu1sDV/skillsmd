Field f = Unsafe.class.getDeclaredField("theUnsafe");
f.setAccessible(true);
Unsafe unsafe = (Unsafe) f.get(null);

// Mirror class: same layout as MethodHandles.Lookup but public fields
class LookupMirror {
    Class<?> lookupClass;
    int allowedModes;
}

Lookup originalLookup = MethodHandles.lookup();
// Confuse into LookupMirror — Unsafe.putObject skips type check
unsafe.putObject(holder, offset, originalLookup);
LookupMirror mirror = (LookupMirror) holder.confusable;
mirror.allowedModes = -1; // -1 = TRUSTED: bypass all access checks
// Now use the trusted lookup to access System.security
