/**
 * @name Ruby path traversal via user-controlled path expression
 * @description Building a filesystem path from attacker-controlled input lets a
 *              malicious user escape the intended directory (e.g. via `../`) and
 *              read or write arbitrary files. Constrain paths to an allow-list and
 *              canonicalise before use.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/path-traversal-path-injection
 * @tags security
 *       external/cwe/cwe-022
 *       external/cwe/cwe-023
 *       external/cwe/cwe-073
 * @vr-id RB-QL-0601
 * @source-citation inspired-by codeql/ruby-queries security/cwe-022/PathInjection.ql
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.TaintTracking
import codeql.ruby.security.PathInjectionQuery
import PathInjectionFlow::PathGraph

from PathInjectionFlow::PathNode source, PathInjectionFlow::PathNode sink
where PathInjectionFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "This filesystem path depends on a $@ and may allow directory traversal.",
  source.getNode(), "user-provided value"
