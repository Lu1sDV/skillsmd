/**
 * @name Ruby auth-session two-factor authentication session bypass
 * @description A method looks up a user directly from `session[:otp_user_id]` via
 *              `User.find` or `User.find_by_id` without first verifying the session
 *              value matches the credential submitted in the current request. An
 *              attacker who controls an active session (e.g. via session fixation)
 *              can complete a second factor for a different user. Add an identity
 *              mismatch guard (`clear_two_factor_attempt! if session[:otp_user_id] != user.id`)
 *              before accepting the OTP step, and prefer lookup by submitted login
 *              credentials over an unchecked session value.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision medium
 * @id rb/auth-session-2fa-session-bypass
 * @tags security
 *       external/cwe/cwe-308
 * @vr-id RB-QL-1323
 * @source-citation derived from GitLab security fixes ac6a2224c865, f10c6c7f7798 (2FA total bypass); CWE-308
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `sessionRef` is an element-reference expression of the form
 * `session[:otp_user_id]`.
 * In Ruby, `session` is a method call (no explicit receiver), not a variable.
 */
predicate isOtpSessionRead(ElementReference sessionRef) {
  sessionRef.getReceiver().(MethodCall).getMethodName() = "session" and
  sessionRef.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "otp_user_id"
}

from MethodCall lookup
where
  // Must be User.find(...) or User.find_by_id(...)
  lookup.getMethodName() = ["find", "find_by_id"] and
  lookup.getReceiver().(ConstantReadAccess).getName() = "User" and
  // The first argument (or only argument) is session[:otp_user_id]
  isOtpSessionRead(lookup.getArgument(0))
select lookup,
  "User looked up directly from `session[:otp_user_id]` via " + lookup.getMethodName() +
    " without an identity mismatch guard; an attacker may complete 2FA for a different user. " +
    "Guard with `clear_two_factor_attempt! if session[:otp_user_id] != user.id` and prefer " +
    "lookup by submitted credentials."
