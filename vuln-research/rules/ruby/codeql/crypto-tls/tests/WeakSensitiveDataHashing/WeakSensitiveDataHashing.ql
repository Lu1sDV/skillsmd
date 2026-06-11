/**
 * @name Ruby crypto-tls weak hash of sensitive data
 * @description Hashing sensitive data (passwords, tokens, certificates) with a
 *              broken or computationally cheap algorithm (MD5, SHA1) lets an
 *              attacker recover or brute-force the original value. Use a strong,
 *              salted, computationally expensive KDF (bcrypt, scrypt, PBKDF2).
 * @kind path-problem
 * @problem.severity warning
 * @security-severity 7.5
 * @precision high
 * @id rb/crypto-tls-weak-sensitive-data-hashing
 * @tags security
 *       external/cwe/cwe-327
 *       external/cwe/cwe-328
 *       external/cwe/cwe-916
 * @vr-id RB-QL-1401
 * @source-citation reuses codeql.ruby.security.WeakSensitiveDataHashingQuery (built-in flow module); CWE-327/328/916
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.WeakSensitiveDataHashingQuery
import WeakSensitiveDataHashingFlow::PathGraph

from
  WeakSensitiveDataHashingFlow::PathNode source, WeakSensitiveDataHashingFlow::PathNode sink,
  string ending, string algorithmName, string classification
where
  normalHashFunctionFlowPath(source, sink) and
  algorithmName = sink.getNode().(NormalHashFunction::Sink).getAlgorithmName() and
  classification = source.getNode().(NormalHashFunction::Source).getClassification() and
  ending = "."
  or
  computationallyExpensiveHashFunctionFlowPath(source, sink) and
  algorithmName = sink.getNode().(ComputationallyExpensiveHashFunction::Sink).getAlgorithmName() and
  classification =
    source.getNode().(ComputationallyExpensiveHashFunction::Source).getClassification() and
  (
    sink.getNode().(ComputationallyExpensiveHashFunction::Sink).isComputationallyExpensive() and
    ending = "."
    or
    not sink.getNode().(ComputationallyExpensiveHashFunction::Sink).isComputationallyExpensive() and
    ending =
      " for " + classification +
        " hashing, since it is not a computationally expensive hash function."
  )
select sink.getNode(), source, sink,
  "$@ is used in a hashing algorithm (" + algorithmName + ") that is insecure" + ending,
  source.getNode(), "Sensitive data (" + classification + ")"
