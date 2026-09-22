/**
 * @name Ruby rails-misc unsafe JSON.parse on untrusted input
 * @description Calling `Gitlab::Json.parse` (or bare `JSON.parse`) directly on
 *              untrusted input such as HTTP response bodies, user-supplied fields, or
 *              cache entries does not enforce size or depth limits and can be exploited
 *              to cause unbounded memory allocation (DoS). Use `Gitlab::Json.safe_parse`
 *              which enforces those limits.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-unsafe-json-parse
 * @tags security
 *       external/cwe/cwe-400
 *       external/cwe/cwe-20
 * @vr-id RB-QL-2505
 * @source-citation derived from GitLab security fixes 7eba732e ae363437 6f589884 7944a976 dee73c75 (replace Json.parse with Json.safe_parse); CWE-400/20
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
  c.getMethodName() = "parse" and
  (
    // Gitlab::Json.parse(...)
    isGitlabJson(c.getReceiver().(ConstantReadAccess))
    or
    // Bare JSON.parse(...)  — top-level constant, no scope qualifier
    (
      c.getReceiver().(ConstantReadAccess).getName() = "JSON" and
      not exists(c.getReceiver().(ConstantReadAccess).getScopeExpr())
    )
  )
select c,
  "Unsafe JSON.parse call: use Gitlab::Json.safe_parse to enforce size/depth limits and prevent DoS on untrusted input."
