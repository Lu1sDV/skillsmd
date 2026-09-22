/**
 * @name Ruby auth-session IDOR: unscoped ActiveRecord find from request parameters
 * @description A model class is looked up directly with `.find` or `.find_by` using a
 *              value from `params`, with no user-scoping on the receiver. An attacker can
 *              enumerate or access records belonging to other users by varying the parameter.
 *              Scope the lookup through the current user's association (e.g.
 *              `current_user.projects.find(...)`) or add an explicit authorization check.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-idor-unscoped-find
 * @tags security
 *       external/cwe/cwe-639
 * @vr-id RB-QL-1304
 * @source-citation derived from GitLab auth-session IDOR fixes (unscoped find from params; shas 126fe92ee748,4c696f6b4c44,e5328e43b6b4); CWE-639
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `node` is a descendant (including itself) of `root` using the
 * generic `getAChild*` traversal.
 */
private predicate isDescendantOf(AstNode node, AstNode root) {
  node = root
  or
  isDescendantOf(node, root.getAChild(_))
}

/**
 * Holds if `arg` is (or contains) a `params[...]` element reference, i.e.
 * the receiver of an `ElementReference` is a `params` method call.
 */
private predicate argContainsParamsAccess(Expr arg) {
  exists(ElementReference er |
    isDescendantOf(er, arg) and
    er.getReceiver().(MethodCall).getMethodName() = "params"
  )
}

from MethodCall c
where
  // .find(...) or .find_by(...)
  c.getMethodName() = ["find", "find_by"] and
  // receiver is a bare constant (model class), not a method call chain
  c.getReceiver() instanceof ConstantReadAccess and
  // at least one argument is sourced from params
  argContainsParamsAccess(c.getAnArgument())
select c,
  "Unscoped " + c.getMethodName() + " on " + c.getReceiver().toString() +
    " using request parameters; scope the lookup to the current user's records or add an authorization check (IDOR)."
