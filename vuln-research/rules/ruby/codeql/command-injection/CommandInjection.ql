/**
 * @name Ruby command injection from remote input
 * @description Passing attacker-controlled data into a shell command (system, exec,
 *              backticks, Open3, ...) lets a malicious user run arbitrary OS commands.
 *              Use an argument-vector form or shell-escape the input instead.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id rb/command-injection-remote-input
 * @tags security
 *       external/cwe/cwe-078
 *       external/cwe/cwe-088
 * @vr-id RB-QL-0101
 * @source-citation inspired-by codeql/ruby-queries security/cwe-078/CommandInjection.ql
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.security.CommandInjectionQuery
import CommandInjectionFlow::PathGraph

from CommandInjectionFlow::PathNode source, CommandInjectionFlow::PathNode sink, Source sourceNode
where
  CommandInjectionFlow::flowPath(source, sink) and
  sourceNode = source.getNode()
select sink.getNode(), source, sink, "This OS command depends on a $@.", sourceNode,
  sourceNode.getSourceType()
