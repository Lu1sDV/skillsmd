Expression expr = new Expression(
    Runtime.getRuntime().getClass(), "exec", new Object[]{"calc"});
expr.execute(); // Executes Runtime.getRuntime().exec("calc")

// Constructor invocation via method name "new"
Expression expr2 = new Expression(
    Class.forName("java.lang.ProcessBuilder"), "new",
    new Object[]{new String[]{"/bin/sh", "-c", "id"}});
ProcessBuilder pb = (ProcessBuilder) expr2.getValue();
pb.start();
