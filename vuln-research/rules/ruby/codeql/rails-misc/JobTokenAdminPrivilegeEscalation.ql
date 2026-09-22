/**
 * @name CI job token enables admin/manage-level policy rule without from_ci_job_token? guard
 * @description A DeclarativePolicy `rule` block enables an admin- or manage-level ability
 *              (`:admin_*` or `:manage_*`) in a class that never calls `from_ci_job_token?`
 *              in any condition block. A CI job token whose underlying user is an instance
 *              admin can satisfy the associated condition and inherit privileged permissions.
 *              Fix: add `next false if @user&.from_ci_job_token?` at the top of every
 *              condition block that gates admin-level rules.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision medium
 * @id rb/rails-misc-job-token-admin-privilege-escalation
 * @tags security
 *       external/cwe/cwe-269
 * @vr-id RB-QL-2523
 * @source-citation derived from GitLab security fix b21f2bd4 (Remove FF prevent_job_token_admin_permissions); CWE-269
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `enableCall` is a `rule { ... }.enable :admin_*` or `.enable :manage_*` DSL
 * call inside a DeclarativePolicy-style class body.
 */
predicate isAdminEnableCall(MethodCall enableCall) {
  enableCall.getMethodName() = "enable" and
  exists(SymbolLiteral sym |
    sym = enableCall.getAnArgument() and
    (
      sym.getConstantValue().getSymbol().matches("admin_%") or
      sym.getConstantValue().getSymbol().matches("manage_%") or
      sym.getConstantValue().getSymbol() = ["admin", "manage"]
    )
  )
}

/**
 * Holds if `cls` is a class whose body contains a `from_ci_job_token?` call inside
 * any `condition` block — i.e. the class has at least one guarded condition.
 */
predicate classHasJobTokenGuard(ClassDeclaration cls) {
  exists(MethodCall condCall, MethodCall guard |
    condCall.getMethodName() = "condition" and
    condCall.hasBlock() and
    condCall.getEnclosingModule() = cls and
    condCall.getBlock().getAChild*() = guard and
    guard.getMethodName() = "from_ci_job_token?"
  )
}

from MethodCall enableCall, ClassDeclaration cls
where
  isAdminEnableCall(enableCall) and
  cls = enableCall.getEnclosingModule() and
  // The class inherits from a DeclarativePolicy base (heuristic: has at least one `condition` DSL call)
  exists(MethodCall cond |
    cond.getMethodName() = "condition" and
    cond.hasBlock() and
    cond.getEnclosingModule() = cls
  ) and
  // No condition block in this class guards against CI job tokens
  not classHasJobTokenGuard(cls)
select enableCall,
  "Rule enables `" +
    enableCall.getAnArgument().(SymbolLiteral).getConstantValue().getSymbol() +
    "` in a policy class with no `from_ci_job_token?` guard in any condition block; " +
    "a CI job-token caller whose user is an admin inherits this privileged ability. " +
    "Add `next false if @user&.from_ci_job_token?` to the relevant condition block."
