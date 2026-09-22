/**
 * @name OAuth authorization request built without PKCE code_challenge (RFC 7636)
 * @description An OAuth authorization URL is constructed via `auth_code.authorize_url(...)`
 *              without a `code_challenge:` parameter, leaving the flow vulnerable to
 *              authorization-code interception attacks. Generate a PKCE pair
 *              (SecureRandom + SHA-256), include `code_challenge:` and
 *              `code_challenge_method: "S256"` in the authorization URL, and pass
 *              `code_verifier:` at the token-exchange step.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.9
 * @precision high
 * @id rb/auth-session-oauth-pkce-missing-code-challenge
 * @tags security
 *       external/cwe/cwe-287
 * @vr-id RB-QL-1331
 * @source-citation derived from GitLab security fix 0cfa8a6c944b (Improve MCP OAuth: PKCE support); CWE-287
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `authCodeCall` is a call to `auth_code` whose result is the
 * receiver of `authorizeUrl`.
 * Matches both:
 *   some_client.auth_code.authorize_url(...)     -- chained directly
 *   ac = something.auth_code; ac.authorize_url(...)  -- via local variable
 *
 * We simply require that the *direct* receiver of `authorize_url` is itself
 * a `MethodCall` named `auth_code`, which covers the common chained form.
 * For robustness we also allow the receiver to be a variable whose only
 * simple assignment RHS is an `auth_code` call.
 */
predicate isAuthCodeAuthorizeUrl(MethodCall c) {
  c.getMethodName() = "authorize_url" and
  (
    // Direct chain: something.auth_code.authorize_url(...)
    c.getReceiver().(MethodCall).getMethodName() = "auth_code"
    or
    // Variable indirection: ac = x.auth_code; ac.authorize_url(...)
    exists(LocalVariableReadAccess lv, AssignExpr ae |
      lv = c.getReceiver() and
      ae.getLeftOperand().(LocalVariableWriteAccess).getVariable() = lv.getVariable() and
      ae.getRightOperand().(MethodCall).getMethodName() = "auth_code"
    )
  )
}

from MethodCall c
where
  isAuthCodeAuthorizeUrl(c) and
  // No code_challenge keyword argument supplied
  not exists(c.getKeywordArgument("code_challenge"))
select c,
  "OAuth authorization URL built without a PKCE `code_challenge:` parameter; " +
  "an attacker who intercepts the authorization code can exchange it for a token. " +
  "Add `code_challenge:` (S256) and `code_challenge_method: \"S256\"` here, and " +
  "pass `code_verifier:` at the token-exchange step."
