Set<URL> allowed = new HashSet<>();
allowed.add(new URL("http://intranet.corp/"));
// URL.equals() triggers DNS resolution!
if (allowed.contains(new URL("http://evil.com/"))) { // true if same IP
    openConnection(new URL("http://evil.com/")); // connects to attacker
}
