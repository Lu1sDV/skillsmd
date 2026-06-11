/**
 * @name Ruby unsafe code constructed from library input
 * @description Building a code string from externally controlled library input and later evaluating
 *              it may allow a caller to execute arbitrary code.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 6.1
 * @precision high
 * @id rb/code-injection-unsafe-construction
 * @tags security
 *       external/cwe/cwe-094
 *       external/cwe/cwe-116
 * @vr-id RB-QL-0202
 * @source-citation inspired-by codeql ruby cwe-094/UnsafeCodeConstruction.ql; reuses UnsafeCodeConstructionFlow
 * @license derived-original
 */

import codeql.ruby.security.UnsafeCodeConstructionQuery
import UnsafeCodeConstructionFlow::PathGraph

from
  UnsafeCodeConstructionFlow::PathNode source, UnsafeCodeConstructionFlow::PathNode sink,
  Sink sinkNode
where UnsafeCodeConstructionFlow::flowPath(source, sink) and sinkNode = sink.getNode()
select sink.getNode(), source, sink,
  "This " + sinkNode.getSinkType() + " which depends on $@ is later $@.", source.getNode(),
  "library input", sinkNode.getCodeSink(), "interpreted as code"
