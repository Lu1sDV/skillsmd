/**
 * @name Ruby XSS via sprintf/i18n string interpolated into html_safe
 * @description Calling `.html_safe` on the result of `sprintf(s_(...), {...})` or
 *              `_(...) % {...}` where at least one interpolated value comes from a
 *              non-constant expression (model attribute, params, etc.) bypasses
 *              Rails auto-escaping and allows stored or reflected XSS. Replace with
 *              `safe_format(...)` or escape each interpolated value individually.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.3
 * @precision high
 * @id rb/xss-sprintf-html-safe-interp
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0804
 * @source-citation derived from GitLab XSS security fixes (shas 3672795fc9a3,c534b75c4bd2,b564616b7303); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `e` is a non-constant expression — i.e., not a string/symbol/integer/
 * float/nil/boolean literal. Includes local variable reads, method calls, etc.
 */
predicate isNonConstant(Expr e) {
  not e instanceof StringLiteral and
  not e instanceof SymbolLiteral and
  not e instanceof IntegerLiteral and
  not e instanceof FloatLiteral and
  not e instanceof NilLiteral and
  not e instanceof BooleanLiteral
}

/**
 * Holds if `hashArg` is a HashLiteral with at least one non-constant value.
 */
predicate isUnsafeHashLiteral(HashLiteral hashArg) {
  exists(Pair pair |
    pair = hashArg.getAKeyValuePair() and
    isNonConstant(pair.getValue())
  )
}

/**
 * Holds if `inner` is a `sprintf(i18n_string, hash)` call where the i18n string
 * is produced by `s_(...)`, `_(...)`, or `n_(...)`, and the hash contains at least
 * one non-constant value.
 */
predicate isUnsafeSprintfCall(MethodCall inner) {
  inner.getMethodName() = "sprintf" and
  // First arg is an i18n translation call
  inner.getArgument(0).(MethodCall).getMethodName() = ["s_", "_", "n_"] and
  // Second arg is a hash with at least one non-constant value
  isUnsafeHashLiteral(inner.getArgument(1))
}

/**
 * Holds if `inner` is a `_(...)  %  rhs` binary operation (ModuloExpr) where:
 * - the left operand (receiver) is an i18n call (`s_`, `_`, or `n_`), and
 * - the right operand is non-constant (a local variable, method call, or hash
 *   with dynamic values).
 * BinaryOperation extends MethodCall in the CodeQL Ruby AST, so `%` is represented
 * as a BinaryOperation with getLeftOperand() = i18n call, getRightOperand() = hash/var.
 */
predicate isUnsafePercentFormatCall(BinaryOperation inner) {
  inner.getOperator() = "%" and
  inner.getLeftOperand().(MethodCall).getMethodName() = ["s_", "_", "n_"] and
  isNonConstant(inner.getRightOperand())
}

from MethodCall htmlSafe, Expr inner
where
  htmlSafe.getMethodName() = "html_safe" and
  inner = htmlSafe.getReceiver() and
  (
    isUnsafeSprintfCall(inner)
    or
    isUnsafePercentFormatCall(inner)
  )
select htmlSafe,
  "Calling .html_safe on an i18n-interpolated string where at least one placeholder value is non-constant bypasses auto-escaping; use safe_format(...) instead."
