/**
 * @name Ruby auth-session authentication skipped via before_action
 * @description A controller calls `skip_before_action` or `skip_before_filter` with an
 *              authentication callback, removing login enforcement for one or more actions.
 *              An unauthenticated attacker can reach those actions without logging in.
 *              Remove the skip or restrict it to genuinely public endpoints.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/auth-session-authentication-skipped
 * @tags security
 *       external/cwe/cwe-306
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1302
 * @source-citation derived from GitLab auth-session security fixes (skipped authentication); CWE-306
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c
where
  c.getMethodName() = ["skip_before_action", "skip_before_filter"] and
  exists(SymbolLiteral s |
    s = c.getAnArgument() and
    s.getConstantValue().getSymbol() =
      [
        "authenticate_user!", "authenticate", "require_login", "require_user",
        "login_required", "authenticate_request", "authenticate_admin!",
        "ensure_logged_in", "require_authentication"
      ]
  )
select c,
  "Authentication is skipped by this call; remove the skip or scope it to explicitly public actions."
