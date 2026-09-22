/**
 * @name Service or Finder execute method missing can? authorization check
 * @description An `execute` method in a `*Service`, `*Finder`, or GraphQL `*Resolver`
 *              class calls a mutating ActiveRecord operation (save/destroy/create/update/delete/rotate)
 *              while referencing `current_user` but never calling `can?(current_user, ...)` or
 *              `Ability.allowed?(current_user, ...)`. An unauthorized caller can trigger
 *              the mutation. Add a `can?(current_user, :permission, resource)` guard before
 *              the mutating call or raise `Gitlab::Access::AccessDeniedError`.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/auth-session-missing-can-check-in-service
 * @tags security
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1326
 * @source-citation derived from GitLab security fix 922a6e081456 (Issues::RelatedBranchesService missing can? guard), caff25a44006 (ErrorTracking::ListProjectsService missing can? guard); CWE-862
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A class whose name ends with Service, Finder, or Resolver.
 */
class ServiceLikeClass extends ClassDeclaration {
  ServiceLikeClass() {
    this.getName().matches("%Service") or
    this.getName().matches("%Finder") or
    this.getName().matches("%Resolver")
  }
}

/**
 * An `execute` method defined directly inside a ServiceLikeClass.
 */
class ExecuteMethod extends Method {
  ExecuteMethod() {
    this.getName() = "execute" and
    exists(ServiceLikeClass c | c.getAMethod() = this)
  }
}

/**
 * A mutating ActiveRecord method call inside a method.
 */
class MutatingCall extends MethodCall {
  MutatingCall() {
    this.getMethodName() =
      ["save", "save!", "destroy", "destroy!", "create", "create!", "update", "update!",
       "delete", "delete!", "delete_all", "rotate", "rotate!", "update_all", "insert", "insert!",
       "upsert", "upsert_all"]
  }
}

/**
 * A reference to the `current_user` local variable or method.
 */
predicate referencesCurrentUser(ExecuteMethod m) {
  exists(MethodCall cu |
    cu.getMethodName() = "current_user" and
    cu.getEnclosingCallable() = m
  )
  or
  exists(LocalVariableReadAccess v |
    v.getVariable().getName() = "current_user" and
    v.getEnclosingCallable() = m
  )
}

/**
 * A `can?` call with `current_user` as the first argument inside a method.
 */
predicate hasCanCheck(ExecuteMethod m) {
  exists(MethodCall can |
    can.getMethodName() = "can?" and
    can.getEnclosingCallable() = m and
    (
      can.getArgument(0).(MethodCall).getMethodName() = "current_user" or
      can.getArgument(0).(LocalVariableReadAccess).getVariable().getName() = "current_user"
    )
  )
}

/**
 * An `Ability.allowed?` call with `current_user` as the first argument inside a method.
 */
predicate hasAbilityAllowedCheck(ExecuteMethod m) {
  exists(MethodCall allowed |
    allowed.getMethodName() = "allowed?" and
    allowed.getReceiver().(ConstantReadAccess).getName() = "Ability" and
    allowed.getEnclosingCallable() = m and
    (
      allowed.getArgument(0).(MethodCall).getMethodName() = "current_user" or
      allowed.getArgument(0).(LocalVariableReadAccess).getVariable().getName() = "current_user"
    )
  )
}

from ExecuteMethod m, MutatingCall mut, ServiceLikeClass cls
where
  cls.getAMethod() = m and
  mut.getEnclosingCallable() = m and
  referencesCurrentUser(m) and
  not hasCanCheck(m) and
  not hasAbilityAllowedCheck(m)
select mut,
  "The `execute` method of " + cls.getName() +
  " calls `" + mut.getMethodName() +
  "` but has no `can?(current_user, ...)` or `Ability.allowed?(current_user, ...)` authorization check; add an authz guard before mutating."
