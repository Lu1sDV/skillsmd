public class SensitiveOperation {
    public SensitiveOperation() {
        SecurityManager sm = System.getSecurityManager();
        if (sm != null) sm.checkPermission(new FilePermission("/etc/passwd", "read"));
        // If we throw SecurityException here, finalize() still runs on partial object
    }
    @Override protected void finalize() throws Throwable {
        // This runs even if constructor threw SecurityException!
        new FileInputStream("/etc/passwd"); // Bypasses security check
        super.finalize();
    }
}
// Attacker partially constructs → GC triggers finalize → data exfil
