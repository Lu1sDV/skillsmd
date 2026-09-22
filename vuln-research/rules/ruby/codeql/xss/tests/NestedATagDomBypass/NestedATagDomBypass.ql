/**
 * @name Banzai sanitization allowlist pushes transformers without an unwrap-nested-a guard
 * @description A method builds a Banzai sanitization allowlist and pushes at least one
 *              transformer onto `allowlist[:transformers]` but never pushes a transformer
 *              that calls `method(:unwrap_nested_a)`. The HTML5 parser can produce nested
 *              `<a>` elements (via table foster-parenting, foreign content, etc.) that
 *              survive sanitization; a later ReferenceRedactor stage then leaks redacted
 *              inner-reference text through the outer `<a>`'s `data-original` attribute.
 *              Add `allowlist[:transformers].push(self.class.method(:unwrap_nested_a))`
 *              and implement `unwrap_nested_a` to replace nested anchors with their children.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/xss-nested-a-tag-dom-bypass
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0815
 * @source-citation derived from GitLab security fix 2349dfb36094 (Unwrap nested <a> no matter how they're produced); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `push` is a call `allowlist[:transformers].push(...)` inside callable `m`.
 *
 * In the Banzai pattern, `allowlist` is a local variable (assigned via `super`),
 * so the ElementReference receiver is a LocalVariableReadAccess, not a MethodCall.
 */
predicate isTransformerPush(MethodCall push, Callable m) {
  push.getMethodName() = "push" and
  push.getEnclosingCallable() = m and
  exists(ElementReference er, LocalVariableReadAccess lv |
    er = push.getReceiver() and
    lv = er.getReceiver() and
    lv.getVariable().getName() = "allowlist" and
    er.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "transformers"
  )
}

/**
 * Holds if `m` contains a call `.method(:unwrap_nested_a)` anywhere in its body,
 * indicating the nested-a guard is wired up.
 */
predicate hasUnwrapNestedAGuard(Callable m) {
  exists(MethodCall mc |
    mc.getMethodName() = "method" and
    mc.getEnclosingCallable() = m and
    mc.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "unwrap_nested_a"
  )
}

from MethodCall push, Callable m
where
  isTransformerPush(push, m) and
  not hasUnwrapNestedAGuard(m)
select push,
  "This sanitization allowlist pushes a transformer but never registers `method(:unwrap_nested_a)`; " +
  "nested `<a>` tags produced by the HTML5 parser will survive and can leak redacted reference text via `data-original`."
