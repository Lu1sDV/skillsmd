/**
 * @name Sensitive data written to application logs
 * @description Logging raw user_id values or unfiltered Sidekiq job arguments
 *              can expose PII and confidential issue content in log storage.
 *              Remove user_id from AppLogger calls; filter Sidekiq job args
 *              through SidekiqProcessor.loggable_arguments before logging.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision high
 * @id rb/rails-misc-sensitive-data-in-logs
 * @tags security
 *       external/cwe/cwe-532
 *       external/cwe/cwe-200
 * @vr-id RB-QL-2517
 * @source-citation derived from GitLab security fixes 108d2fc0 (user_id in pipeline log) and 441a5d30 (Sidekiq args without loggable_arguments); CWE-532/200
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Case 1: AppLogger.info / AppLogger.warn / AppLogger.error called with a
 * `user_id:` keyword argument.  The fix removes the keyword argument.
 */
predicate appLoggerWithUserId(MethodCall c, string msg) {
  c.getReceiver().(ConstantReadAccess).getName() = "AppLogger" and
  c.getMethodName() = ["info", "warn", "error", "debug"] and
  exists(c.getKeywordArgument("user_id")) and
  msg =
    "AppLogger." + c.getMethodName() +
      " passes a raw user_id: keyword argument; remove user_id from the log call to prevent PII exposure."
}

/**
 * Case 2: A Sidekiq middleware logger.info call that dumps job['args'] directly
 * (via string interpolation containing a dump of the args array) without a
 * loggable_arguments guard anywhere in the same callable.
 */
predicate sidekiqArgsWithoutScrubbing(MethodCall c, string msg) {
  // The call is logger.info (implicit or explicit receiver)
  c.getMethodName() = "info" and
  // Must be inside a `call` method (Sidekiq middleware convention)
  exists(Method m |
    m.getName() = "call" and
    c.getEnclosingCallable() = m
  ) and
  // The argument string-interpolates job['args'] via a dump call without loggable_arguments
  exists(StringlikeLiteral s, StringInterpolationComponent interp, MethodCall dump,
    ElementReference ref |
    s = c.getAnArgument() and
    interp = s.getComponent(_) and
    dump = interp.getAStmt().(MethodCall) and
    dump.getMethodName() = ["dump", "generate", "to_json"] and
    ref = dump.getAnArgument() and
    ref.getArgument(0).(StringLiteral).getConstantValue().getString() = "args"
  ) and
  // No loggable_arguments call in the same callable
  not exists(MethodCall guard |
    guard.getMethodName() = "loggable_arguments" and
    guard.getEnclosingCallable() = c.getEnclosingCallable()
  ) and
  msg =
    "Sidekiq job arguments are logged without filtering through loggable_arguments; " +
      "confidential issue content or PII may appear in logs."
}

from MethodCall c, string msg
where
  appLoggerWithUserId(c, msg) or
  sidekiqArgsWithoutScrubbing(c, msg)
select c, msg
