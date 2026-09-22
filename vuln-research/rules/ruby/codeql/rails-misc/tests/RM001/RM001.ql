/**
 * @name ActiveRecord model field missing length validation
 * @description An ActiveRecord model validates a field for presence but has no
 *              corresponding `validates :field, length: { maximum: N }` in the
 *              same class body. User-supplied input is stored without a size
 *              bound, enabling database-level DoS via overlong values or
 *              column-size errors propagated to API responses. Add
 *              `validates :field, length: { maximum: N }, if: :field_changed?`.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-rm-001
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2504
 * @source-citation derived from GitLab security fixes 189b90e8092c,42bd7dbbee30,84068a92260f,ef7da8125fdf,8dc8141fc43e (AR model missing length validation); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a `validates :fieldName, presence: true` call (or any
 * validates call for that field without an inline `length:` keyword).
 */
predicate isPresenceValidates(MethodCall c, string fieldName) {
  c.getMethodName() = "validates" and
  fieldName = c.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() and
  // Must have a presence: keyword arg (rules out bare no-op validates calls)
  exists(c.getKeywordArgument("presence")) and
  // Must NOT already have a length: keyword in this same call
  not exists(c.getKeywordArgument("length"))
}

/**
 * Holds if `c` is a `validates :fieldName, length: { ... }` call (the fix shape).
 */
predicate hasLengthValidates(MethodCall c, string fieldName) {
  c.getMethodName() = "validates" and
  fieldName = c.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() and
  exists(c.getKeywordArgument("length"))
}

from MethodCall presenceCall, string fieldName
where
  isPresenceValidates(presenceCall, fieldName) and
  // Only flag inside an ApplicationRecord subclass
  exists(ClassDeclaration cls |
    presenceCall.getEnclosingModule() = cls and
    cls.getSuperclassExpr().(ConstantReadAccess).getName() = "ApplicationRecord"
  ) and
  // No length validator for the same field in the same class body
  not exists(MethodCall lenCall |
    hasLengthValidates(lenCall, fieldName) and
    lenCall.getEnclosingModule() = presenceCall.getEnclosingModule()
  )
select presenceCall,
  "Field `:" + fieldName +
    "` is validated for presence but has no length: { maximum: N } constraint in this model; " +
    "add `validates :" + fieldName + ", length: { maximum: N }, if: :" + fieldName + "_changed?` to prevent unbounded input."
