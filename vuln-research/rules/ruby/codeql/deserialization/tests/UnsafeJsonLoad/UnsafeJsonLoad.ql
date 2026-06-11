/**
 * @name Ruby unsafe JSON.load deserialization of remote data
 * @description `JSON.load` / `JSON.restore` honour the `json_class` directive and can
 *              instantiate arbitrary objects from attacker-controlled input, unlike
 *              `JSON.parse`. Prefer `JSON.parse` for untrusted data.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/deserialization-json-load
 * @tags security
 *       external/cwe/cwe-502
 * @vr-id RB-QL-0404
 * @source-citation inspired-by codeql ruby/unsafe-deserialization (cwe-502); JSON.load json_class research
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.UnsafeDeserializationQuery
import UnsafeCodeConstructionFlow::PathGraph

from UnsafeCodeConstructionFlow::PathNode source, UnsafeCodeConstructionFlow::PathNode sink
where
  UnsafeCodeConstructionFlow::flowPath(source, sink) and
  sink.getNode() instanceof UnsafeDeserialization::JsonLoadArgument
select sink.getNode(), source, sink,
  "Unsafe JSON.load deserialization of a $@ may instantiate arbitrary objects.",
  source.getNode(), source.getNode().(UnsafeDeserialization::Source).describe()
