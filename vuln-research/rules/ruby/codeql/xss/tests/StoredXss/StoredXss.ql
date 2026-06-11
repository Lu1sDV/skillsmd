/**
 * @name Ruby stored cross-site scripting from persisted values
 * @description Values read back from persistent storage (database, file) and rendered
 *              into HTML without escaping let a previously stored payload execute in
 *              every viewer's browser.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/xss-stored-render
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 * @vr-id RB-QL-0802
 * @source-citation inspired-by codeql rb/stored-xss; reuses StoredXssFlow module
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.StoredXSSQuery
import StoredXssFlow::PathGraph

from StoredXssFlow::PathNode source, StoredXssFlow::PathNode sink
where StoredXssFlow::flowPath(source, sink)
select sink.getNode(), source, sink,
  "Stored XSS: a persisted $@ is rendered into HTML without escaping.", source.getNode(),
  "stored value"
