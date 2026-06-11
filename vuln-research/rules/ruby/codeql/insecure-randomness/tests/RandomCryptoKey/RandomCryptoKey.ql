/**
 * @name Weak randomness in a cryptographic operation
 * @description Feeding a non-cryptographic random value (Kernel#rand) into a cryptographic
 *              operation lets an attacker predict keys, IVs, or plaintext nonces.
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.8
 * @precision high
 * @id rb/insecure-randomness-crypto-input
 * @tags security
 *       external/cwe/cwe-338
 * @vr-id RB-QL-2203
 * @source-citation inspired-by codeql ruby InsecureRandomness CryptoKeySink; CWE-338
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
  sink.getNode() instanceof InsecureRandomness::CryptoKeySink
select sink.getNode(), source, sink,
  "Insecure random value from $@ is used in a cryptographic operation.",
  source.getNode(), source.getNode().toString()
