/**
 * @name Grape::Entity expose of sensitive association without permission check
 * @description A `Grape::Entity` subclass exposes a security-sensitive field
 *              (pipeline, trace, token, or job_token) behind an `if:` lambda
 *              that checks only data presence, not the caller's permission to
 *              read the associated resource. Any user who can read the parent
 *              object also receives the sensitive nested data. Add an
 *              `Ability.allowed?(opts[:user], :read_X, obj.project)` guard
 *              inside the `if:` lambda, or remove the field.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-rm-005
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-2514
 * @source-citation derived from GitLab security fixes 4acfdd18c5aa,547cdf137a46,8d5517e8a205 (Grape::Entity expose pipeline/trace without Ability.allowed? guard); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` is a subclass of `Grape::Entity` or any common
 * GitLab-style base entity that itself extends `Grape::Entity`.
 * We keep this intentionally broad: any superclass named `*Entity` is
 * treated as a Grape entity so we don't need to resolve the full constant
 * hierarchy. Teams that subclass their own `BaseEntity < Grape::Entity`
 * still get coverage.
 */
predicate isGrapeEntitySubclass(ClassDeclaration cls) {
  exists(ConstantReadAccess superExpr |
    superExpr = cls.getSuperclassExpr() and
    (
      // Direct: class Foo < Grape::Entity  (getName() = "Entity", scope = Grape)
      superExpr.getName() = "Entity"
      or
      // Qualified: class Foo < API::Entities::BaseEntity or similar *Entity names
      superExpr.getName().matches("%Entity%")
    )
  )
}

/**
 * Sensitive field names whose exposure without a permission check is a
 * finding. Derived directly from the GitLab fix corpus.
 */
predicate isSensitiveFieldName(string name) {
  name = ["pipeline", "pipelines", "trace", "token", "job_token", "build_token"]
}

/**
 * Holds if `inner` is anywhere inside the subtree rooted at `outer`.
 * Used to check that a permission-guard call is within the if: lambda.
 */
predicate isDescendantOf(AstNode inner, AstNode outer) {
  inner.getParent() = outer
  or
  isDescendantOf(inner.getParent(), outer)
}

/**
 * Holds if `lambda` contains a call to `Ability.allowed?` or `can?`,
 * indicating the developer has added a permission guard.
 */
predicate hasPermissionGuard(Lambda lambda) {
  exists(MethodCall guard |
    isDescendantOf(guard, lambda) and
    (
      // Ability.allowed?(...)
      guard.getMethodName() = "allowed?" and
      guard.getReceiver().(ConstantReadAccess).getName() = "Ability"
      or
      // Declarative: can?(...) — used by CanCan / custom helpers
      guard.getMethodName() = "can?"
      or
      // Direct: can_read_pipeline? helper introduced in the fix
      guard.getMethodName().matches("can_read_%")
    )
  )
}

from MethodCall expose, string fieldName, Lambda ifLambda
where
  expose.getMethodName() = "expose" and
  // First positional arg is a symbol for a sensitive field
  fieldName =
    expose.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() and
  isSensitiveFieldName(fieldName) and
  // Has an if: keyword argument that is a Lambda
  ifLambda = expose.getKeywordArgument("if").(Lambda) and
  // The if: lambda does NOT contain an Ability/can? permission check
  not hasPermissionGuard(ifLambda) and
  // Scoped to a Grape::Entity subclass (or any *Entity* subclass)
  exists(ClassDeclaration cls |
    isGrapeEntitySubclass(cls) and
    expose.getEnclosingModule() = cls
  )
select expose,
  "Grape::Entity exposes `:" + fieldName +
    "` behind an `if:` lambda that checks only data presence, not the caller's " +
    "permission to read this resource. Add `Ability.allowed?(opts[:user], :read_" +
    fieldName + ", obj.project)` to the `if:` lambda to prevent unauthorized disclosure."
