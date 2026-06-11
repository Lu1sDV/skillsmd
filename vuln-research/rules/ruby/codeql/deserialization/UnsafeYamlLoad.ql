/**
 * @name Ruby unsafe YAML/Psych deserialization of remote data
 * @description Passing attacker-controlled data to `YAML.load` (pre-Psych-4) or the
 *              `unsafe_load*` / `load_stream` family allows instantiation of arbitrary
 *              Ruby objects and remote code execution. Use `YAML.safe_load` instead.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/deserialization-yaml-load
 * @tags security
 *       external/cwe/cwe-502
 * @vr-id RB-QL-0402
 * @source-citation inspired-by codeql ruby/unsafe-deserialization (cwe-502); Psych unsafe_load RCE research
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.UnsafeDeserializationQuery
import UnsafeCodeConstructionFlow::PathGraph

from UnsafeCodeConstructionFlow::PathNode source, UnsafeCodeConstructionFlow::PathNode sink
where
  UnsafeCodeConstructionFlow::flowPath(source, sink) and
  (
    sink.getNode() instanceof UnsafeDeserialization::YamlLoadArgument or
    sink.getNode() instanceof UnsafeDeserialization::YamlParseArgument
  )
select sink.getNode(), source, sink,
  "Unsafe YAML deserialization of a $@ may execute arbitrary code.", source.getNode(),
  source.getNode().(UnsafeDeserialization::Source).describe()
