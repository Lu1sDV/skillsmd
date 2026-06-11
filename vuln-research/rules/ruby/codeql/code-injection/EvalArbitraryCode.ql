/**
 * @name Ruby arbitrary code execution via eval-family sink
 * @description Passing untrusted input to a call that evaluates its argument as arbitrary Ruby
 *              code (eval, instance_eval, class_eval, module_eval) yields remote code execution.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id rb/code-injection-eval-arbitrary
 * @tags security
 *       external/cwe/cwe-094
 *       external/cwe/cwe-095
 * @vr-id RB-QL-0203
 * @source-citation inspired-by codeql ruby cwe-094/CodeInjection.ql; restricts CodeInjectionFlow to arbitrary-code sinks
 * @license derived-original
 */

private import codeql.ruby.AST
private import codeql.ruby.Concepts
import codeql.ruby.security.CodeInjectionQuery
import CodeInjectionFlow::PathGraph

/** A code-injection sink whose call evaluates its argument as fully arbitrary Ruby code. */
predicate isArbitraryCodeSink(CodeInjectionFlow::PathNode sink) {
  exists(CodeExecution c | c.runsArbitraryCode() and c.getCode() = sink.getNode())
}

from CodeInjectionFlow::PathNode source, CodeInjectionFlow::PathNode sink
where CodeInjectionFlow::flowPath(source, sink) and isArbitraryCodeSink(sink)
select sink.getNode(), source, sink,
  "Arbitrary Ruby code execution depends on a $@.", source.getNode(), "user-provided value"
