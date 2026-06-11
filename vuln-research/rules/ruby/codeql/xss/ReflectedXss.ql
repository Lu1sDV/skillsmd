/**
 * @name Ruby reflected cross-site scripting via response body
 * @description Request-derived input that reaches an HTML response without escaping
 *              lets an attacker inject script into the page served back to the victim.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/xss-reflected-response
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 * @vr-id RB-QL-0801
 * @source-citation inspired-by codeql rb/reflected-xss; reuses ReflectedXssFlow module
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.ReflectedXSSQuery
import ReflectedXssFlow::PathGraph

from ReflectedXssFlow::PathNode source, ReflectedXssFlow::PathNode sink
where ReflectedXssFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Reflected XSS: unescaped $@ is written into the HTTP response body.", source.getNode(),
  "request-derived value"
