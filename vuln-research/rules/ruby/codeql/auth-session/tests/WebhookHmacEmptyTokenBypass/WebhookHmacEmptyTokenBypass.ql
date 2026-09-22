/**
 * @name Webhook HMAC verification missing empty-token guard
 * @description A webhook signature verification method computes an HMAC digest
 *              from a secret token without first checking whether the token is
 *              blank or nil. When the token is empty, HMAC('') is deterministic
 *              and trivially forgeable by any caller. Add a
 *              `return false if token.blank?` (or `.empty?`) guard before the
 *              HMAC computation.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.1
 * @precision high
 * @id rb/auth-session-webhook-hmac-empty-token-bypass
 * @tags security
 *       external/cwe/cwe-287
 * @vr-id RB-QL-1333
 * @source-citation derived from GitLab security fix 0dbce3f1a8d1 (external webhook token blank-check bypass); CWE-287
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A method call that computes an HMAC digest.
 * Matches: OpenSSL::HMAC.hexdigest(...), OpenSSL::HMAC.digest(...),
 *          HMAC.hexdigest(...), HMAC.digest(...)
 */
predicate isHmacCall(MethodCall c) {
  c.getMethodName() = ["hexdigest", "digest"] and
  // Receiver is a constant named HMAC (bare or namespace-qualified via getScopeExpr)
  c.getReceiver().(ConstantReadAccess).getName() = "HMAC"
}

/**
 * A call that checks whether a value is blank or empty.
 * Matches: token.blank?, token.empty?, token.nil?
 */
predicate isBlankOrEmptyGuard(MethodCall guard) {
  guard.getMethodName() = ["blank?", "empty?", "nil?", "present?"]
}

from MethodCall hmac
where
  isHmacCall(hmac) and
  // No blank/empty guard exists in the same enclosing callable
  not exists(MethodCall guard |
    isBlankOrEmptyGuard(guard) and
    guard.getEnclosingCallable() = hmac.getEnclosingCallable()
  )
select hmac,
  "HMAC digest computed without a prior blank/empty check on the secret token; " +
  "an empty token makes the signature trivially forgeable. Add `return false if token.blank?` before this call."
