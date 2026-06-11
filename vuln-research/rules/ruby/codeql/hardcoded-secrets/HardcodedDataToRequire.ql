/**
 * @name Hard-coded data used as a Ruby import path
 * @description A hard-coded hexadecimal blob that flows into a `require` argument decodes
 *              into an import path at runtime, a classic obfuscated-loader/backdoor tell.
 *              Require fixed, reviewable file names instead of decoded constants.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/hardcoded-secrets-data-to-require
 * @tags security
 *       external/cwe/cwe-506
 * @vr-id RB-QL-2102
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
  sink.getNode().(Sink).getKind() = "an import path"
select sink.getNode(), source, sink,
  "Hard-coded data from $@ is interpreted as an import path.", source.getNode(),
  "this constant"
