/**
 * @name Ruby placeholder replacement passes HTML-tagged value directly to CGI.escapeHTML (XSS)
 * @description `CGI.escapeHTML` is called on the result of a proc/lambda invocation
 *              without first stripping HTML tags. An attacker-controlled replacement
 *              value may contain HTML that survives `escapeHTML` because tag removal
 *              happens after entity encoding. Fix: pass the value through an HTML
 *              sanitization filter (e.g. `Banzai::Filter::SanitizationFilter`) to
 *              strip tags first, then call `CGI.escapeHTML` on the resulting text.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.3
 * @precision high
 * @id rb/ssti-placeholder-sanitization-bypass
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0903
 * @source-citation derived from GitLab security fix a141459f0aa5 (security-placeholder-bypass); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `e` is a `.call(...)` invocation or contains one as the left-hand
 * operand of a `||` short-circuit default (e.g. `action.call(ctx) || ''`).
 */
predicate isCallExprOrDefault(Expr e, MethodCall inner) {
  // Direct: CGI.escapeHTML(action.call(ctx))
  inner = e and inner.getMethodName() = "call"
  or
  // With default: CGI.escapeHTML(action.call(ctx) || '')
  exists(BinaryOperation op |
    op = e and
    op.getOperator() = "||" and
    inner = op.getLeftOperand() and
    inner.getMethodName() = "call"
  )
}

from MethodCall escapeCall, MethodCall innerCall
where
  // CGI.escapeHTML(...)
  escapeCall.getMethodName() = "escapeHTML" and
  escapeCall.getReceiver().(ConstantReadAccess).getName() = "CGI" and
  // The argument (possibly wrapped in `|| default`) is a .call() invocation
  isCallExprOrDefault(escapeCall.getArgument(0), innerCall) and
  // No sanitization filter call exists in the same enclosing callable.
  // Safe code calls a sanitizer (e.g. SanitizationFilter.new(...).call) before escapeHTML.
  not exists(MethodCall sanitizerNew |
    sanitizerNew.getEnclosingCallable() = escapeCall.getEnclosingCallable() and
    sanitizerNew.getMethodName() = "new" and
    sanitizerNew.getReceiver().(ConstantReadAccess).getName() =
      ["SanitizationFilter", "Sanitize", "Loofah", "ActionController::Base"]
  )
select escapeCall,
  "CGI.escapeHTML applied to the result of .call() without prior HTML tag sanitization; " +
    "the replacement value may contain HTML tags that survive entity encoding. " +
    "Strip tags with a sanitization filter before calling CGI.escapeHTML."
