/**
 * @name Recursive method without depth counter (unbounded recursion on user input)
 * @description A method that calls itself recursively without a depth-counter parameter
 *              or MAX_RECURSION_DEPTH guard. An attacker who passes deeply-nested JSON or
 *              hash structures can trigger stack overflow or memory exhaustion (DoS).
 *              Fix by adding a `depth = 0` parameter and raising on `depth > MAX_RECURSION_DEPTH`.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-rm-009
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2524
 * @source-citation derived from GitLab security fix 92f930b88151 (add MAX_RECURSION_DEPTH to GraphQL variables parser); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if parameter `p` is a depth/counter guard parameter — i.e., its name
 * suggests it tracks recursion depth or an iteration limit.
 */
predicate isDepthParameter(NamedParameter p) {
  p.getName().toLowerCase().regexpMatch(".*(depth|level|counter|limit|recursion|nesting).*")
}

/**
 * Holds if `m` contains a constant read whose name suggests a recursion-depth
 * ceiling (MAX_RECURSION_DEPTH, MAX_DEPTH, RECURSION_LIMIT, MAX_NESTING, etc.).
 */
predicate hasDepthGuardConstant(Method m) {
  exists(ConstantReadAccess c |
    c.getEnclosingCallable() = m and
    c.getName().toUpperCase().regexpMatch(".*(MAX.*DEPTH|MAX.*RECURSION|RECURSION.*LIMIT|MAX.*NESTING|DEPTH.*LIMIT).*")
  )
}

from Method m, MethodCall recursiveCall
where
  // The call is a bare recursive call to the same method (self-call without explicit receiver,
  // or with `self` as receiver)
  recursiveCall.getMethodName() = m.getName() and
  recursiveCall.getEnclosingCallable() = m and
  (
    not exists(recursiveCall.getReceiver())
    or
    recursiveCall.getReceiver() instanceof SelfVariableReadAccess
  ) and
  // No depth/counter parameter — the fix is to add one
  not exists(NamedParameter p |
    p = m.getAParameter() and
    isDepthParameter(p)
  ) and
  // No MAX_RECURSION_DEPTH-style constant referenced inside the method
  not hasDepthGuardConstant(m)
select recursiveCall,
  "Method '" + m.getName() +
    "' calls itself recursively without a depth counter or MAX_RECURSION_DEPTH guard;" +
    " an attacker can pass deeply-nested data to cause stack overflow or memory exhaustion."
