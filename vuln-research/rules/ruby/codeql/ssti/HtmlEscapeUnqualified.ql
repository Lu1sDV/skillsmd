/**
 * @name Ruby unqualified html_escape followed by % formatting (XSS)
 * @description A bare (unqualified) call to `html_escape` is used as the left operand of
 *              a `%` format operation with a hash of non-literal values. The format
 *              substitution happens AFTER escaping, so hash values re-introduce unescaped
 *              HTML. Qualify the call as `ERB::Util.html_escape` to fix.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/ssti-html-escape-unqualified
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0901
 * @source-citation derived from GitLab fix 61900eec005e (corpus-labeled ssti; actually reflected XSS via unqualified html_escape followed by % formatting); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall pct, MethodCall he
where
  // `a % b` is a MethodCall with method name "%"
  pct.getMethodName() = "%" and
  // the receiver of `%` is an html_escape call
  he = pct.getReceiver() and
  he.getMethodName() = "html_escape" and
  // unqualified: synthesized self receiver (bare call, no explicit ERB::Util. prefix)
  he.getReceiver() instanceof SelfVariableAccess and
  // the argument to `%` is a hash literal (the { key: val } format shape)
  pct.getArgument(0) instanceof HashLiteral
select pct,
  "Unqualified `html_escape` followed by `%` formatting can re-introduce unescaped HTML from the substitution values; use `ERB::Util.html_escape` (XSS, CWE-79)."
