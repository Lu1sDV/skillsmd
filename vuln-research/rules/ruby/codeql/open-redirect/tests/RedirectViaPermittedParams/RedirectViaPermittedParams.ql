/**
 * @name Ruby open redirect through permitted/strong parameters
 * @description Taint survives `ActionController::Parameters#permit`/`require`, so a
 *              redirect target taken from a strong-parameters hash is still
 *              attacker-controlled and can drive an open redirect. Validate the
 *              resolved URL against an allow-list before calling `redirect_to`.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/open-redirect-permitted-params
 * @tags security
 *       external/cwe/cwe-601
 * @vr-id RB-QL-1003
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
