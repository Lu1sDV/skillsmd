/**
 * @name DeclarativePolicy ability enabled without a governing rule
 * @description A `enable :permission` call appears directly in a DeclarativePolicy class
 *              body without being chained on a `rule { ... }` block. The ability is
 *              unconditionally granted regardless of any condition, which may allow
 *              unintended access. Wrap the enable in a `rule { condition }.enable :permission`
 *              block and add a corresponding `rule { ~condition }.prevent :permission` guard.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-declarative-policy-rule-missing
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1309
 * @source-citation derived from GitLab DeclarativePolicy access-control fixes (ungated enable; shas 047963e52d19,10432c4573d1,15a350c91eb4); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` looks like a DeclarativePolicy class: its name ends in "Policy"
 * or it inherits from a class whose name ends in "Policy" or "BasePolicy".
 * We check the class name as a proxy since Ruby AST does not resolve superclass
 * names reliably across files at query time.
 */
predicate isPolicyClass(ClassDeclaration cls) {
  cls.getName().matches("%Policy")
  or
  exists(string superName |
    superName = cls.getSuperclassExpr().(ConstantReadAccess).getName() and
    (superName.matches("%Policy") or superName = "BasePolicy")
  )
}

/**
 * Holds if `enable` is a bare `enable :perm` call in the direct body of class `cls`
 * — i.e. it is NOT inside a block that belongs to a `rule { ... }` call chain.
 *
 * The legal DSL form is:
 *   rule { condition }.enable :perm          # chained .enable on rule's return
 *   rule { condition }.policy do
 *     enable :perm                           # inside a .policy block
 *   end
 *
 * A bare class-body `enable :perm` has no enclosing rule block up to the class boundary.
 */
predicate isUngatedEnable(MethodCall enable, ClassDeclaration cls) {
  // The call is named "enable" with at least one argument (the permission symbol).
  enable.getMethodName() = "enable" and
  enable.getNumberOfArguments() >= 1 and
  // It lives somewhere inside this policy class.
  enable.getEnclosingModule() = cls and
  isPolicyClass(cls) and
  // Exclude the two gated forms:
  //   (a) `rule{...}.enable :perm` — enable is itself a rule-chain call (its receiver
  //       is a rule{} or another rule-chain call).
  not isRuleChainCall(enable, cls) and
  //   (b) `rule{...}.policy do enable :perm end` — enable is inside a block that
  //       belongs to a rule-chain call (e.g. the .policy block).
  not isInsideRuleChainBlock(enable, cls)
}

/**
 * Holds if `node` is a descendant of a Block that is the block argument of a call
 * that is part of a `rule { }` chain (either directly the rule block, or a `.policy`
 * block chained on a rule).
 */
predicate isInsideRuleChainBlock(Expr node, ClassDeclaration cls) {
  exists(Block blk, MethodCall owner |
    // node is inside this block
    blk.getAChild*() = node and
    // the block belongs to some method call
    owner.getBlock() = blk and
    // and that call is part of a rule chain in the same class
    isRuleChainCall(owner, cls)
  )
}

/**
 * Holds if `call` is directly a `rule { }` call, or is a method call chained on one
 * (e.g. `.enable`, `.policy`, `.prevent`, `.prevent_all`).
 */
predicate isRuleChainCall(MethodCall call, ClassDeclaration cls) {
  // Direct rule call: method named "rule" with a block
  call.getMethodName() = "rule" and
  call.hasBlock() and
  call.getEnclosingModule() = cls
  or
  // Chained call: receiver is itself part of a rule chain (e.g. rule{}.policy or rule{}.enable)
  exists(MethodCall recv |
    recv = call.getReceiver() and
    isRuleChainCall(recv, cls)
  )
}

from MethodCall enable, ClassDeclaration cls, string permName
where
  isUngatedEnable(enable, cls) and
  permName = enable.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol()
select enable,
  "DeclarativePolicy class `" + cls.getName() +
    "` calls `enable :" + permName +
    "` without a governing `rule { }` block; the permission is unconditionally granted. " +
    "Wrap this in a rule condition or add a complementary `prevent` rule."
