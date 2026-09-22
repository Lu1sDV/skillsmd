/**
 * @name User-controlled string used directly in Regexp (ReDoS)
 * @description Building a `Regexp` from a dynamic (non-literal) expression, or
 *              interpolating an expression into a regex literal `/#{expr}/`, passes
 *              a user-controlled pattern to Ruby's Oniguruma engine, which is
 *              susceptible to catastrophic backtracking (ReDoS). Use
 *              `RE2::Regexp.escape` and `Gitlab::UntrustedRegexp.new` instead, or
 *              ensure the input is sanitized before use.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision medium
 * @id rb/rails-misc-user-controlled-regex-redos
 * @tags security
 *       external/cwe/cwe-1333
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2515
 * @source-citation derived from GitLab security fix e5d78860 (ReDoS in GitRefsFinder via Regexp.new); CWE-1333/400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if the enclosing callable of `node` already uses `Gitlab::UntrustedRegexp`
 * as a safe wrapper, indicating the author intentionally used the safe API.
 */
predicate hasSafeWrapper(Expr node) {
  exists(MethodCall safe |
    safe.getEnclosingMethod() = node.getEnclosingMethod() and
    safe.getMethodName() = "new" and
    // Gitlab::UntrustedRegexp.new(...)
    exists(ConstantReadAccess cls, ConstantReadAccess ns |
      cls = safe.getReceiver() and
      cls.getName() = "UntrustedRegexp" and
      ns = cls.getScopeExpr() and
      ns.getName() = "Gitlab"
    )
  )
}

/**
 * Holds if `expr` is a plain string or symbol literal — i.e., definitely NOT
 * a user-controlled runtime value.  We only flag Regexp.new calls whose first
 * argument is a computed expression.
 */
predicate isStringOrSymbolLiteral(Expr expr) {
  expr instanceof StringLiteral
  or
  expr instanceof SymbolLiteral
}

from Expr sink, string msg
where
  // ── Case 1: Regexp.new(dynamic_expr) ──────────────────────────────────────
  // Regexp.new(<non-literal>) with no UntrustedRegexp in the same callable
  exists(MethodCall call, Expr arg |
    sink = call and
    call.getMethodName() = "new" and
    call.getReceiver().(ConstantReadAccess).getName() = "Regexp" and
    arg = call.getArgument(0) and
    not isStringOrSymbolLiteral(arg) and
    not hasSafeWrapper(call) and
    msg =
      "Dynamic expression passed to `Regexp.new` without using `Gitlab::UntrustedRegexp`; " +
        "Ruby's Oniguruma engine may catastrophically backtrack on attacker-controlled input."
  )
  or
  // ── Case 2: /#{interpolated}/ regex literal ───────────────────────────────
  // A regex literal that contains at least one interpolation component, with
  // no UntrustedRegexp guard in the same callable
  exists(RegExpLiteral re |
    sink = re and
    re.getComponent(_) instanceof RegExpInterpolationComponent and
    not hasSafeWrapper(re) and
    msg =
      "Interpolated regex literal `/.../` with a dynamic `#{...}` component; " +
        "use `Gitlab::UntrustedRegexp.new(RE2::Regexp.escape(term))` to avoid ReDoS via Oniguruma."
  )
select sink, msg
