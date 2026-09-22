/**
 * @name CI ID token claim built from target project without fork-origin check
 * @description A JWT/OIDC claims-building method reads `project.full_path` or
 *              `project.id` to populate path or identity claims without checking
 *              whether the pipeline originates from a forked merge request. An
 *              attacker controlling a fork can cause the token to carry the target
 *              project's identity instead of the source project's, enabling
 *              cross-project privilege escalation. Introduce a
 *              `source_project` helper that returns `merge_request.source_project`
 *              for forked pipelines and use it instead of `project`.
 * @kind problem
 * @problem.severity error
 * @security-severity 9.6
 * @precision medium
 * @id rb/auth-session-ci-id-token-claim-manipulation
 * @tags security
 *       external/cwe/cwe-345
 * @vr-id RB-QL-1324
 * @source-citation derived from GitLab security fix 9c1c507ccefa (CI ID token sub-claim built from controllable project context); CWE-345
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * A method call that reads `project.full_path` or `project.id` — the two
 * accessors used to build OIDC/JWT claims from the build's project reference.
 */
predicate isProjectClaimAccessor(MethodCall access) {
  access.getMethodName() = ["full_path", "id"] and
  access.getReceiver().(MethodCall).getMethodName() = "project"
}

/**
 * A MethodBase (named method or singleton method) whose name suggests it
 * constructs JWT/OIDC claims or tokens.
 * Covers patterns like: project_claims, custom_claims, predefined_claims,
 * generate_token, build_token, jwt_claims, oidc_claims, token_payload, etc.
 */
predicate isClaimsBuilder(MethodBase m) {
  m.getName().matches("%claim%")
  or m.getName().matches("%token%")
  or m.getName().matches("%payload%")
  or m.getName().matches("%jwt%")
  or m.getName().matches("%oidc%")
}

/**
 * A guard that acknowledges the fork-origin distinction:
 * a call to `merge_request_from_forked_project?` or `source_project`.
 */
predicate hasForkOriginGuard(MethodBase m) {
  exists(MethodCall guard |
    guard.getEnclosingCallable() = m and
    guard.getMethodName() = ["merge_request_from_forked_project?", "source_project"]
  )
}

from MethodCall access, MethodBase enclosing
where
  isProjectClaimAccessor(access) and
  enclosing = access.getEnclosingCallable() and
  isClaimsBuilder(enclosing) and
  not hasForkOriginGuard(enclosing)
select access,
  "CI/OIDC claim built from `project." + access.getMethodName() +
    "` without a fork-origin guard (`source_project` / `merge_request_from_forked_project?`); " +
    "forked-MR pipelines may carry target-project identity instead of source-project identity."
