/**
 * @name CI job token used without scope guard
 * @description A method authenticates via a CI job token
 *              (`authenticate_jobtoken!` / `authenticate_job_token!`) but does not
 *              call a CI-job-token scope guard (`project_allowed_for_job_token?`,
 *              `allowed_for_job_token?`, or `scoped_to?`) anywhere in the same
 *              callable. A token issued for project A can therefore reach resources
 *              in project B when the inbound-scope feature is enabled. Add a
 *              scope guard or raise `forbidden!` for out-of-scope requests.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/auth-session-ci-job-token-scope-bypass
 * @tags security
 *       external/cwe/cwe-863
 * @vr-id RB-QL-1322
 * @source-citation derived from GitLab security fix 2aa664777ba2 (Hide private project name to unauthorized users); CWE-863
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `auth` is a CI-job-token authentication call.
 * Covers `authenticate_jobtoken!`, `authenticate_job_token!`, and
 * `authenticate_job_token_with_user_token!`.
 */
predicate isJobTokenAuth(MethodCall auth) {
  auth.getMethodName() =
    ["authenticate_jobtoken!", "authenticate_job_token!", "authenticate_job_token_with_user_token!"]
}

/**
 * Holds if `guard` is a CI-job-token scope-check call.
 * Covers the three guard names seen in GitLab fixes.
 */
predicate isJobTokenScopeGuard(MethodCall guard) {
  guard.getMethodName() = ["project_allowed_for_job_token?", "allowed_for_job_token?", "scoped_to?"]
}

from MethodCall auth
where
  isJobTokenAuth(auth) and
  // No scope guard exists anywhere in the same enclosing callable
  not exists(MethodCall guard |
    isJobTokenScopeGuard(guard) and
    guard.getEnclosingCallable() = auth.getEnclosingCallable()
  )
select auth,
  "CI job token authenticated via `" + auth.getMethodName() +
    "` without a scope guard (`project_allowed_for_job_token?`, `allowed_for_job_token?`, or `scoped_to?`) " +
    "in this method; a token from another project may access this resource. " +
    "Add a scope check or raise `forbidden!` for out-of-scope requests."
