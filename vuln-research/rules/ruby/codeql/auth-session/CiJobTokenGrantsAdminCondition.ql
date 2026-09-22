/**
 * @name CI job token actor satisfies :admin DeclarativePolicy condition without guard
 * @description A `condition(:admin)` or `condition(:is_admin)` block in a BasePolicy
 *              subclass calls an admin-mode check (`admin_mode?` or `admin?`) without
 *              first checking `from_ci_job_token?`. A CI job token whose underlying user
 *              is an instance admin will inherit admin-level permissions. Add
 *              `next false if @user&.from_ci_job_token?` as the first statement in the
 *              condition block to short-circuit for job-token callers.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.6
 * @precision high
 * @id rb/auth-session-ci-job-token-grants-admin-condition
 * @tags security
 *       external/cwe/cwe-269
 * @vr-id RB-QL-1321
 * @source-citation derived from GitLab security fix f5e8c0286f02 (Return for admin condition if user authentication with job token); CWE-269
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `condCall` is a `condition(:admin)` or `condition(:is_admin)` DSL call
 * that has an associated block.
 */
predicate isAdminConditionDecl(MethodCall condCall) {
  condCall.getMethodName() = "condition" and
  condCall.hasBlock() and
  condCall.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() =
    ["admin", "is_admin"]
}

/**
 * Holds if `mc` is any descendant call inside `condCall`'s block.
 */
predicate isCallInConditionBlock(MethodCall condCall, MethodCall mc) {
  condCall.getBlock().getAChild*() = mc
}

from MethodCall condCall
where
  isAdminConditionDecl(condCall) and
  // The block calls an admin-mode predicate (the vulnerable evaluation)
  exists(MethodCall adminCheck |
    isCallInConditionBlock(condCall, adminCheck) and
    adminCheck.getMethodName() = ["admin_mode?", "admin?"]
  ) and
  // The block does NOT call from_ci_job_token? anywhere
  not exists(MethodCall guard |
    isCallInConditionBlock(condCall, guard) and
    guard.getMethodName() = "from_ci_job_token?"
  )
select condCall,
  "The `:" + condCall.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() +
    "` DeclarativePolicy condition checks admin-mode without a `from_ci_job_token?` guard; " +
    "a CI job-token actor whose user is an instance admin inherits admin permissions. " +
    "Add `next false if @user&.from_ci_job_token?` as the first statement in the condition block."
