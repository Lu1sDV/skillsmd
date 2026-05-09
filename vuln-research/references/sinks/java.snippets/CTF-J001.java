Field unsafeField = Unsafe.class.getDeclaredField("theUnsafe");
unsafeField.setAccessible(true);
Unsafe unsafe = (Unsafe) unsafeField.get(null);
Object systemBase = unsafe.staticFieldBase(System.class);
for (int i = 0; ; i += 4) {
    if (unsafe.getObjectVolatile(systemBase, i) == System.getSecurityManager()) {
        unsafe.putObjectVolatile(systemBase, i, null); // Disabled!
        break;
    }
}
