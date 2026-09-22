/**
 * @name Ruby unqualified html_escape or html_escape_once call (XSS)
 * @description A bare (unqualified) call to `html_escape` or `html_escape_once` is used
 *              without an explicit `ERB::Util.` receiver. In certain Rails module scopes
 *              the helper may not resolve to `ERB::Util`, causing unsafe HTML output.
 *              When combined with `%` format substitution the escape order also allows
 *              re-introduction of raw HTML from substitution values. Qualify as
 *              `ERB::Util.html_escape` or `ERB::Util.html_escape_once` to fix.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id rb/ssti-html-escape-wrong-method
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0902
 * @source-citation derived from GitLab fix 61900eec005e (unqualified html_escape / html_escape_once replaced with ERB::Util-qualified form across ~20 call sites); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall he
where
  // Call is html_escape or html_escape_once (the two helpers patched in the fix)
  he.getMethodName() = ["html_escape", "html_escape_once"] and
  // Unqualified: the receiver is synthesized self (bare call, not ERB::Util.html_escape)
  he.getReceiver() instanceof SelfVariableAccess
select he,
  "Unqualified `" + he.getMethodName() +
  "` call may not resolve to ERB::Util in all module scopes and is unsafe when combined with `%` format substitution; use `ERB::Util." +
  he.getMethodName() + "` (XSS, CWE-79)."
