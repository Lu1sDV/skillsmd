/**
 * @name Ruby XSS via .html_safe string interpolated with % operator
 * @description A string (literal or i18n call) is marked `.html_safe` and then
 *              interpolated via the `%` operator with a hash argument. Because
 *              `.html_safe` is applied before `%`, Rails auto-escaping is bypassed
 *              and any HTML in the interpolated values is inserted raw into the page.
 *              Replace with `safe_format(...)` and `tag_pair(...)` to escape properly.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.3
 * @precision high
 * @id rb/xss-hamlhtmlsafeinterpolationpercent
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0805
 * @source-citation derived from GitLab XSS security fixes (shas 349a5086 d09826fc e4e5d1da); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `htmlSafe` is a call to `.html_safe` whose receiver is either:
 *   - a string literal, or
 *   - an i18n translation helper call (s_(...), _(...), n_(...)).
 * These are the forms that appear in HAML/ERB views before the `%` operator.
 */
predicate isHtmlSafeOnStringOrI18n(MethodCall htmlSafe) {
  htmlSafe.getMethodName() = "html_safe" and
  (
    htmlSafe.getReceiver() instanceof StringLiteral
    or
    htmlSafe.getReceiver().(MethodCall).getMethodName() = ["s_", "_", "n_"]
  )
}

from MethodCall percentCall, MethodCall htmlSafe
where
  // The outer call is the % operator
  percentCall.getMethodName() = "%" and
  // Its receiver is a .html_safe call on a string literal or i18n helper
  htmlSafe = percentCall.getReceiver() and
  isHtmlSafeOnStringOrI18n(htmlSafe) and
  // The argument is a hash (hash literal passed as argument)
  percentCall.getAnArgument() instanceof HashLiteral
select percentCall,
  "The string is marked .html_safe before % interpolation; HTML in the substituted values is inserted raw, enabling XSS. Use safe_format(...) with tag_pair(...) instead."
