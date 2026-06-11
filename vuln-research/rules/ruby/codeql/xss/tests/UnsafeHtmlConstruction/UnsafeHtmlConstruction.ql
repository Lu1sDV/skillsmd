/**
 * @name Ruby unsafe HTML construction from library input
 * @description Building HTML markup by concatenating or interpolating externally
 *              controlled strings produces fragments that can later carry an XSS
 *              payload when handed to a rendering sink.
 * @kind path-problem
 * @problem.severity error
 * @precision high
 * @id rb/xss-unsafe-html-construction
 * @tags security
 *       external/cwe/cwe-079
 *       external/cwe/cwe-116
 * @vr-id RB-QL-0803
 * @source-citation inspired-by codeql rb/html-constructed-from-input; reuses UnsafeHtmlConstructionFlow module
 * @license derived-original
 */

import codeql.ruby.security.UnsafeHtmlConstructionQuery
import UnsafeHtmlConstructionFlow::PathGraph

from
  UnsafeHtmlConstructionFlow::PathNode source, UnsafeHtmlConstructionFlow::PathNode sink,
  Sink sinkNode
where UnsafeHtmlConstructionFlow::flowPath(source, sink) and sink.getNode() = sinkNode
select sinkNode, source, sink,
  "Unsafe HTML construction: this " + sinkNode.getSinkType() +
    " built from $@ may later enable $@.", source.getNode(), "library input",
  sinkNode.getXssSink(), "cross-site scripting"
