/**
 * @name Ruby auth-session GraphQL resolver or mutation missing Ability check
 * @description A GraphQL resolver or mutation defines a `resolve` method that
 *              performs a sensitive data operation (find, execute, save, update,
 *              or destroy) but contains no authorization guard
 *              (`Ability.allowed?`, `authorize!`, `raise_resource_not_available_error!`,
 *              or a declarative `authorize`/`read_ability` call) in the same method.
 *              An unauthenticated or under-privileged caller can invoke the resolver
 *              and access or mutate protected data. Add
 *              `return unless Ability.allowed?(current_user, :permission, resource)`
 *              (or `raise_resource_not_available_error!`) at the top of `resolve`.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id rb/auth-session-graphql-resolver-missing-ability-check
 * @tags security
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1311
 * @source-citation derived from GitLab auth-session graphql-resolver missing-authz fixes (shas 32836e4faf7a,fab77c4ecd4a,1b19c469feb7); CWE-862
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` is a GraphQL resolver or mutation class by naming convention.
 * Matches classes whose name ends in `Resolver` or `Mutation`.
 */
private predicate isGraphqlResolverOrMutationClass(ClassDeclaration cls) {
  cls.getName().matches("%Resolver") or
  cls.getName().matches("%Mutation")
}

/**
 * Holds if `call` is a sensitive data operation — a method call whose name
 * indicates record retrieval or mutation.
 */
private predicate isSensitiveOp(MethodCall call) {
  call.getMethodName() =
    ["find", "find_by", "execute", "save", "save!", "update", "update!", "destroy", "destroy!"]
}

/**
 * Holds if `guard` is an authorization guard call in the same enclosing
 * callable as `resolve`.
 */
private predicate isAuthzGuard(MethodCall guard) {
  guard.getMethodName() =
    [
      "allowed?", "authorize!", "raise_resource_not_available_error!", "authorize",
      "read_ability"
    ]
}

from Method resolve, MethodCall sensitiveOp
where
  // The method is named `resolve`
  resolve.getName() = "resolve" and
  // It belongs to a Resolver or Mutation class
  isGraphqlResolverOrMutationClass(resolve.getEnclosingModule()) and
  // The method body contains a sensitive data operation
  sensitiveOp.getEnclosingCallable() = resolve and
  isSensitiveOp(sensitiveOp) and
  // No authorization guard call exists anywhere in the same resolve method
  not exists(MethodCall guard |
    isAuthzGuard(guard) and
    guard.getEnclosingCallable() = resolve
  )
select sensitiveOp,
  "GraphQL resolver/mutation `resolve` method calls `" + sensitiveOp.getMethodName() +
    "` without an `Ability.allowed?`, `authorize!`, or `raise_resource_not_available_error!` guard; add an authorization check before the sensitive operation."
