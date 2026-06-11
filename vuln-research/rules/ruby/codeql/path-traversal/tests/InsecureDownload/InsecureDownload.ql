/**
 * @name Ruby download of sensitive file over insecure connection
 * @description Fetching an executable, script, or other sensitive file over a
 *              plaintext `http://` URL lets a network attacker tamper with the
 *              payload (man-in-the-middle). Use `https://` and verify integrity.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/path-traversal-insecure-download
 * @tags security
 *       external/cwe/cwe-829
 * @vr-id RB-QL-0602
 * @source-citation inspired-by codeql/ruby-queries security/cwe-829/InsecureDownload.ql
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.TaintTracking
import codeql.ruby.security.InsecureDownloadQuery
import InsecureDownloadFlow::PathGraph

from InsecureDownloadFlow::PathNode source, InsecureDownloadFlow::PathNode sink
where InsecureDownloadFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "$@ of a sensitive file from an insecure $@.",
  sink.getNode().(Sink).getDownloadCall(), "Download", source.getNode(), "HTTP source"
