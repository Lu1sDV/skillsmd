/**
 * @name Ruby code injection from remote input
 * @description Evaluating a string built from untrusted, externally controlled input as Ruby
 *              source code lets an attacker run arbitrary code in the process.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.3
 * @precision high
 * @id rb/code-injection-remote-flow
 * @tags security
 *       external/cwe/cwe-094
 *       external/cwe/cwe-095
 * @vr-id RB-QL-0201
 * @source-citation inspired-by codeql ruby cwe-094/CodeInjection.ql; reuses CodeInjectionFlow
 * @license derived-original
 */

private import codeql.ruby.AST
import codeql.ruby.security.CodeInjectionQuery
import CodeInjectionFlow::PathGraph

from CodeInjectionFlow::PathNode source, CodeInjectionFlow::PathNode sink
where CodeInjectionFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "Ruby code execution depends on a $@.", source.getNode(),
  "user-provided value"
