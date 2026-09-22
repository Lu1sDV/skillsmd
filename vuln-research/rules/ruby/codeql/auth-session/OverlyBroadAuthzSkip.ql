/**
 * @name Ruby auth-session overly broad authorization skip
 * @description A controller calls `skip_before_action` or `skip_before_filter` with a
 *              privileged-authorization callback (e.g. `authorize_admin_*!` /
 *              `authorize_*_admin!` / `authorize_owner_*!`) and the `only:` list
 *              includes a state-changing action (`:create`, `:update`, `:edit`, or
 *              `:destroy`). This grants an unprivileged caller write access to a
 *              resource that requires admin or owner authorization, allowing privilege
 *              escalation. Restrict the skip to read-only actions only.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.8
 * @precision high
 * @id rb/auth-session-overly-broad-authz-skip
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1303
 * @source-citation derived from GitLab auth-session privilege-escalation fixes (overly broad authz skip; shas 30cc4e834c30,d7ffe0b5a8e4); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c, SymbolLiteral callback, SymbolLiteral mutatingAction
where
  // The call is skip_before_action or its legacy alias.
  c.getMethodName() = ["skip_before_action", "skip_before_filter"] and
  // The first positional arg names a privileged-authorization callback.
  callback = c.getAnArgument() and
  (
    callback.getConstantValue().getSymbol().matches("authorize_admin%") or
    callback.getConstantValue().getSymbol().matches("authorize_%_admin!") or
    callback.getConstantValue().getSymbol().matches("authorize_owner%")
  ) and
  // The only: keyword arg is an ArrayLiteral containing a mutating action symbol.
  exists(ArrayLiteral arr |
    arr = c.getKeywordArgument("only") and
    mutatingAction = arr.getAnElement() and
    mutatingAction.getConstantValue().getSymbol() =
      ["create", "update", "edit", "destroy"]
  )
select c,
  "Privileged-authorization callback '" + callback.getConstantValue().getSymbol() +
  "' is skipped for mutating action ':" + mutatingAction.getConstantValue().getSymbol() +
  "'; restrict the skip to read-only actions to prevent privilege escalation."
