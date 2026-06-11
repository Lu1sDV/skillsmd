/**
 * @name Ruby rails-misc stack trace exposure in HTTP response
 * @description Writing exception backtrace or caller information into an HTTP
 *              response body discloses internal implementation details (file
 *              paths, gem versions, call stack) that help an attacker craft a
 *              follow-up exploit. Log the error server-side and return a generic
 *              message to the client instead.
 * @kind path-problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/rails-misc-stack-trace-exposure
 * @tags security
 *       external/cwe/cwe-209
 *       external/cwe/cwe-497
 * @vr-id RB-QL-2501
 * @source-citation reuses codeql.ruby.security.StackTraceExposureQuery (built-in flow module); CWE-209/497
 * @license derived-original
 */

import codeql.ruby.DataFlow
import codeql.ruby.security.StackTraceExposureQuery
import StackTraceExposureFlow::PathGraph

from StackTraceExposureFlow::PathNode source, StackTraceExposureFlow::PathNode sink
where StackTraceExposureFlow::flowPath(source, sink)
select sink.getNode(), source, sink, "$@ can be exposed to an external user.", source.getNode(),
  "Error information"
