/**
 * @name Ruby auth-session PAT-disabled enterprise-group policy not checked in find_by_token
 * @description A `find_by_token` override checks only the instance-level
 *              `personal_access_tokens_disabled?` setting but omits the enterprise-group-level
 *              `disable_personal_access_tokens?` flag on the token's owner. An enterprise user
 *              whose group has PATs disabled can still authenticate via PAT because the
 *              group-level policy is never enforced. After the instance check, verify
 *              `pat.user.enterprise_user?` and `pat.user.enterprise_group.disable_personal_access_tokens?`
 *              and return `nil` if disabled.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/auth-session-pat-disabled-policy-not-enforced-in-finder
 * @tags security
 *       external/cwe/cwe-863
 * @vr-id RB-QL-1334
 * @source-citation derived from GitLab security fix 5567f530d514 (Enterprise PAT-disabled policy not propagated into find_by_token); CWE-863
 * @license derived-original
 */

import codeql.ruby.AST

from Method m
where
  // The method is named find_by_token (an override of the PAT finder)
  m.getName() = "find_by_token" and
  // It contains an instance-level PAT-disabled check
  exists(MethodCall instanceCheck |
    instanceCheck.getEnclosingCallable() = m and
    instanceCheck.getMethodName() = "personal_access_tokens_disabled?"
  ) and
  // But it does NOT contain an enterprise-user guard (enterprise_user? call)
  not exists(MethodCall enterpriseGuard |
    enterpriseGuard.getEnclosingCallable() = m and
    enterpriseGuard.getMethodName() = "enterprise_user?"
  ) and
  // And it does NOT contain an enterprise-group PAT-disabled check
  not exists(MethodCall groupCheck |
    groupCheck.getEnclosingCallable() = m and
    groupCheck.getMethodName() = "disable_personal_access_tokens?"
  )
select m,
  "find_by_token checks only the instance-level personal_access_tokens_disabled? setting but " +
  "does not verify enterprise_user? / disable_personal_access_tokens? for the token's " +
  "enterprise group; users in groups with PATs disabled can still authenticate via PAT."
