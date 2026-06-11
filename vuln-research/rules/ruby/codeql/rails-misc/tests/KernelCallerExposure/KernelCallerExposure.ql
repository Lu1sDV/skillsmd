/**
 * @name Ruby rails-misc Kernel#caller exposure in HTTP response
 * @description Returning the result of `Kernel#caller` (the current call stack)
 *              in an HTTP response leaks internal file paths, method names and
 *              gem layout that aid an attacker in fingerprinting the application
 *              and crafting a follow-up exploit. Never expose `caller` output to
 *              clients; log it server-side instead.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/rails-misc-kernel-caller-exposure
 * @tags security
 *       external/cwe/cwe-209
 *       external/cwe/cwe-497
 * @vr-id RB-QL-2502
 * @source-citation reuses codeql.ruby.security.StackTraceExposureQuery (built-in flow module); narrows source to Kernel#caller; CWE-209/497
 * @license derived-original
 */

import codeql.ruby.DataFlow
import codeql.ruby.security.StackTraceExposureQuery
import codeql.ruby.security.StackTraceExposureCustomizations
import StackTraceExposureFlow::PathGraph

from StackTraceExposureFlow::PathNode source, StackTraceExposureFlow::PathNode sink
where
  StackTraceExposureFlow::flowPath(source, sink) and
  source.getNode() instanceof StackTraceExposure::KernelCallerCall
select sink.getNode(), source, sink, "$@ can be exposed to an external user.", source.getNode(),
  "Call stack from Kernel#caller"
