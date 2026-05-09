System.loadLibrary("evil_native");
// Native method executes shellcode — ZERO JVM security checks
native void executeShellcode(byte[] shellcode);
