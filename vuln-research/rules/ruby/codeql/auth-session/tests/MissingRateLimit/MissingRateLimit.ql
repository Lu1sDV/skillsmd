/**
 * @name Authentication or import endpoint lacks rate limiting
 * @description A controller action that performs authentication, password
 *              reset, or token validation has no `check_rate_limit!` call in
 *              the method body or attached via `before_action`. Without rate
 *              limiting, an attacker can brute-force credentials or trigger
 *              expensive operations at will. Add
 *              `check_rate_limit!(:key, scope: [ip])` at the start of the
 *              action or as a `before_action` lambda.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id rb/auth-session-missing-rate-limit
 * @tags security
 *       external/cwe/cwe-307
 * @vr-id RB-QL-1313
 * @source-citation derived from GitLab security fix 4b98496b4ab3 (gitea import rate limiting), 2bc1a70de269 (repositories changelog rate limiting); CWE-307
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `m` is a controller action method (named in a set of sensitive
 * auth/import/token action names) that contains a call signalling it handles
 * authentication or credential lookups.
 */
predicate isSensitiveAuthAction(Method m) {
  // Method name is in the sensitive set that auth/rate-limit fixes target.
  m.getName() =
    ["create", "authenticate", "login", "sign_in", "token", "password",
     "reset_password", "status", "import", "update_password"] and
  // The method body calls something that implies credential processing.
  exists(MethodCall c |
    c.getEnclosingCallable() = m and
    c.getMethodName() =
      ["authenticate_user!", "find_by_login", "find_by_token",
       "find_by_authentication_token", "find_by_reset_password_token",
       "with_reset_password_token", "sign_in", "devise_token_auth_check!",
       "find_by_email_and_password", "resource_from_credentials",
       "authenticate_with_http_token", "authenticate_with_http_basic"]
  )
}

/**
 * Holds if callable `c` contains a `check_rate_limit!` call directly.
 */
predicate hasDirectRateLimit(Callable c) {
  exists(MethodCall rl |
    rl.getEnclosingCallable() = c and
    rl.getMethodName() = "check_rate_limit!"
  )
}

/**
 * Holds if the class `cls` has a `before_action` (or `before_filter`) call
 * whose lambda/block argument contains a `check_rate_limit!` call.
 * This covers `before_action -> { check_rate_limit!(...) }` patterns.
 */
predicate hasBeforeActionRateLimit(ClassDeclaration cls) {
  exists(MethodCall ba, Callable inner, MethodCall rl |
    ba.getEnclosingModule() = cls and
    ba.getMethodName() = ["before_action", "before_filter"] and
    // The argument may be a Lambda (-> { }) or a Block (do...end / { })
    inner = ba.getAnArgument() and
    rl.getEnclosingCallable() = inner and
    rl.getMethodName() = "check_rate_limit!"
  )
}

from Method m
where
  isSensitiveAuthAction(m) and
  not hasDirectRateLimit(m) and
  not hasBeforeActionRateLimit(m.getEnclosingModule().(ClassDeclaration))
select m,
  "Method '" + m.getName() +
    "' performs authentication or credential lookup without a `check_rate_limit!` " +
    "call; add rate limiting to prevent brute-force or enumeration attacks (CWE-307)."
