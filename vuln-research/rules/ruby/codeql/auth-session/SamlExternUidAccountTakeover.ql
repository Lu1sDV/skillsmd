/**
 * @name SAML identity extern_uid updated without invalidating trust
 * @description An identity record's `extern_uid` attribute is updated (via
 *              `update`, `update_column`, `assign_attributes`, or `update_all`)
 *              without also marking `trusted_extern_uid` as false in the same
 *              method. An administrator or attacker who changes a SAML
 *              `extern_uid` mapping can silently take over the target account
 *              on the next SAML sign-in. Set `trusted_extern_uid = false` on
 *              every extern_uid change and send a security notification email.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision medium
 * @id rb/auth-session-saml-extern-uid-account-takeover
 * @tags security
 *       external/cwe/cwe-287
 * @vr-id RB-QL-1329
 * @source-citation derived from GitLab security fixes a03ee8b2665b,d593d8585a31 (Fix SAML identity takeover via trusted_extern_uid); CWE-287
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `call` passes `extern_uid` as a keyword argument or as part of a
 * hash literal argument — i.e. it mutates the extern_uid field.
 */
predicate updatesExternUid(MethodCall call) {
  // Direct keyword form: identity.update(extern_uid: new_uid)
  exists(call.getKeywordArgument("extern_uid"))
  or
  // Hash-pair inside a hash literal argument:
  // identity.update({ extern_uid: new_uid, ... })
  exists(Pair p |
    p.getKey().(SymbolLiteral).getConstantValue().getSymbol() = "extern_uid" and
    p.getParent*() = call.getAnArgument()
  )
}

/**
 * Holds if the same enclosing callable as `mutator` also sets
 * `trusted_extern_uid` to false, indicating the fix is in place.
 */
predicate hasTrustInvalidation(MethodCall mutator) {
  // Pattern 1: identity.trusted_extern_uid = false
  exists(AssignExpr assign, MethodCall getter |
    getter.getMethodName() = "trusted_extern_uid=" and
    assign.getLeftOperand() = getter and
    assign.getEnclosingCallable() = mutator.getEnclosingCallable()
  )
  or
  // Pattern 2: identity.update_column(:trusted_extern_uid, false) or
  //            identity.update(trusted_extern_uid: false)
  exists(MethodCall guard |
    guard.getMethodName() = ["update_column", "update_all", "update", "assign_attributes"] and
    guard.getEnclosingCallable() = mutator.getEnclosingCallable() and
    (
      exists(guard.getKeywordArgument("trusted_extern_uid"))
      or
      exists(Pair p |
        p.getKey().(SymbolLiteral).getConstantValue().getSymbol() = "trusted_extern_uid" and
        p.getParent*() = guard.getAnArgument()
      )
      or
      // update_column(:trusted_extern_uid, ...)
      guard.getAnArgument().(SymbolLiteral).getConstantValue().getSymbol() =
        "trusted_extern_uid"
    )
  )
  or
  // Pattern 3: explicit field setter call: identity.trusted_extern_uid = false
  exists(MethodCall setter |
    setter.getMethodName() = "trusted_extern_uid=" and
    setter.getEnclosingCallable() = mutator.getEnclosingCallable()
  )
}

from MethodCall mutator
where
  // The call is one of the ActiveRecord mutation methods that can change extern_uid
  mutator.getMethodName() = ["update", "update!", "assign_attributes", "update_column", "update_all"] and
  // It touches the extern_uid attribute
  updatesExternUid(mutator) and
  // The same method does NOT also invalidate trusted_extern_uid
  not hasTrustInvalidation(mutator)
select mutator,
  "Identity `extern_uid` is updated by `" + mutator.getMethodName() +
    "` without setting `trusted_extern_uid = false`. A changed SAML extern_uid " +
    "lets an attacker silently take over the mapped account on the next SAML sign-in. " +
    "Invalidate trust and send a `saml_extern_uid_changed_email` notification."
