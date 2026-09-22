/**
 * @name DeclarativePolicy condition declared but never used in a rule
 * @description A `condition(:name) { ... }` is declared in a DeclarativePolicy class but
 *              no `rule { name }` block in the same class body references it. The access
 *              rule that enforces this condition is likely missing; add the corresponding
 *              `rule { name }.prevent :permission` or `rule { name }.enable :permission`.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-declarative-policy-unused-condition
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1306
 * @source-citation derived from GitLab DeclarativePolicy access-control fixes (unused condition / missing rule; shas 047963e52d19,0de6ffe017e4,10432c4573d1); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cond` is a `condition(:name)` DSL call and `condName` is the symbol text.
 */
predicate isConditionDeclaration(MethodCall cond, string condName) {
  cond.getMethodName() = "condition" and
  condName = cond.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol()
}

/**
 * Holds if `ruleCall` is a `rule { ... }` DSL call (a method named "rule" that has a block).
 */
predicate isRuleCall(MethodCall ruleCall) {
  ruleCall.getMethodName() = "rule" and
  ruleCall.hasBlock()
}

/**
 * Holds if `ref` is a bare method call named `condName` inside the block of `ruleCall`.
 * A bare condition reference `reporter` inside `rule { reporter }` compiles to a
 * zero-argument MethodCall on implicit self.
 */
predicate isConditionRefInRuleBlock(MethodCall ruleCall, string condName) {
  isRuleCall(ruleCall) and
  exists(MethodCall ref |
    ref.getMethodName() = condName and
    // ref is a descendant of the rule's block
    ruleCall.getBlock().getAChild*() = ref
  )
}

from MethodCall cond, string condName
where
  isConditionDeclaration(cond, condName) and
  // Only flag conditions inside classes that also declare at least one rule —
  // avoids noise from abstract base policies with no rules at all.
  exists(MethodCall anyRule |
    isRuleCall(anyRule) and
    anyRule.getEnclosingModule() = cond.getEnclosingModule()
  ) and
  // No rule block in the same class references this condition by name.
  not exists(MethodCall ruleCall |
    isRuleCall(ruleCall) and
    ruleCall.getEnclosingModule() = cond.getEnclosingModule() and
    isConditionRefInRuleBlock(ruleCall, condName)
  )
select cond,
  "DeclarativePolicy condition `:" + condName +
    "` is declared but never referenced by any `rule { }` in this class; " +
    "the access rule enforcing it may be missing."
