/**
 * @name Timing-unsafe comparison of OAuth secret, token, or HMAC signature
 * @description An OAuth application secret, API token, or HMAC signature is compared
 *              using Ruby's `==` or `!=` operator rather than a constant-time function
 *              (`ActiveSupport::SecurityUtils.secure_compare` /
 *              `Rack::Utils.secure_compare`). A timing side-channel may allow an attacker
 *              to recover the secret one byte at a time. Replace `==` with
 *              `ActiveSupport::SecurityUtils.secure_compare` or
 *              `Rack::Utils.secure_compare`.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.4
 * @precision medium
 * @id rb/auth-session-timing-unsafe-token-compare
 * @tags security
 *       external/cwe/cwe-208
 * @vr-id RB-QL-1317
 * @source-citation derived from GitLab security fix 1a0f40d1c059 (oauth application secret_matches? using == instead of secure_compare); CWE-208
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `name` looks like a method that validates a credential via comparison.
 * These names are drawn from the real GitLab fixes and common Rails/Doorkeeper patterns.
 */
predicate isCredentialComparatorMethod(string name) {
  name =
    [
      "secret_matches?", "valid_token?", "token_valid?", "authenticate?",
      "verify_signature?", "signature_valid?", "hmac_valid?", "check_token?",
      "token_matches?", "verify_token?", "compare_token?", "valid_secret?",
      "secret_valid?", "password_matches?"
    ]
}

/**
 * Holds if `e` is an expression whose name looks like a secret, token, or HMAC value.
 * Checks local variable reads and zero-arg method calls by name.
 */
predicate isCredentialExpr(Expr e) {
  exists(string n |
    (
      n = e.(LocalVariableReadAccess).getVariable().getName() or
      n = e.(MethodCall).getMethodName()
    ) and
    (
      n.matches("%secret%") or
      n.matches("%token%") or
      n.matches("%signature%") or
      n.matches("%hmac%") or
      n.matches("%digest%") or
      n.matches("%api_key%") or
      n.matches("%auth_key%")
    )
  )
}

from MethodCall eq
where
  // `==` or `!=` operator call
  eq.getMethodName() = ["==", "!="] and
  // Either the receiver or the first argument looks like a credential
  (isCredentialExpr(eq.getReceiver()) or isCredentialExpr(eq.getArgument(0))) and
  // The enclosing method must be a credential-comparison helper
  isCredentialComparatorMethod(eq.getEnclosingCallable().(Method).getName())
select eq,
  "Credential comparison using `" + eq.getMethodName() +
    "` is vulnerable to timing attacks; use ActiveSupport::SecurityUtils.secure_compare or Rack::Utils.secure_compare instead."
