/**
 * @name Hard-coded data evaluated as Ruby code
 * @description A hard-coded hexadecimal blob that reaches a code-evaluation sink (such as
 *              `eval` or `instance_eval`) is decoded and executed at runtime — a hallmark
 *              of concealed backdoors. Never `eval` decoded constants.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/hardcoded-secrets-data-to-eval
 * @tags security
 *       external/cwe/cwe-506
 * @vr-id RB-QL-2103
 * @source-citation inspired-by codeql/ruby-queries rb/hardcoded-data-interpreted-as-code (cwe-506); re-expressed original
 * @license derived-original
 */

private import codeql.ruby.security.HardcodedDataInterpretedAsCodeQuery
import HardcodedDataInterpretedAsCodeFlow::PathGraph

from
  HardcodedDataInterpretedAsCodeFlow::PathNode source,
  HardcodedDataInterpretedAsCodeFlow::PathNode sink
where
  HardcodedDataInterpretedAsCodeFlow::flowPath(source, sink) and
  sink.getNode().(Sink).getKind() = "code"
select sink.getNode(), source, sink,
  "Hard-coded data from $@ is evaluated as code.", source.getNode(), "this constant"
