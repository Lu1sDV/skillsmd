/**
 * @name Grape API endpoint missing route_setting :authorization in partially-migrated file
 * @description A Grape API endpoint verb block (get/post/put/patch/delete) lacks a
 *              preceding `route_setting :authorization` call in the same enclosing module,
 *              while the module already contains at least one such setting for another
 *              endpoint. Missing authorization route settings allow endpoints to bypass
 *              granular PAT permission enforcement. Add
 *              `route_setting :authorization, permissions: :x, boundary_type: :project`
 *              immediately before each verb block.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-grape-api-missing-route-authorization-setting
 * @tags security
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1308
 * @source-citation derived from GitLab security fix e70254a84f92 (Add granular PAT permissions for CI/CD Pipelines API endpoints), 61b02dc96437 (Add authorization route setting to pipeline schedule REST API endpoints); CWE-862
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `rs` is a `route_setting :authorization` call — i.e., a MethodCall
 * named `route_setting` whose first argument is the symbol `:authorization`.
 */
private predicate isAuthorizationRouteSetting(MethodCall rs) {
  rs.getMethodName() = "route_setting" and
  rs.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "authorization"
}

/**
 * Holds if `verb` is a Grape HTTP-verb call (`get`/`post`/`put`/`patch`/`delete`)
 * whose first argument is a string route path (i.e. a StringLiteral).
 * This restricts to actual route declarations, not incidental same-name calls.
 */
private predicate isGrapeVerbCall(MethodCall verb) {
  verb.getMethodName() = ["get", "post", "put", "patch", "delete"] and
  exists(verb.getArgument(0).(StringLiteral))
}

/**
 * Holds if `rs` is the `route_setting :authorization` call that immediately
 * precedes `verb` in the same statement sequence.
 *
 * We detect "immediately precedes" by checking that both calls share a parent
 * StmtSequence and `rs` appears at index N while `verb` appears at index N+1
 * (or any later index, but with no intervening verb call — pragmatically we
 * just check existence within the same sequence at an earlier position).
 *
 * Pragmatic approximation: `rs` and `verb` are siblings in the same
 * StmtSequence (or Body), and `rs` has a strictly smaller child-index than
 * `verb`, and there is no other verb call between them.
 */
private predicate hasImmediatelyPrecedingRouteSetting(MethodCall verb, StmtSequence seq) {
  seq.getAStmt() = verb and
  exists(MethodCall rs |
    isAuthorizationRouteSetting(rs) and
    seq.getAStmt() = rs and
    // rs appears before verb in the sequence
    exists(int ri, int vi |
      seq.getStmt(ri) = rs and
      seq.getStmt(vi) = verb and
      ri < vi
    ) and
    // no other verb call appears between rs and verb
    not exists(MethodCall other, int oi, int ri2, int vi2 |
      isGrapeVerbCall(other) and
      seq.getAStmt() = other and
      seq.getStmt(ri2) = rs and
      seq.getStmt(oi) = other and
      seq.getStmt(vi2) = verb and
      ri2 < oi and
      oi < vi2
    )
  )
}

from MethodCall verb
where
  isGrapeVerbCall(verb) and
  // Only flag in partially-migrated modules: the enclosing module already has
  // at least one route_setting :authorization somewhere (for another endpoint).
  exists(MethodCall anyRs |
    isAuthorizationRouteSetting(anyRs) and
    anyRs.getEnclosingModule() = verb.getEnclosingModule()
  ) and
  // The verb call is NOT immediately preceded by a route_setting :authorization
  // in the same statement sequence.
  not exists(StmtSequence seq | hasImmediatelyPrecedingRouteSetting(verb, seq))
select verb,
  "Grape API endpoint `" + verb.getMethodName() + "` is missing a `route_setting :authorization` " +
  "immediately before it; other endpoints in this module already have one (missing authorization)."
