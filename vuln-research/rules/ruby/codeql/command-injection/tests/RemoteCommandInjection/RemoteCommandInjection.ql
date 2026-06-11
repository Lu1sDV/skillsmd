/**
 * @name Ruby OS command injection from an HTTP request
 * @description An HTTP request parameter, header or body value flows into an OS command
 *              sink (system, exec, backticks, Open3, ...). This is directly reachable by a
 *              remote attacker. Pass the input as a separate argument or shell-escape it.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 9.8
 * @precision high
 * @id rb/command-injection-http-request
 * @tags security
 *       external/cwe/cwe-078
 *       external/cwe/cwe-088
 * @vr-id RB-QL-0104
 * @source-citation derived-original; reuses codeql.ruby.security.CommandInjectionCustomizations Sink + RemoteFlowSource
 * @license derived-original
 */

import codeql.ruby.AST
import codeql.ruby.DataFlow
import codeql.ruby.TaintTracking
import codeql.ruby.dataflow.RemoteFlowSources
import codeql.ruby.security.CommandInjectionCustomizations

private module RemoteCommandConfig implements DataFlow::ConfigSig {
  predicate isSource(DataFlow::Node source) { source instanceof RemoteFlowSource }

  predicate isSink(DataFlow::Node sink) { sink instanceof CommandInjection::Sink }

  predicate isBarrier(DataFlow::Node node) { node instanceof CommandInjection::Sanitizer }
}

module RemoteCommandFlow = TaintTracking::Global<RemoteCommandConfig>;

import RemoteCommandFlow::PathGraph

from RemoteCommandFlow::PathNode source, RemoteCommandFlow::PathNode sink
where RemoteCommandFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "This OS command depends on an $@.", source.getNode(),
  "HTTP request value"
