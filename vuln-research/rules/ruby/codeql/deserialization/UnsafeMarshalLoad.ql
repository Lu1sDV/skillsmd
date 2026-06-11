/**
 * @name Ruby unsafe Marshal deserialization of remote data
 * @description Passing attacker-controlled data to `Marshal.load` / `Marshal.restore`
 *              reconstructs arbitrary Ruby objects and can trigger remote code
 *              execution via crafted gadget chains. Deserialize only trusted data.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/deserialization-marshal-load
 * @tags security
 *       external/cwe/cwe-502
 * @vr-id RB-QL-0401
 * @source-citation inspired-by codeql ruby/unsafe-deserialization (cwe-502); Ruby Marshal RCE gadget research
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.UnsafeDeserializationQuery
import UnsafeCodeConstructionFlow::PathGraph

from UnsafeCodeConstructionFlow::PathNode source, UnsafeCodeConstructionFlow::PathNode sink
where
  UnsafeCodeConstructionFlow::flowPath(source, sink) and
  sink.getNode() instanceof UnsafeDeserialization::MarshalLoadOrRestoreArgument
select sink.getNode(), source, sink,
  "Marshal deserialization of a $@ may execute arbitrary code.", source.getNode(),
  source.getNode().(UnsafeDeserialization::Source).describe()
