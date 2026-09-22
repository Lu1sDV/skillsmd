/**
 * @name JSON parse without depth/size parse_limits (OOM/DoS)
 * @description Calling `JSON.parse`, `Gitlab::Json.parse`, or
 *              `Gitlab::Json.safe_parse` on an externally-fetched payload
 *              without a `parse_limits: { max_depth:, max_array_size:,
 *              max_json_size_bytes: }` keyword argument allows a deeply
 *              nested or oversized JSON response to exhaust Rails worker
 *              memory (DoS). Add the `parse_limits:` keyword with all
 *              three bounds.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision high
 * @id rb/rails-misc-rm-003
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2513
 * @source-citation derived from GitLab security fix 8d75814365ab (HttpResponseParser: add parse_limits to JSON parse); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `recv` refers to `Gitlab::Json` via scope resolution.
 */
predicate isGitlabJson(ConstantReadAccess recv) {
  recv.getName() = "Json" and
  recv.getScopeExpr().(ConstantReadAccess).getName() = "Gitlab"
}

from MethodCall c
where
  (
    // JSON.parse(...) — bare standard library
    c.getMethodName() = "parse" and
    c.getReceiver().(ConstantReadAccess).getName() = "JSON" and
    not exists(c.getReceiver().(ConstantReadAccess).getScopeExpr())
    or
    // Gitlab::Json.parse(...)
    c.getMethodName() = "parse" and
    isGitlabJson(c.getReceiver().(ConstantReadAccess))
    or
    // Gitlab::Json.safe_parse(...)
    c.getMethodName() = "safe_parse" and
    isGitlabJson(c.getReceiver().(ConstantReadAccess))
  ) and
  // Flag only when the parse_limits: keyword argument is absent
  not exists(c.getKeywordArgument("parse_limits"))
select c,
  "JSON parse called without `parse_limits: { max_depth:, max_array_size:, max_json_size_bytes: }`; " +
    "a deeply nested or oversized payload can exhaust worker memory (DoS). " +
    "Add the parse_limits: keyword with all three bounds."
