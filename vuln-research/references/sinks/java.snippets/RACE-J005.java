// Thread 1: while (buf.hasRemaining()) { process(buf.get()); }
// Thread 2: buf.position(newPos); // race window between remaining() and get()
// CVE-2020-2803 exploited this via Unsafe to achieve out-of-bounds read/write
