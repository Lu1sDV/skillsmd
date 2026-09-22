/**
 * @name CI cache protection tier decided by branch flag instead of user role
 * @description A method uses `pipeline.protected_ref?` (a branch/ref property) to
 *              determine whether to apply a protected-tier cache-key suffix. This
 *              allows a developer-role user running a job on a protected branch to
 *              receive the maintainer-tier cache, enabling cross-privilege cache
 *              poisoning. Fix by gating on the actual user role, e.g.
 *              `project.team.max_member_access(user.id) >= Gitlab::Access::MAINTAINER`.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-rm-011
 * @tags security
 *       external/cwe/cwe-284
 * @vr-id RB-QL-2525
 * @source-citation derived from GitLab security fix 9ac8aa7399645a354cd0dda06a56a40d9a2684d7 (Prevent cache poisoning via protected_ref? branch flag); CWE-284
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a call to `protected_ref?` on a receiver whose source text
 * indicates a pipeline object (variable named `pipeline`, or a method call
 * returning one).
 */
predicate isPipelineProtectedRefCall(MethodCall c) {
  c.getMethodName() = "protected_ref?" and
  (
    // Direct pipeline variable or accessor: pipeline.protected_ref?
    c.getReceiver().(MethodCall).getMethodName() = "pipeline"
    or
    c.getReceiver().(LocalVariableReadAccess).getVariable().getName() = "pipeline"
    or
    c.getReceiver().(InstanceVariableReadAccess).getVariable().getName() = "@pipeline"
  )
}

/**
 * Holds if the enclosing callable `m` contains a role-based access check that
 * replaces the branch-flag guard — i.e., a call to `max_member_access` or a
 * call to `uses_protected_cache?` which is the extracted helper introduced by
 * the security fix.
 */
predicate hasRoleBasedCacheGuard(Callable m) {
  exists(MethodCall guard |
    guard.getEnclosingCallable() = m and
    guard.getMethodName() = ["max_member_access", "uses_protected_cache?"]
  )
}

from MethodCall prc
where
  isPipelineProtectedRefCall(prc) and
  not hasRoleBasedCacheGuard(prc.getEnclosingCallable())
select prc,
  "Cache protection tier determined by `pipeline.protected_ref?` (a branch property) rather than " +
    "the user's actual role. A developer running a job on a protected branch receives the " +
    "maintainer-tier cache, enabling cache poisoning across privilege boundaries. " +
    "Use `project.team.max_member_access(user.id) >= Gitlab::Access::MAINTAINER` instead."
