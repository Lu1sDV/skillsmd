/**
 * @name Grape API endpoint allows unauthenticated write requests
 * @description A Grape `::API::Base` subclass defines a non-GET route
 *              (POST, PUT, DELETE, or PATCH) but has no `before` hook calling
 *              `authenticate!` or `authenticate_non_get!` in the same class
 *              body. Anonymous users can reach the endpoint and perform
 *              state-changing operations. Fix by adding
 *              `before { authenticate_non_get! }` at the class level.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-api-endpoint-unauthenticated-write
 * @tags security
 *       external/cwe/cwe-306
 * @vr-id RB-QL-1315
 * @source-citation derived from GitLab security fix d19cd4411212 (Prevent anonymous users from creating uploads); CWE-306
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` is a Grape API class — it inherits directly from `::API::Base`
 * (the leaf name is `"Base"`) or its own name follows the Grape resource naming
 * pattern. Using the leaf-name proxy is standard for this codebase since Ruby AST
 * does not resolve fully-qualified superclass names across files.
 */
private predicate isGrapeApiClass(ClassDeclaration cls) {
  cls.getSuperclassExpr().(ConstantReadAccess).getName() = "Base"
}

/**
 * Holds if `verb` is a Grape non-GET route declaration in class `cls`:
 * a `post`/`put`/`delete`/`patch` call whose first argument is a string
 * (the route path), located directly inside `cls`.
 */
private predicate isNonGetRouteCall(MethodCall verb, ClassDeclaration cls) {
  verb.getMethodName() = ["post", "put", "delete", "patch"] and
  exists(verb.getArgument(0).(StringLiteral)) and
  verb.getEnclosingModule() = cls
}

/**
 * Holds if `cls` has a `before` hook containing `authenticate!` or
 * `authenticate_non_get!`. The hook is a MethodCall named `before` with
 * a Block body; the body must contain a call to the auth method.
 */
private predicate hasAuthBeforeHook(ClassDeclaration cls) {
  exists(MethodCall beforeHook, Block blk, MethodCall authCall |
    beforeHook.getMethodName() = "before" and
    beforeHook.getEnclosingModule() = cls and
    blk = beforeHook.getBlock() and
    blk.getAChild*() = authCall and
    authCall.getMethodName() = ["authenticate!", "authenticate_non_get!"]
  )
}

from MethodCall verb, ClassDeclaration cls
where
  isGrapeApiClass(cls) and
  isNonGetRouteCall(verb, cls) and
  not hasAuthBeforeHook(cls)
select verb,
  "Grape API endpoint `" + verb.getMethodName() +
    "` in class `" + cls.getName() +
    "` has no `before { authenticate_non_get! }` hook; unauthenticated callers can reach this write endpoint (CWE-306)."
