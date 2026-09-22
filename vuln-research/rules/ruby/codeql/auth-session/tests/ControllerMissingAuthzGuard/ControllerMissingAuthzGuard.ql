/**
 * @name Ruby auth-session controller defines mutating action without authorization guard
 * @description A Rails controller defines at least one state-changing action
 *              (`create`, `update`, `destroy`, or `edit`) but has no
 *              `before_action`/`before_filter` in its class body whose callback
 *              symbol matches an authentication or authorization naming convention
 *              (`authenticate*`, `authorize*`, `require_*`, `ensure_*`,
 *              `*_authentication`). An attacker can invoke the mutating endpoint
 *              with no access check enforced. Add a `before_action
 *              :authenticate_user!` or `:authorize_X!` guard.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-controller-missing-authz-guard
 * @tags security
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1307
 * @source-citation derived from GitLab auth-session missing-authorization fixes (shas 049e1a244d4a,462b0f25b3fa,468b6231b86b); CWE-862
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `sym` matches an authentication or authorization callback naming
 * convention used in Rails/GitLab codebases.
 * `bindingset[sym]` tells CodeQL that the caller is responsible for binding `sym`.
 */
bindingset[sym]
private predicate isAuthCallbackSymbol(string sym) {
  sym.matches("authenticate%") or
  sym.matches("authorize%") or
  sym.matches("require_%") or
  sym.matches("ensure_%") or
  sym.matches("%_authentication")
}

/**
 * Holds if `ba` is a `before_action` / `before_filter` / `prepend_before_action`
 * call directly in the class body of `ctrl` (i.e. `ba.getEnclosingModule() = ctrl`)
 * and its first positional argument is a symbol satisfying `isAuthCallbackSymbol`.
 */
private predicate hasAuthBeforeAction(ClassDeclaration ctrl) {
  exists(MethodCall ba, string sym |
    ba.getMethodName() = ["before_action", "before_filter", "prepend_before_action"] and
    ba.getEnclosingModule() = ctrl and
    sym = ba.getAnArgument().(SymbolLiteral).getConstantValue().getSymbol() and
    isAuthCallbackSymbol(sym)
  )
}

from ClassDeclaration ctrl
where
  // The class is a Rails controller (by naming convention).
  ctrl.getName().matches("%Controller") and
  // It defines at least one mutating action.
  exists(ctrl.getMethod(["create", "update", "destroy", "edit"])) and
  // It has NO before_action / before_filter in this class body with an auth/authz callback.
  not hasAuthBeforeAction(ctrl)
select ctrl,
  "Controller defines mutating action(s) but has no authentication/authorization before_action; add an access guard (missing authorization)."
