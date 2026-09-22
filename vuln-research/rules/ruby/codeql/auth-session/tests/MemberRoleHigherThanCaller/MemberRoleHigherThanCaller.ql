/**
 * @name Token rotate service subclass missing access-level validation override
 * @description A `RotateService` subclass inherits from another `RotateService`
 *              whose default `valid_access_level?` returns `true` unconditionally.
 *              Without overriding `valid_access_level?` to compare the token
 *              owner's role with the caller's role, any authenticated user can
 *              rotate a group or project access token to an access level above
 *              their own, escalating privilege. Add a `valid_access_level?`
 *              override that calls `max_member_access_for_user` for both the
 *              token owner and the current user and rejects upgrades.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision medium
 * @id rb/auth-session-member-role-higher-than-caller
 * @tags security
 *       external/cwe/cwe-269
 * @vr-id RB-QL-1325
 * @source-citation derived from GitLab security fix 0edcbd24c2a7 (GroupAccessTokens::RotateService missing valid_access_level? override); CWE-269
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` is a RotateService subclass — its own (leaf) name is
 * `"RotateService"` and its superclass expression also resolves to a constant
 * leaf-named `"RotateService"`.  This catches patterns such as:
 *
 *   class GroupAccessTokens::RotateService < ::PersonalAccessTokens::RotateService
 *   class ProjectAccessTokens::RotateService < ::PersonalAccessTokens::RotateService
 */
private predicate isRotateServiceSubclass(ClassDeclaration cls) {
  cls.getName() = "RotateService" and
  cls.getSuperclassExpr().(ConstantReadAccess).getName() = "RotateService"
}

/**
 * Holds if `cls` declares a `valid_access_level?` instance method, which
 * means it does perform an access-level check before token operations.
 */
private predicate hasValidAccessLevelOverride(ClassDeclaration cls) {
  exists(cls.getMethod("valid_access_level?"))
}

from ClassDeclaration cls
where
  isRotateServiceSubclass(cls) and
  not hasValidAccessLevelOverride(cls)
select cls,
  "RotateService subclass '" + cls.getName() +
    "' inherits a `valid_access_level?` that returns `true` by default but does not override it. " +
    "Add a `valid_access_level?` override that compares the token owner's role and the caller's role " +
    "via `max_member_access_for_user` to prevent privilege escalation (CWE-269)."
