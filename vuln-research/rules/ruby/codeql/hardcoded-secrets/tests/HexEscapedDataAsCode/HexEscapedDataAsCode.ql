/**
 * @name Hard-coded data interpreted as Ruby code
 * @description A hard-coded hexadecimal blob or escape-encoded string that reaches a
 *              code-execution or import sink lets a backdoor decode and run concealed
 *              logic at runtime. Keep executable code in source, not in opaque constants.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/hardcoded-secrets-data-as-code
 * @tags security
 *       external/cwe/cwe-506
 * @vr-id RB-QL-2101
 * @source-citation inspired-by codeql/ruby-queries rb/hardcoded-data-interpreted-as-code (cwe-506); re-expressed original
 * @license derived-original
 */

private import codeql.ruby.security.HardcodedDataInterpretedAsCodeQuery
import HardcodedDataInterpretedAsCodeFlow::PathGraph

from
  HardcodedDataInterpretedAsCodeFlow::PathNode source,
  HardcodedDataInterpretedAsCodeFlow::PathNode sink
where HardcodedDataInterpretedAsCodeFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Hard-coded data from $@ is interpreted as " + sink.getNode().(Sink).getKind() + ".",
  source.getNode(), "this constant"
