/**
 * @name Weak randomness selecting from a character set
 * @description Indexing into a character set with a non-cryptographic random value
 *              (Kernel#rand) yields predictable tokens, passwords, or identifiers.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.8
 * @precision high
 * @id rb/insecure-randomness-charset-index
 * @tags security
 *       external/cwe/cwe-338
 * @vr-id RB-QL-2202
 * @source-citation inspired-by codeql ruby InsecureRandomness CharacterIndexing sink; CWE-338
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.security.InsecureRandomnessQuery
import codeql.ruby.security.InsecureRandomnessCustomizations
import InsecureRandomnessFlow::PathGraph

from InsecureRandomnessFlow::PathNode source, InsecureRandomnessFlow::PathNode sink
where
  InsecureRandomnessFlow::flowPath(source, sink) and
  sink.getNode() instanceof InsecureRandomness::CharacterIndexing
select sink.getNode(), source, sink,
  "Insecure random value from $@ indexes a character set, yielding a predictable token.",
  source.getNode(), source.getNode().toString()
