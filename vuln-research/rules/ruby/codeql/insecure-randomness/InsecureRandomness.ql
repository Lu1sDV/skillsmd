/**
 * @name Insecure randomness in a security context
 * @description Using a non-cryptographic pseudo-random number generator (Kernel#rand)
 *              to produce a security-sensitive value lets an attacker predict the value.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.8
 * @precision high
 * @id rb/insecure-randomness-flow
 * @tags security
 *       external/cwe/cwe-338
 * @vr-id RB-QL-2201
 * @source-citation inspired-by codeql ruby experimental/insecure-randomness; CWE-338
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.security.InsecureRandomnessQuery
import InsecureRandomnessFlow::PathGraph

from InsecureRandomnessFlow::PathNode source, InsecureRandomnessFlow::PathNode sink
where InsecureRandomnessFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Insecure random value from $@ flows into a security-sensitive context.",
  source.getNode(), source.getNode().toString()
