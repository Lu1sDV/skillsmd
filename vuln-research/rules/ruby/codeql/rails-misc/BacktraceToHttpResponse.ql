/**
 * @name Ruby rails-misc exception backtrace exposure in HTTP response
 * @description Rendering the `backtrace` (or `backtrace_locations`) of a rescued
 *              exception into an HTTP response body reveals absolute file paths,
 *              line numbers and the gem call chain, giving an attacker a precise
 *              map of the deployment. Log the backtrace server-side and return a
 *              generic error to the client.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/rails-misc-backtrace-http-response
 * @tags security
 *       external/cwe/cwe-209
 *       external/cwe/cwe-497
 * @vr-id RB-QL-2503
 * @source-citation reuses codeql.ruby.security.StackTraceExposureQuery (built-in flow module); narrows source to rescued-exception backtrace; CWE-209/497
 * @license derived-original
 */

import codeql.ruby.DataFlow
import codeql.ruby.security.StackTraceExposureQuery
import codeql.ruby.security.StackTraceExposureCustomizations
import StackTraceExposureFlow::PathGraph

from StackTraceExposureFlow::PathNode source, StackTraceExposureFlow::PathNode sink
where
  StackTraceExposureFlow::flowPath(source, sink) and
  source.getNode() instanceof StackTraceExposure::BacktraceCall
select sink.getNode(), source, sink, "$@ can be exposed to an external user.", source.getNode(),
  "Exception backtrace"
