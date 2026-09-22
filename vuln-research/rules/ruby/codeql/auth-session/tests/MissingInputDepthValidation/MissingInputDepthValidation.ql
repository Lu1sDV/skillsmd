/**
 * @name Ruby auth-session JSON.parse on request body without depth limit
 * @description Calling `JSON.parse` on a raw request body (`request.body.read`,
 *              `request.raw_post`, or `request.body`) without a `max_nesting:`
 *              argument allows a deeply-nested JSON payload to exhaust stack or
 *              heap memory, causing a denial-of-service. Pass `max_nesting: N`
 *              (e.g. 100) or route all JSON ingestion through a depth-validating
 *              middleware (e.g. `Gitlab::Middleware::JsonValidation`).
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-missing-input-depth-validation
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-1318
 * @source-citation derived from GitLab security fix 34d5290482e7 (add JsonValidation middleware to cap JSON depth); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `recv` is the bare `JSON` constant (not scoped under another module).
 */
predicate isBareJsonConstant(ConstantReadAccess recv) {
  recv.getName() = "JSON" and
  not exists(recv.getScopeExpr())
}

/**
 * Holds if `arg` is a call that reads raw bytes from a Rack/Rails request —
 * i.e. the call chain ends in `.read`, `.raw_post`, or is `request.body` itself.
 * We look one level deep: `request.body.read`, `request.raw_post`, or just
 * `request.body` as the argument.
 */
predicate isRequestBodyRead(Expr arg) {
  // request.body.read  OR  request.raw_post
  exists(MethodCall outer |
    outer = arg and
    outer.getMethodName() = ["read", "raw_post"] and
    // The receiver is either `request` or `request.body`
    (
      outer.getReceiver().(MethodCall).getMethodName() = ["request", "body"] or
      outer.getReceiver().(MethodCall).getMethodName() = "request"
    )
  )
  or
  // request.body  (passed directly without .read)
  exists(MethodCall bodyCall |
    bodyCall = arg and
    bodyCall.getMethodName() = "body" and
    bodyCall.getReceiver().(MethodCall).getMethodName() = "request"
  )
}

from MethodCall c
where
  // JSON.parse(...)
  c.getMethodName() = "parse" and
  isBareJsonConstant(c.getReceiver().(ConstantReadAccess)) and
  // First argument reads directly from the request body
  isRequestBodyRead(c.getArgument(0)) and
  // No max_nesting: keyword argument supplied
  not exists(c.getKeywordArgument("max_nesting"))
select c,
  "JSON.parse on request body without `max_nesting:` limit; a deeply-nested payload can exhaust memory (DoS). Pass `max_nesting: 100` or use a depth-validating middleware."
