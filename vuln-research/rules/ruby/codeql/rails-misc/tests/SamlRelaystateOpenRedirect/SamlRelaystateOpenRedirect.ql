/**
 * @name SAML RelayState used as open redirect without origin validation
 * @description An OmniAuth SAML callback passes `params['RelayState']` (or
 *              `params[:RelayState]`) to a redirect sink without first verifying
 *              the request originated from GitLab via an `OriginValidator`
 *              (`gitlab_initiated?` / `valid_gitlab_initiated_saml_request?`).
 *              An attacker can supply an arbitrary redirect destination in the
 *              RelayState parameter, producing an open redirect (CWE-601).
 *              Fix: gate the redirect on `valid_gitlab_initiated_saml_request?`
 *              before consuming the RelayState value.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/rails-misc-saml-relaystate-open-redirect
 * @tags security
 *       external/cwe/cwe-601
 * @vr-id RB-QL-2521
 * @source-citation derived from GitLab security fix 5a7e0b51 (SAML RelayState open redirect); CWE-601
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A `params[...]` element-reference call whose key is the string or symbol
 * `RelayState` (SAML uses the PascalCase name as a bare string key).
 */
predicate isRelayStateAccess(MethodCall bracket) {
  bracket.getMethodName() = "[]" and
  // receiver is any `params` call (explicit or implicit-self)
  bracket.getReceiver().(MethodCall).getMethodName() = "params" and
  exists(Expr key | key = bracket.getArgument(0) |
    // params['RelayState']
    key.getConstantValue().getString() = "RelayState"
    or
    // params[:RelayState]
    key.getConstantValue().getSymbol() = "RelayState"
  )
}

/**
 * A call that forwards a value to a redirect destination:
 *   - safe_redirect_path(...)
 *   - safe_redirect(...)
 *   - redirect_to(...)
 *   - store_location_for(...)
 *   - safe_relay_state (no-arg wrapper that itself calls safe_redirect_path)
 * We only flag when RelayState is a direct argument, so we look at the call
 * that *receives* the RelayState bracket expression as an argument.
 */
predicate isRedirectSink(MethodCall sink) {
  sink.getMethodName() =
    ["safe_redirect_path", "safe_redirect", "redirect_to", "store_location_for"]
}

/**
 * The enclosing callable contains a call to a SAML origin-validation guard:
 *   - valid_gitlab_initiated_saml_request?
 *   - gitlab_initiated?
 */
predicate hasOriginValidationGuard(Callable callable) {
  exists(MethodCall guard | guard.getEnclosingCallable() = callable |
    guard.getMethodName() =
      ["valid_gitlab_initiated_saml_request?", "gitlab_initiated?"]
  )
}

from MethodCall sink, MethodCall relayAccess
where
  isRedirectSink(sink) and
  isRelayStateAccess(relayAccess) and
  // RelayState bracket is a direct argument of the sink call
  relayAccess = sink.getAnArgument() and
  // No origin-validation guard exists in the same enclosing method
  not hasOriginValidationGuard(sink.getEnclosingCallable())
select sink,
  "SAML RelayState passed to redirect sink without origin validation; call valid_gitlab_initiated_saml_request? before following params['RelayState'] to prevent open redirect."
