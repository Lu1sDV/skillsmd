/**
 * @name Expired SSH key or deploy token accepted without expiry check
 * @description A credential lookup (SSH key or deploy token) returns a result
 *              and the credential is used for authentication without calling
 *              `expired?` on it first. An attacker with a leaked but expired
 *              credential can authenticate indefinitely. Add an
 *              `not_found! if key.expired?` (or equivalent) guard immediately
 *              after the nil check, before presenting or using the credential.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/auth-session-expired-ssh-key-or-token-accepted
 * @tags security
 *       external/cwe/cwe-613
 * @vr-id RB-QL-1328
 * @source-citation derived from GitLab security fix 5983d82308fd (Reject expired keys and blocked users); CWE-613
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A method call that looks up a credential (SSH key or deploy token) by a
 * unique token/fingerprint. These are the canonical finders used before
 * presenting or authenticating with the credential.
 */
predicate isCredentialLookup(MethodCall lookup) {
  lookup.getMethodName() =
    [
      "find_by_fingerprint_sha256", "find_by_token", "find_by_fingerprint",
      "find_by_hashed_token", "find_by_secret_token"
    ]
}

from MethodCall lookup
where
  isCredentialLookup(lookup) and
  // No `expired?` call anywhere in the same enclosing method/callable
  not exists(MethodCall guard |
    guard.getMethodName() = "expired?" and
    guard.getEnclosingCallable() = lookup.getEnclosingCallable()
  )
select lookup,
  "Credential looked up via `" + lookup.getMethodName() +
    "` without an `expired?` check in this method; expired credentials may authenticate successfully."
