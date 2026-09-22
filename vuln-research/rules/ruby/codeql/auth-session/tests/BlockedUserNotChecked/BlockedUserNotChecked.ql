/**
 * @name Ruby auth-session blocked user not checked after lookup
 * @description A method looks up a user via an authentication-flow finder
 *              (`with_reset_password_token`, `find_by_reset_password_token`, or
 *              `find_by_login`) but never calls `.blocked?` in the same method.
 *              A banned or deactivated user can therefore reset credentials or
 *              sign in. Add a `return ... if user.blocked?` guard before any
 *              downstream authentication or password-reset action.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/auth-session-blocked-user-not-checked
 * @tags security
 *       external/cwe/cwe-287
 * @vr-id RB-QL-1305
 * @source-citation derived from GitLab auth-session blocked-user-bypass fixes (shas 3d678147a801,7ccb4a840b11,ac8c5c37d035); CWE-287
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall finder
where
  // Auth-flow finders that return a User and precede a sensitive action
  finder.getMethodName() =
    ["with_reset_password_token", "find_by_reset_password_token", "find_by_login"] and
  // Receiver must be the User constant (not an arbitrary model)
  finder.getReceiver().(ConstantReadAccess).getName() = "User" and
  // No `blocked?` call exists anywhere in the same enclosing method/callable
  not exists(MethodCall guard |
    guard.getMethodName() = "blocked?" and
    guard.getEnclosingCallable() = finder.getEnclosingCallable()
  )
select finder,
  "User looked up for authentication via " + finder.getMethodName() +
    " without a `blocked?` check in this method; blocked users may authenticate or reset credentials."
