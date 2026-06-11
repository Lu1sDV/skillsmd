/**
 * @name Ruby crypto-tls clear-text logging of sensitive data
 * @description Writing sensitive values (passwords, API tokens, private keys)
 *              into a logger without encryption or hashing exposes them to anyone
 *              who can read the logs. Redact or omit secrets before logging.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/crypto-tls-clear-text-logging-sensitive-data
 * @tags security
 *       external/cwe/cwe-312
 *       external/cwe/cwe-359
 *       external/cwe/cwe-532
 * @vr-id RB-QL-1402
 * @source-citation reuses codeql.ruby.security.CleartextLoggingQuery (built-in flow module); CWE-312/359/532
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.CleartextLoggingQuery
import CleartextLoggingFlow::PathGraph

from CleartextLoggingFlow::PathNode source, CleartextLoggingFlow::PathNode sink
where CleartextLoggingFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "This logs sensitive data returned by $@ as clear text.",
  source.getNode(), source.getNode().(Source).describe()
