URL.setURLStreamHandlerFactory(protocol -> new URLStreamHandler() {
    @Override protected URLConnection openConnection(URL u) {
        return new URLConnection(u) {
            @Override public void connect() { /* attacker handler */ }
        };
    }
});
