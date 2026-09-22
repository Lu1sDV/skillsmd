/**
 * @name Unsafe HTML string interpolation via % after html_safe
 * @description A translation string is marked `html_safe` and then interpolated
 *              using Ruby's `%` operator with a hash of user-controlled values.
 *              Because the string is already marked safe, Rails does not escape
 *              the interpolated values, allowing injected HTML/JavaScript to
 *              reach the browser unescaped. Replace with
 *              `safe_format(_(\"...\"), key: value)` which escapes each
 *              interpolated slot before composing the safe result.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/rails-misc-unsafe-html-string-interpolation
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-2510
 * @source-citation derived from GitLab security fixes 974753ea,ffcc5e22 (html_safe + % interpolation bypasses escaping); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `htmlSafeCall` is a call to `html_safe` on any expression
 * (typically an i18n translation call such as `_()`, `s_()`, `n_()`).
 */
predicate isHtmlSafeCall(MethodCall htmlSafeCall) {
  htmlSafeCall.getMethodName() = "html_safe"
}

/**
 * Holds if `percentCall` is a `%` method call whose receiver is a `html_safe`
 * call — i.e. the pattern `expr.html_safe % { ... }`.
 */
predicate isUnsafeInterpolation(MethodCall percentCall, MethodCall htmlSafeCall) {
  percentCall.getMethodName() = "%" and
  percentCall.getReceiver() = htmlSafeCall and
  isHtmlSafeCall(htmlSafeCall)
}

from MethodCall percentCall, MethodCall htmlSafeCall
where isUnsafeInterpolation(percentCall, htmlSafeCall)
select percentCall,
  "String interpolation via `%` after `html_safe` bypasses Rails HTML escaping; " +
  "replace with `safe_format(...)` to escape interpolated values."
