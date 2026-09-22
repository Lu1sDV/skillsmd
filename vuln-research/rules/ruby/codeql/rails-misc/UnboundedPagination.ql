/**
 * @name Unbounded pagination per_page parameter
 * @description A keyset paginator receives a `per_page:` value taken directly
 *              from user-controlled params without enforcing a maximum. A caller
 *              can pass `per_page=100000` and exhaust database or application
 *              memory. Fix: `per_page = [params[:per_page].to_i, MAX_PER_PAGE].min`.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.3
 * @precision medium
 * @id rb/rails-misc-unbounded-pagination
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2527
 * @source-citation derived from GitLab security fix f85343ef (enforce discussions pagination); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `e` is a direct read of `params[<key>]` or `params[<key>].to_i`
 * (both unguarded forms seen in the real fix).
 */
predicate isRawParamsPerPage(Expr e) {
  // params[:per_page]  or  params["per_page"]
  exists(ElementReference er |
    er.getReceiver().(MethodCall).getMethodName() = "params" and
    e = er
  )
  or
  // params[:per_page].to_i  /  params[:per_page].presence  etc.
  exists(MethodCall conv, ElementReference er |
    conv.getReceiver() = er and
    er.getReceiver().(MethodCall).getMethodName() = "params" and
    e = conv
  )
}

/**
 * Holds if `e` is guarded by a `.min(...)` call — i.e. it is the receiver of
 * an Array#min call or is the first element of a two-element array literal
 * whose `.min` is called, matching the pattern `[val, MAX].min`.
 */
predicate isMinCapped(Expr e) {
  // [per_page_expr, CONST].min  →  MethodCall with getMethodName()="min"
  //   whose receiver is an ArrayLiteral containing e
  exists(MethodCall minCall, ArrayLiteral arr |
    minCall.getMethodName() = "min" and
    minCall.getReceiver() = arr and
    arr.getElement(0) = e
  )
}

from MethodCall paginate, Expr perPageArg
where
  // Target: keyset_paginate (GitLab's paginator) or paginate (kaminari/will_paginate)
  paginate.getMethodName() = ["keyset_paginate", "paginate"] and
  // The per_page: keyword argument is present
  perPageArg = paginate.getKeywordArgument("per_page") and
  // The argument itself (or its direct sub-expression) is a raw params read
  (
    isRawParamsPerPage(perPageArg)
    or
    // per_page: params[:per_page].to_i  already caught above, but also
    // per_page: some_var where some_var = params[...] in the same method —
    // keep scope to direct structural expressions only (no full dataflow)
    isRawParamsPerPage(perPageArg.(MethodCall).getReceiver())
  ) and
  // Not guarded: the per_page argument is NOT itself wrapped in a .min call
  not isMinCapped(perPageArg) and
  not isMinCapped(perPageArg.(MethodCall).getReceiver())
select paginate,
  "Keyset/paginate call passes `per_page:` directly from user params without a maximum cap; " +
    "use `[params[:per_page].to_i, MAX_PER_PAGE].min` to prevent resource exhaustion."
