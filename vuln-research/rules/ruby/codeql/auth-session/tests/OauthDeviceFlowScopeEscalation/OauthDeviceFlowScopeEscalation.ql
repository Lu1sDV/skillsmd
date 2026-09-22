/**
 * @name OAuth device flow scope escalation — missing scope-validation patch
 * @description A `class_eval` block on `Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest`
 *              does not call `validate` with a scope-checking validator, leaving the device
 *              authorization flow able to issue tokens for scopes beyond what the application
 *              was approved for. Add a `validate :scopes_match_configured` override (or
 *              equivalent) inside the patch to re-validate requested scopes before token issuance.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/auth-session-oauth-device-flow-scope-escalation
 * @tags security
 *       external/cwe/cwe-269
 * @vr-id RB-QL-1319
 * @source-citation derived from GitLab security fix 1242ad1b96fb (Add security patch for OAuth device flow scope validation bypass); CWE-269
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `ce` is a `class_eval` call whose receiver chain refers to
 * `Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest`.
 * We check the full constant path by matching the stringified receiver.
 */
predicate isDeviceAuthRequestClassEval(MethodCall ce) {
  ce.getMethodName() = "class_eval" and
  ce.hasBlock() and
  exists(ConstantReadAccess leaf |
    leaf = ce.getReceiver() and
    leaf.getName() = "DeviceAuthorizationRequest"
  )
}

/**
 * Holds if `call` is a `validate` DSL call inside `block`, where the first
 * argument is a symbol naming a scope-checking validator
 * (`:scopes_match_configured`, `:validate_scopes_match_configured`,
 *  `:scopes`, or any symbol containing "scope").
 */
predicate hasScopeValidateCall(Block block, MethodCall call) {
  call.getMethodName() = "validate" and
  block.getAChild*() = call and
  exists(SymbolLiteral sym |
    sym = call.getArgument(0) and
    sym.getConstantValue().getSymbol().matches("%scope%")
  )
}

from MethodCall ce
where
  isDeviceAuthRequestClassEval(ce) and
  not hasScopeValidateCall(ce.getBlock(), _)
select ce,
  "Doorkeeper::DeviceAuthorizationGrant::OAuth::DeviceAuthorizationRequest is patched via class_eval " +
  "but no scope-validation `validate` call is present; device authorization can issue tokens for " +
  "unapproved scopes. Add `validate :scopes_match_configured` (or equivalent) to enforce scope checks."
