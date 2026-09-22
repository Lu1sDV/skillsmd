/**
 * @name Admin controller uses current_user.admin? without checking admin mode
 * @description An admin controller, concern, or authentication helper calls
 *              `current_user.admin?` (or `user.admin?`) as an access guard without
 *              pairing it with a `can_access_admin_area?` or `admin_mode?` check in
 *              the same method. When GitLab's admin mode is enabled, a user who is
 *              technically an admin but has not re-authenticated in the current session
 *              can bypass the mode gate. Replace `.admin?` with `.can_access_admin_area?`.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision medium
 * @id rb/auth-session-admin-bare-admin-check-without-mode
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1314
 * @source-citation derived from GitLab security fix 8fc32b26e348 (admin mode admin check); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `call` is a `.admin?` call on a receiver named `current_user` or `user`
 * (covering `current_user.admin?`, `current_user&.admin?`, `user.admin?`).
 */
predicate isAdminCheck(MethodCall call) {
  call.getMethodName() = "admin?" and
  call.getReceiver().(MethodCall).getMethodName() = ["current_user", "user"]
}

/**
 * Holds if `callable` contains a paired admin-mode guard call.
 */
predicate hasModeGuard(Callable callable) {
  exists(MethodCall guard |
    guard.getEnclosingCallable() = callable and
    guard.getMethodName() = ["can_access_admin_area?", "admin_mode?", "prevent_admin_area_access?"]
  )
}

/**
 * Holds if the ClassDeclaration or ModuleDeclaration named `n` has "Admin" in its name.
 */
predicate isAdminNamed(ModuleBase n) {
  n.(ClassDeclaration).getName().matches("%Admin%")
  or
  n.(ModuleDeclaration).getName().matches("%Admin%")
}

/**
 * Holds if the ClassDeclaration (or ModuleDeclaration) directly enclosing `callable`
 * has "Admin" in its name, OR any ancestor module in the nesting chain does.
 */
predicate isInAdminScopedClass(Callable callable) {
  // Direct enclosing class/module is Admin-named
  isAdminNamed(callable.getEnclosingModule())
  or
  // One level up: class/module is nested inside an Admin-named module
  isAdminNamed(callable.getEnclosingModule().(ModuleBase).getEnclosingModule())
}

from MethodCall adminCall, Callable enclosing
where
  isAdminCheck(adminCall) and
  enclosing = adminCall.getEnclosingCallable() and
  // Only flag inside admin-scoped classes/modules
  isInAdminScopedClass(enclosing) and
  // No safer mode guard exists in the same method
  not hasModeGuard(enclosing)
select adminCall,
  "`.admin?` used as an admin access guard without a paired `can_access_admin_area?` or `admin_mode?` check; " +
    "replace with `.can_access_admin_area?` to respect admin mode."
