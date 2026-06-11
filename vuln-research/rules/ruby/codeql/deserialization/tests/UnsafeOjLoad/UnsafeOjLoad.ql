/**
 * @name Ruby unsafe Oj deserialization of remote data
 * @description Passing attacker-controlled data to `Oj.load` in the default `:object`
 *              mode (or `Oj.object_load`) reconstructs arbitrary Ruby objects and can
 *              lead to remote code execution. Set `mode: :strict`/`:compat`.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/deserialization-oj-load
 * @tags security
 *       external/cwe/cwe-502
 * @vr-id RB-QL-0403
 * @source-citation inspired-by codeql ruby/unsafe-deserialization (cwe-502); Oj :object mode RCE research
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.UnsafeDeserializationQuery
import UnsafeCodeConstructionFlow::PathGraph

from UnsafeCodeConstructionFlow::PathNode source, UnsafeCodeConstructionFlow::PathNode sink
where
  UnsafeCodeConstructionFlow::flowPath(source, sink) and
  sink.getNode() instanceof UnsafeDeserialization::UnsafeOjLoadArgument
select sink.getNode(), source, sink,
  "Unsafe Oj object-mode deserialization of a $@ may execute arbitrary code.", source.getNode(),
  source.getNode().(UnsafeDeserialization::Source).describe()
