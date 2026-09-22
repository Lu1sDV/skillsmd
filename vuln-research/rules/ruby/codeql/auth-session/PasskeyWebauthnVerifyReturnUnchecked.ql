/**
 * @name Passkey / WebAuthn verification return value unchecked
 * @description `verify_passkey(...)` or `verify_webauthn(...)` is called as a bare
 *              statement so its boolean return value is silently discarded. If the
 *              underlying WebAuthn library returns `false` on failure instead of raising,
 *              the authentication service continues and grants access without valid credentials.
 *              Fix: `raise WebAuthn::Error unless verify_passkey(...)`.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.1
 * @precision high
 * @id rb/auth-session-passkey-webauthn-verify-return-unchecked
 * @tags security
 *       external/cwe/cwe-252
 * @vr-id RB-QL-1320
 * @source-citation derived from GitLab security fix f3002eb83cfc (Prevent bypass 2FA with WebAuthn & passkey authentication); CWE-252
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c
where
  // Target: WebAuthn/passkey verification methods whose boolean return signals success/failure.
  c.getMethodName() = ["verify_passkey", "verify_webauthn"] and
  // The call is used as a bare statement — its return value is discarded.
  // A MethodCall whose value is consumed (conditional, assignment, argument) will NOT
  // be a direct child statement of any StmtSequence.
  exists(StmtSequence seq | seq.getAStmt() = c)
select c,
  "Return value of `" + c.getMethodName() +
    "` is not checked; if the WebAuthn library returns false on failure rather than raising, " +
    "authentication continues. Use `raise WebAuthn::Error unless " + c.getMethodName() + "(...)`."
