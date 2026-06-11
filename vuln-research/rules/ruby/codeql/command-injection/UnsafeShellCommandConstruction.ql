/**
 * @name Ruby shell command constructed from library input
 * @description A reusable library/method builds a shell command string out of one of its
 *              parameters and later executes it. A caller passing untrusted data can inject
 *              arbitrary OS commands. Build an argument vector instead of a command string.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 6.3
 * @precision high
 * @id rb/command-injection-shell-construction
 * @tags security
 *       external/cwe/cwe-078
 *       external/cwe/cwe-088
 *       external/cwe/cwe-073
 * @vr-id RB-QL-0103
 * @source-citation inspired-by codeql/ruby-queries security/cwe-078/UnsafeShellCommandConstruction.ql
 * @license derived-original
 */

import codeql.ruby.security.UnsafeShellCommandConstructionQuery
import UnsafeShellCommandConstructionFlow::PathGraph

from
  UnsafeShellCommandConstructionFlow::PathNode source,
  UnsafeShellCommandConstructionFlow::PathNode sink, Sink sinkNode
where
  UnsafeShellCommandConstructionFlow::flowPath(source, sink) and
  sinkNode = sink.getNode()
select sinkNode.getStringConstruction(), source, sink,
  "This " + sinkNode.describe() + " which depends on $@ is later used in a $@.", source.getNode(),
  "library input", sinkNode.getCommandExecution(), "shell command"
