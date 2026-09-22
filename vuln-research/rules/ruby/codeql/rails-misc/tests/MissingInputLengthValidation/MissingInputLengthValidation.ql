/**
 * @name ActiveRecord model validates presence but has no length cap
 * @description An ActiveRecord model class validates a field for presence (or format)
 *              but never applies any `validates ..., length: { maximum: N }` constraint
 *              in the same class body. Without a length cap, oversized payloads stored or
 *              processed by this model can exhaust database row capacity, application
 *              memory, or cause denial of service. Add `length: { maximum: N }` to the
 *              relevant `validates` calls, or introduce a dedicated size validator.
 * @kind problem
 * @problem.severity warning
 * @security-severity 5.3
 * @precision medium
 * @id rb/rails-misc-missing-input-length-validation
 * @tags security
 *       external/cwe/cwe-20
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2507
 * @source-citation derived from GitLab security fix 04819bc3 (abuse report message length cap); CWE-20/400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` is an ActiveRecord model class (inherits from ApplicationRecord
 * or ActiveRecord::Base directly).
 */
predicate isActiveRecordModel(ClassDeclaration cls) {
  // class Foo < ApplicationRecord
  cls.getSuperclassExpr().(ConstantReadAccess).getName() = "ApplicationRecord"
  or
  // class Foo < ActiveRecord::Base
  exists(ConstantReadAccess base, ConstantReadAccess ns |
    base = cls.getSuperclassExpr() and
    base.getName() = "Base" and
    ns = base.getScopeExpr() and
    ns.getName() = "ActiveRecord"
  )
}

/**
 * Holds if `vc` is a `validates` call in `cls` that includes a `presence: true`
 * or `format:` keyword argument — indicating a field that is user-facing and
 * expected to carry user-supplied content.
 */
predicate isPresenceOrFormatValidates(ClassDeclaration cls, MethodCall vc) {
  vc.getEnclosingModule() = cls and
  vc.getMethodName() = "validates" and
  (
    // presence: true  (the keyword arg value is a BooleanLiteral true)
    vc.getKeywordArgument("presence").(BooleanLiteral).getValue() = true
    or
    // format: { ... }  — any format validator
    exists(vc.getKeywordArgument("format"))
  )
}

/**
 * Holds if `cls` contains at least one `validates` call with a `length:` keyword
 * anywhere in the class body.
 */
predicate hasAnyLengthValidates(ClassDeclaration cls) {
  exists(MethodCall lv |
    lv.getEnclosingModule() = cls and
    lv.getMethodName() = "validates" and
    exists(lv.getKeywordArgument("length"))
  )
}

from ClassDeclaration cls, MethodCall presenceCall
where
  isActiveRecordModel(cls) and
  isPresenceOrFormatValidates(cls, presenceCall) and
  not hasAnyLengthValidates(cls)
select presenceCall,
  "ActiveRecord model '" + cls.getName() +
    "' validates presence/format on a field but has no `length: { maximum: N }` constraint " +
    "anywhere in this class; add a length cap to prevent oversized-payload DoS."
