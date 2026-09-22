/**
 * @name Nokogiri node children set via Sanitize.fragment() on HTML attribute values
 * @description A Banzai filter calls `Sanitize.fragment(attr_value)` on HTML attribute
 *              values (e.g. `img['alt']`, `img['src']`, `img['data-src']`) to produce
 *              link text, then chains `.presence` on the result and assigns it as
 *              Nokogiri node children via `node.children =`. `Sanitize.fragment` can
 *              pass through HTML markup, so attribute values containing tags reach the
 *              DOM as raw HTML, causing XSS. Use `node.content = value` instead,
 *              which sets plain text and auto-escapes any HTML.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/xss-banzaisanitizefragmentasnodecontent
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0811
 * @source-citation derived from GitLab security fix 06d921b1 (Escape, don't sanitise alt text in ImageLinkFilter); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when `fragCall` is a `Sanitize.fragment(x)` call and the result is
 * immediately chained with `.presence` — the exact pattern from the real fix.
 *
 * The chain `Sanitize.fragment(f).presence` is the specific smell:
 * the code uses Sanitize.fragment to "strip" HTML attribute values before
 * using them as link text, but `fragment` is not designed for that purpose and
 * can pass through markup, enabling XSS.  The fix is to use plain attribute
 * values directly and assign via `node.content =` (which auto-escapes).
 */
predicate isSanitizeFragmentDotPresence(MethodCall outer) {
  // The outer call is `.presence`
  outer.getMethodName() = "presence" and
  // The receiver of `.presence` is `Sanitize.fragment(...)`
  exists(MethodCall inner |
    inner = outer.getReceiver() and
    inner.getMethodName() = "fragment" and
    inner.getReceiver().(ConstantAccess).getName() = "Sanitize"
  )
}

from MethodCall presenceCall
where isSanitizeFragmentDotPresence(presenceCall)
select presenceCall,
  "Sanitize.fragment().presence is used to produce link text from an HTML attribute value; " +
  "Sanitize.fragment can pass through HTML markup. Use node.content = value (plain-text assignment) instead."
