/**
 * @name Passkey/WebAuthn authentication proceeds without checking if passkeys are allowed for the user
 * @description A WebAuthn or passkey authentication service verifies the cryptographic assertion
 *              (`verify_passkey` / `verify_webauthn`) but never calls `allow_passkey_authentication?`
 *              to confirm passkeys are permitted for this user. An attacker authenticates with a
 *              passkey on an account whose organization has disabled passkey/password authentication.
 *              Fix: add `raise WebAuthn::Error unless user.allow_passkey_authentication?` immediately
 *              after credential verification.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/auth-session-passkey-authentication-policy-bypass
 * @tags security
 *       external/cwe/cwe-287
 * @vr-id RB-QL-1332
 * @source-citation derived from GitLab security fixes 6497646e9ac2 and 02cb0dce5b50 (passkey auth bypass for SSO-restricted accounts); CWE-287
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall verify
where
  // Target: methods that perform WebAuthn/passkey cryptographic assertion verification
  verify.getMethodName() = ["verify_passkey", "verify_webauthn"] and
  // No `allow_passkey_authentication?` policy check exists anywhere in the same callable
  not exists(MethodCall guard |
    guard.getMethodName() = "allow_passkey_authentication?" and
    guard.getEnclosingCallable() = verify.getEnclosingCallable()
  )
select verify,
  "WebAuthn/passkey verification via `" + verify.getMethodName() +
    "` is performed without checking `allow_passkey_authentication?`; users whose organization " +
    "has disabled passkey authentication may still authenticate. Add " +
    "`raise WebAuthn::Error unless user.allow_passkey_authentication?` after verification."
