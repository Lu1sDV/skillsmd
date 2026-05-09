int cores = Runtime.getRuntime().availableProcessors();
ExecutorService executor = Executors.newVirtualThreadPerTaskExecutor();
Phaser phaser = new Phaser(cores * 2);
for (int i = 0; i < cores * 2; i++) {
    final Object lock = new Object();
    executor.submit(() -> {
        synchronized (lock) {
            phaser.arriveAndAwaitAdvance(); // parked while pinned!
        }
    });
}
// SILENT DEADLOCK: all carriers pinned, no thread can proceed
// ThreadMXBean.findDeadlockedThreads() returns null!
