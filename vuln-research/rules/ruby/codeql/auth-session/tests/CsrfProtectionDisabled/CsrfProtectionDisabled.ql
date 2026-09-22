/**
 * @name Ruby auth-session CSRF protection disabled or weakened
 * @description Disabling or neutering Rails cross-site request forgery (CSRF)
 *              defenses lets an attacker forge authenticated state-changing
 *              requests on behalf of a logged-in victim. Keep
 *              `protect_from_forgery with: :exception` enabled and do not skip
 *              `verify_authenticity_token` on state-changing controllers.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/auth-session-csrf-protection-disabled
 * @tags security
 *       external/cwe/cwe-352
 * @vr-id RB-QL-1301
 * @source-citation derived from GitLab auth-session CSRF security fixes; CWE-352
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c, string msg
where
  // 1. skip_before_action :verify_authenticity_token (+ legacy skip_before_filter)
  (
    c.getMethodName() = ["skip_before_action", "skip_before_filter"] and
    exists(SymbolLiteral s |
      s = c.getAnArgument() and s.getConstantValue().getSymbol() = "verify_authenticity_token"
    ) and
    msg = "CSRF protection is disabled by skipping verify_authenticity_token; remove the skip on state-changing controllers."
  )
  or
  // 2. skip_forgery_protection (any call disables CSRF for the controller)
  (
    c.getMethodName() = "skip_forgery_protection" and
    msg = "CSRF protection is disabled by skip_forgery_protection; remove it or scope it tightly to safe actions."
  )
  or
  // 3. protect_from_forgery with: :null_session (silently drops the session instead of rejecting)
  (
    c.getMethodName() = "protect_from_forgery" and
    exists(SymbolLiteral s |
      s = c.getKeywordArgument("with") and s.getConstantValue().getSymbol() = "null_session"
    ) and
    msg = "CSRF protection is weakened by protect_from_forgery with: :null_session; use with: :exception to reject forged requests."
  )
select c, msg
