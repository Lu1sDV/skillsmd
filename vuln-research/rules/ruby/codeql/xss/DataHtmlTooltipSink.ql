/**
 * @name User-controlled string rendered as HTML via data-html tooltip attribute
 * @description A call to `dataset.merge!` or a `dataset[...]` assignment sets `html: true`
 *              alongside a user-controlled title value, instructing the Bootstrap/GitLab
 *              tooltip library to render the title as raw HTML. This enables XSS when the
 *              title string is user-controlled. Fix: remove `html: true` and assign the
 *              title directly (e.g. `dataset['title'] = title`) so the library
 *              HTML-escapes the value.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/xss-data-html-tooltip-sink
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0808
 * @source-citation derived from GitLab xss security fix 7df7f72b65c6 (Don't render label link tooltip names as HTML); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when `call` is a `merge!` call that contains an `html: true` pair
 * among its arguments (keyword or hash-literal argument).
 *
 * Pattern: dataset.merge!(html: true, title: ...)
 * The key combination `html: true` is the precise smell — it tells the
 * tooltip library to treat the title as raw HTML.
 */
predicate isMergeWithHtmlTrue(MethodCall call) {
  call.getMethodName() = "merge!" and
  exists(Pair p |
    // The pair appears directly as a keyword argument or inside a hash argument
    (p = call.getAnArgument() or
     exists(HashLiteral h | h = call.getAnArgument() and p = h.getAnElement())) and
    p.getKey().(SymbolLiteral).getConstantValue().getSymbol() = "html" and
    p.getValue().(BooleanLiteral).isTrue()
  )
}

from MethodCall call
where isMergeWithHtmlTrue(call)
select call,
  "dataset.merge! sets `html: true`, enabling the tooltip library to render the title as raw HTML; " +
  "remove `html: true` and assign the title directly (e.g. `dataset['title'] = title`) to prevent XSS."
