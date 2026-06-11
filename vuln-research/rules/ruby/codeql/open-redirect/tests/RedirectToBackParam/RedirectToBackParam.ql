/**
 * @name Ruby open redirect from request-supplied return URL
 * @description A "return to" / "next" style request parameter flowing into
 *              `redirect_to` lets an attacker craft a link on the trusted site
 *              that bounces the victim to a malicious external page. Resolve such
 *              parameters against an allow-list or force a relative path.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/open-redirect-return-url-param
 * @tags security
 *       external/cwe/cwe-601
 * @vr-id RB-QL-1004
 * @source-citation reuses codeql.ruby.security.UrlRedirectQuery (built-in UrlRedirect flow module); CWE-601
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.UrlRedirectQuery
import UrlRedirectFlow::PathGraph

from UrlRedirectFlow::PathNode source, UrlRedirectFlow::PathNode sink
where UrlRedirectFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Untrusted URL redirection depends on a $@.", source.getNode(), "user-provided value"
