class Helper {
    private int value;
    public Helper() { this.value = computeExpensive(); } // JIT can reorder!
}

private static Helper instance; // MUST be volatile for DCL to work
public static Helper getInstance() {
    if (instance == null) {          // Thread 2 sees instance != null
        synchronized (Helper.class) {
            if (instance == null) {
                instance = new Helper(); // JIT: 1) alloc memory 2) write pointer (before ctor!)
            }
        }
    }
    return instance; // Thread 2 accesses uninitialized object
}
