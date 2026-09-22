/**
 * @name Protected branch/tag access level instantiated with user_id during import without admin check
 * @description During project or group import, ProtectedBranch::MergeAccessLevel,
 *              PushAccessLevel, UnprotectAccessLevel, or ProtectedTag::CreateAccessLevel objects
 *              are instantiated with a user_id from the import data. Without validating that the
 *              importing user has admin or owner privileges, an attacker-controlled export file
 *              can assign any user (including admins) as the allowed pusher/merger, granting
 *              privilege escalation on protected branches and tags. Add a guard that checks
 *              whether the importing user has admin or owner access before accepting user_id fields.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id rb/auth-session-import-protected-access-level-user-swap
 * @tags security
 *       external/cwe/cwe-269
 * @vr-id RB-QL-1330
 * @source-citation derived from GitLab security fix 7bfe9760321d (user-swap on templated project import); CWE-269
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A call that instantiates a ProtectedBranch or ProtectedTag access-level model.
 * Matches: ProtectedBranch::MergeAccessLevel.new(...),
 *          ProtectedBranch::PushAccessLevel.new(...),
 *          ProtectedBranch::UnprotectAccessLevel.new(...),
 *          ProtectedTag::CreateAccessLevel.new(...)
 */
predicate isProtectedAccessLevelNew(MethodCall c) {
  c.getMethodName() = "new" and
  exists(ConstantReadAccess klass |
    klass = c.getReceiver() and
    klass.getName() =
      ["MergeAccessLevel", "PushAccessLevel", "UnprotectAccessLevel", "CreateAccessLevel"] and
    klass.getScopeExpr().(ConstantReadAccess).getName() = ["ProtectedBranch", "ProtectedTag"]
  )
}

/**
 * The `.new` call has a `user_id` keyword argument or a hash argument with a `user_id` key.
 */
predicate hasUserIdArgument(MethodCall c) {
  // Direct keyword argument: .new(user_id: x)
  exists(c.getKeywordArgument("user_id"))
  or
  // Hash literal argument containing user_id key
  exists(HashLiteral h, Pair p |
    h = c.getAnArgument() and
    p = h.getAKeyValuePair() and
    (
      p.getKey().(SymbolLiteral).getConstantValue().getSymbol() = "user_id"
      or
      p.getKey().(StringLiteral).getConstantValue().getString() = "user_id"
    )
  )
}

/**
 * The enclosing callable has an admin/owner guard: calls `can_admin_all_resources?`
 * or `can?(:owner_access, ...)` which is the documented fix pattern.
 */
predicate hasAdminGuard(MethodCall c) {
  exists(MethodCall guard |
    guard.getEnclosingCallable() = c.getEnclosingCallable() and
    (
      guard.getMethodName() = ["can_admin_all_resources?", "can_admin_importable?",
                               "user_can_admin_importable?"]
      or
      // can?(:owner_access, ...) pattern
      guard.getMethodName() = "can?" and
      exists(SymbolLiteral s |
        s = guard.getArgument(0) and
        s.getConstantValue().getSymbol() = "owner_access"
      )
    )
  )
}

from MethodCall c
where
  isProtectedAccessLevelNew(c) and
  hasUserIdArgument(c) and
  not hasAdminGuard(c)
select c,
  "ProtectedBranch/Tag access level created with user_id during import without an admin/owner guard; " +
  "an attacker-controlled import file can assign arbitrary users as pushers or mergers. " +
  "Add a check for can_admin_all_resources? or can?(:owner_access, importable) before accepting user_id."
