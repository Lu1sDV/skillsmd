/**
 * @name Ruby open redirect via tainted host in interpolated URL
 * @description When a request parameter controls the leading (host) portion of an
 *              interpolated string passed to `redirect_to`, an attacker can force a
 *              redirect to an arbitrary external origin. Only the suffix of a URL is
 *              safe to interpolate; validate or allow-list the host instead.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/open-redirect-interpolated-host
 * @tags security
 *       external/cwe/cwe-601
 * @vr-id RB-QL-1002
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
