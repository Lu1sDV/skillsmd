/**
 * @name OAuth identity-link provider and extern_uid passed as URL params instead of session
 * @description During an OAuth identity-link flow, `provider` and `extern_uid` are
 *              passed as URL query parameters to the confirmation page. An attacker can
 *              forge or manipulate these parameters to link a victim's account to an
 *              attacker-controlled identity. Store the values in
 *              `session[:identity_link_provider]` and `session[:identity_link_extern_uid]`
 *              instead, and read them back from the session on confirmation.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/auth-session-identity-link-sensitive-data-in-params
 * @tags security
 *       external/cwe/cwe-384
 * @vr-id RB-QL-1327
 * @source-citation derived from GitLab security fix e2d183895fdf (Use session instead of params for identity linking); CWE-384
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `sessionRef` is a session key assignment for one of the identity-link
 * session keys (`identity_link_provider` or `identity_link_extern_uid`) inside
 * the same callable as `redirect`, indicating the fixed pattern.
 */
predicate hasIdentityLinkSessionAssignment(MethodCall redirect) {
  exists(AssignExpr assign, ElementReference sessionRef, SymbolLiteral key |
    sessionRef = assign.getLeftOperand() and
    sessionRef.getReceiver().(MethodCall).getMethodName() = "session" and
    key = sessionRef.getArgument(0) and
    key.getConstantValue().getSymbol() = ["identity_link_provider", "identity_link_extern_uid"] and
    assign.getEnclosingCallable() = redirect.getEnclosingCallable()
  )
}

from MethodCall redirect, MethodCall pathCall
where
  redirect.getMethodName() = "redirect_to" and
  // The single argument to redirect_to is a URL-helper method call
  pathCall = redirect.getArgument(0) and
  // That path helper has a `provider:` keyword argument
  exists(pathCall.getKeywordArgument("provider")) and
  // And an `extern_uid:` keyword argument
  exists(pathCall.getKeywordArgument("extern_uid")) and
  // The same enclosing method does NOT also store these values in session (fixed pattern)
  not hasIdentityLinkSessionAssignment(redirect)
select redirect,
  "OAuth identity-link `provider` and `extern_uid` are passed as URL query parameters to the " +
    "confirmation redirect. An attacker can forge these values to hijack the identity-link flow. " +
    "Store them in `session[:identity_link_provider]` and `session[:identity_link_extern_uid]` instead."
