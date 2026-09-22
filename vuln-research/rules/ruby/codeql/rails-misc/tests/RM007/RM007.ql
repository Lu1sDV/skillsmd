/**
 * @name Unfiltered request path logged (token/secret leak via fullpath)
 * @description Passing `request.fullpath` directly to a structured logger records
 *              query-string parameters — including tokens like `?private_token=` or
 *              `?access_token=` — in plaintext in log aggregators (e.g. Kibana).
 *              Replace `request.fullpath` with `request.filtered_path` so Rails
 *              applies the `config.filter_parameters` ruleset before writing to logs.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision high
 * @id rb/rails-misc-rm-007
 * @tags security
 *       external/cwe/cwe-532
 * @vr-id RB-QL-2519
 * @source-citation derived from GitLab security fix abf144507aff (hide private_token from logs/Kibana); CWE-532
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `call` is a structured-logger invocation: a call to a
 * logging-level method (`error`, `warn`, `info`, `debug`, `log`, `add`,
 * `fatal`) where the receiver is either a plain identifier (`logger`,
 * `Rails.logger`, `Gitlab::AuthLogger`, etc.) or any method/constant chain.
 */
predicate isLoggerCall(MethodCall call) {
  call.getMethodName() = ["error", "warn", "warning", "info", "debug", "fatal", "log", "add"]
}

/**
 * Holds if `fullpath` is a call to `request.fullpath`.
 */
predicate isRequestFullpath(MethodCall fullpath) {
  fullpath.getMethodName() = "fullpath" and
  fullpath.getReceiver().(MethodCall).getMethodName() = "request"
  or
  fullpath.getMethodName() = "fullpath" and
  fullpath.getReceiver().(SelfVariableAccess).toString() = "self"
  or
  // bare `request` local variable / method call with no explicit receiver
  fullpath.getMethodName() = "fullpath" and
  fullpath.getReceiver().(VariableReadAccess).getVariable().getName() = "request"
}

from MethodCall logCall, Pair pair, MethodCall fullpath
where
  isLoggerCall(logCall) and
  pair = logCall.getAnArgument() and
  fullpath = pair.getValue() and
  isRequestFullpath(fullpath)
select fullpath,
  "request.fullpath passed to a logger leaks query-string tokens (e.g. ?private_token=, ?access_token=) in plaintext. Replace with request.filtered_path."
