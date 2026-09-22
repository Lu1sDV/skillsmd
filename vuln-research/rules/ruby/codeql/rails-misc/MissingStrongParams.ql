/**
 * @name Rails controller uses raw params without strong parameters
 * @description Accessing `params[:key]` directly in a Rails controller instead of
 *              `params.permit(...)` allows unexpected keys to be accepted, enabling
 *              mass-assignment, unexpected query parameters, and information exposure.
 *              Use `params.permit(:key)` or a dedicated permitted-params method.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-missing-strong-params
 * @tags security
 *       external/cwe/cwe-20
 * @vr-id RB-QL-2516
 * @source-citation derived from GitLab security fix 56d0dc5b (Use strong params for secure controllers); CWE-20
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a bare `params` method call with no explicit receiver
 * (i.e., an implicit-self call like Rails controllers use).
 * These are `IdentifierMethodCall` instances whose receiver is a synthetic self.
 */
predicate isParamsIdentifier(MethodCall c) {
  c.getMethodName() = "params" and
  // IdentifierMethodCall has a synthetic self receiver; RegularMethodCall
  // would have an explicit receiver as a non-Self AST node.
  // We distinguish by checking the receiver is a SelfVariableReadAccess
  // (the synthetic self injected by the extractor).
  c.getReceiver() instanceof SelfVariableReadAccess
}

/**
 * A call `params[:key]` — an ElementReference (which extends MethodCall with
 * methodName "[]") whose direct receiver is the bare `params` identifier call.
 * This pattern is unfenced: no `.permit(...)` guards the key.
 *
 * GOOD cases excluded automatically:
 *   params.permit(:id)[:id]          — receiver of [] is `permit`, not `params`
 *   params.require(:x).permit(:y)    — no [] at all, or receiver is `permit`
 */
predicate isRawParamsAccess(MethodCall bracket) {
  bracket.getMethodName() = "[]" and
  // Direct receiver is the bare `params` call
  isParamsIdentifier(bracket.getReceiver()) and
  // The argument is a symbol literal (params[:key]) — ignoring params[var]
  exists(SymbolLiteral sym | sym = bracket.getArgument(0))
}

from MethodCall c
where isRawParamsAccess(c)
select c,
  "Raw params[:key] access without strong parameters; use params.permit(:key) or a dedicated permitted-params method to filter unexpected keys."
