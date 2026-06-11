/**
 * @name Ruby crypto-tls clear-text storage of sensitive data
 * @description Persisting sensitive values (passwords, secrets, certificates)
 *              without encryption or hashing lets an attacker who reaches the
 *              store read them directly. Encrypt at rest or store a strong hash.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/crypto-tls-clear-text-storage-sensitive-data
 * @tags security
 *       external/cwe/cwe-312
 *       external/cwe/cwe-359
 *       external/cwe/cwe-532
 * @vr-id RB-QL-1403
 * @source-citation reuses codeql.ruby.security.CleartextStorageQuery (built-in flow module); CWE-312/359/532
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.CleartextStorageQuery
import codeql.ruby.security.CleartextStorageCustomizations::CleartextStorage
import CleartextStorageFlow::PathGraph

from CleartextStorageFlow::PathNode source, CleartextStorageFlow::PathNode sink
where CleartextStorageFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "This stores sensitive data returned by $@ as clear text.",
  source.getNode(), source.getNode().(Source).describe()
