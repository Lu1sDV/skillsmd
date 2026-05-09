final Object lock = new Object();
final StringBuilder shared = new StringBuilder();

Thread t = new Thread(() -> {
    synchronized(lock) {
        shared.append("A"); // ThreadDeath can fire HERE
        shared.append("B"); // If first append executed but second didn't
    }
});
t.start();
Thread.sleep(1);
t.stop(); // Asynchronous ThreadDeath!
// -> shared may contain "A" without "B" — corrupted state
// -> lock is released even though critical section was interrupted
