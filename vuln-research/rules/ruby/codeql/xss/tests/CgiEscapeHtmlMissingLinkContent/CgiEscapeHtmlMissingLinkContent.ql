/**
 * @name Banzai reference filter `object_link_text` returns unescaped HTML content
 * @description A method named `object_link_text` (the Banzai reference-filter hook that
 *              supplies the text content of generated `<a>` tags) returns a plain Ruby
 *              String without calling `CGI.escapeHTML` on the value before returning it.
 *              The return value is interpolated directly into an HTML context by the
 *              framework caller, so any user-controlled markup in the text produces stored
 *              XSS.  Fix: rename the override to `object_link_content_html` and wrap every
 *              returned text value with `CGI.escapeHTML(...)`.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id rb/xss-cgi-escape-html-missing-link-content
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0816
 * @source-citation derived from GitLab security fix 24e1797bbcc4 (Correct text/HTML confusion in AbstractReferenceFilter#object_link_text); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when `m` is a method named `object_link_text` — the Banzai hook whose
 * return value is inserted verbatim into an HTML `<a>` element body.
 */
predicate isObjectLinkTextMethod(Method m) { m.getName() = "object_link_text" }

/**
 * Holds when `call` is a `CGI.escapeHTML(...)` call anywhere inside method `m`.
 * This is the required sanitizer; its absence is the smell.
 */
predicate hasCgiEscapeHtmlCall(Method m) {
  exists(MethodCall call |
    call.getEnclosingCallable() = m and
    call.getMethodName() = "escapeHTML" and
    call.getReceiver().(ConstantAccess).getName() = "CGI"
  )
}

/**
 * Exclude test/spec files so we don't flag test helpers that deliberately
 * reproduce the vulnerable shape.
 */
predicate inProductionPath(Method m) {
  exists(string path | path = m.getLocation().getFile().getRelativePath() |
    not path.matches("spec/%") and
    not path.matches("test/%") and
    not path.matches("vendor/%")
  )
}

from Method m
where
  isObjectLinkTextMethod(m) and
  not hasCgiEscapeHtmlCall(m) and
  inProductionPath(m)
select m,
  "Method `object_link_text` returns plain text that is inserted into an HTML context without " +
  "CGI.escapeHTML; rename to `object_link_content_html` and wrap every returned value with " +
  "CGI.escapeHTML(...) to prevent XSS."
