/**
 * @name Ruby XSS via string interpolation in HTML anchor href
 * @description Building an `<a href="...">` tag by interpolating a non-constant
 *              expression directly into a Ruby string (e.g.
 *              `%(<a href="#{href}">#{content}</a>)`) allows injected quotes or
 *              angle-brackets in `href` or the link text to break out of the
 *              attribute and introduce cross-site scripting. Replace with a DOM
 *              builder such as `doc.document.create_element('a')` with property
 *              assignment, which separates structure from data.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.3
 * @precision high
 * @id rb/xss-string-interpolation-in-html-href
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0809
 * @source-citation derived from GitLab XSS fix (sha e6bac2a88998, ReferenceRedactor href interpolation); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `e` is an expression that is very likely to carry runtime data:
 * a method call (e.g. `node.attr('href')`), an instance variable read
 * (`@href`), a class variable read (`@@href`), or a global variable read
 * (`$href`).  Local variable reads are excluded because they are
 * AST-indistinguishable from locals that hold constant strings without
 * dataflow.  This keeps precision high while catching the canonical
 * GitLab pattern (`%(<a href="#{node.attr('href')}">…</a>)`).
 */
predicate isDynamicExpr(Expr e) {
  e instanceof MethodCall or
  e instanceof InstanceVariableReadAccess or
  e instanceof ClassVariableReadAccess or
  e instanceof GlobalVariableReadAccess
}

/**
 * Holds if `str` is a string-like literal (StringLiteral or HereDoc) that
 * has at least one text component whose raw text contains both `<a` and `href`.
 * This identifies the literal as building an HTML anchor element.
 */
predicate hasHtmlHrefTextComponent(StringlikeLiteral str) {
  exists(StringTextComponent txt |
    txt = str.getComponent(_) and
    txt.getRawText().matches("%<a%href%")
  )
}

/**
 * Holds if `str` contains at least one interpolation `#{...}` where the
 * interpolated expression is a dynamic/runtime value.
 */
predicate hasDynamicInterpolation(StringlikeLiteral str) {
  exists(StringInterpolationComponent interp, Expr inner |
    interp = str.getComponent(_) and
    inner = interp.getStmt(0) and
    isDynamicExpr(inner)
  )
}

from StringlikeLiteral str
where
  // Must be a plain StringLiteral or HereDoc — not a regexp or subshell
  (str instanceof StringLiteral or str instanceof HereDoc) and
  // The literal's static text mentions an HTML anchor with href
  hasHtmlHrefTextComponent(str) and
  // At least one interpolated slot is a dynamic expression
  hasDynamicInterpolation(str)
select str,
  "HTML anchor tag built by string interpolation; injected content in `href` or link text can break out of the attribute. Use a DOM builder (e.g. `create_element('a')`) instead."
