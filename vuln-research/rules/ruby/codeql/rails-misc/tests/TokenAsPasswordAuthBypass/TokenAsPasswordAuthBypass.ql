/**
 * @name Token accepted as LDAP/database password (authentication bypass)
 * @description An authentication method performs a password-based credential check
 *              (LDAP bind or database lookup via `find_with_user_password`) without
 *              first short-circuiting when the supplied password is a personal-access
 *              token or CI token. An attacker whose token is leaked can authenticate
 *              via the LDAP or database path even after the token is revoked. Fix by
 *              adding `return if <token_checker>.token?(password)` before the password
 *              check.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.1
 * @precision high
 * @id rb/rails-misc-token-as-password-auth-bypass
 * @tags security
 *       external/cwe/cwe-287
 *       external/cwe/cwe-303
 * @vr-id RB-QL-2522
 * @source-citation derived from GitLab security fix 11ff5c38 (remove prevent_token_prefixed_password_fallback_sessionless FF); CWE-287, CWE-303
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall pwCheck
where
  // Password-based authentication sink: find_with_user_password performs LDAP+DB auth
  pwCheck.getMethodName() = ["find_with_user_password", "login"] and
  // Only flag `login` when called on an LDAP or Database Authentication object
  (
    pwCheck.getMethodName() = "find_with_user_password"
    or
    pwCheck.getMethodName() = "login" and
    exists(MethodCall recv |
      recv = pwCheck.getReceiver() and
      recv.getMethodName() = ["new", "initialize"] and
      recv.getReceiver().(ConstantReadAccess).getName() =
        ["Authentication", "LdapAuthentication", "DatabaseAuthentication"]
    )
  ) and
  // No token? guard exists anywhere in the same enclosing callable
  not exists(MethodCall guard |
    guard.getMethodName() = "token?" and
    guard.getEnclosingCallable() = pwCheck.getEnclosingCallable()
  )
select pwCheck,
  "Password-based authentication via `" + pwCheck.getMethodName() +
    "` is attempted without first checking whether the password is a token " +
    "(e.g. `return if AgnosticTokenIdentifier.token?(password)`). " +
    "A leaked or revoked personal-access token may authenticate via LDAP or the database."
