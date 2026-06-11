/**
 * @name Ruby open redirect from request parameter to redirect_to
 * @description Passing an unvalidated request parameter directly into a Rails
 *              `redirect_to` lets an attacker send the victim to an arbitrary
 *              external site (phishing, credential theft). Restrict redirects to
 *              an allow-list or a relative path before redirecting.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/open-redirect-from-params
 * @tags security
 *       external/cwe/cwe-601
 * @vr-id RB-QL-1001
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
