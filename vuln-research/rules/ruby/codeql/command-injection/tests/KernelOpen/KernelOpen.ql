/**
 * @name Ruby command execution via Kernel.open / IO sinks
 * @description Passing attacker-controlled data to Kernel#open, IO.read, IO.write or
 *              URI.open is dangerous: a leading "|" turns the argument into a shell
 *              command. Validate the path or use File.open, which never spawns a process.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id rb/command-injection-kernel-open
 * @tags security
 *       external/cwe/cwe-078
 *       external/cwe/cwe-088
 *       external/cwe/cwe-073
 * @vr-id RB-QL-0102
 * @source-citation inspired-by codeql/ruby-queries security/cwe-078/KernelOpen.ql
 * @license derived-original
 */

import codeql.ruby.DataFlow
import codeql.ruby.security.KernelOpenQuery
import KernelOpenFlow::PathGraph

from
  KernelOpenFlow::PathNode source, KernelOpenFlow::PathNode sink, DataFlow::Node sourceNode,
  DataFlow::CallNode call
where
  KernelOpenFlow::flowPath(source, sink) and
  sourceNode = source.getNode() and
  call.getArgument(0) = sink.getNode()
select sink.getNode(), source, sink,
  "This call to " + call.(AmbiguousPathCall).getName() + " depends on a $@.", sourceNode,
  "user-provided value"
