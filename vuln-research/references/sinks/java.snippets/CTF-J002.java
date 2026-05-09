class MyClassLoader extends ClassLoader {
    public static void doWork(ClassLoader cl) throws Throwable {
        byte[] buf = /* DisableSec.class bytes */;
        new MyClassLoader().defineClass("DisableSec", buf, 0, buf.length);
    }
}
