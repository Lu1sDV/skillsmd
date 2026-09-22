/**
 * @name Sidekiq worker called with unfiltered parent IDs (cyclic hierarchy DoS)
 * @description A Sidekiq worker is called via `perform_async` with parent IDs
 *              collected by `.pluck(:parent_id)` (or similar hierarchy-column names)
 *              without first excluding descendant IDs via `.where.not(parent_id: descendants)`.
 *              In a self-referencing hierarchy (epics, work items, etc.) a cycle can cause
 *              the worker to re-enqueue itself infinitely, producing unbounded CPU/memory
 *              exhaustion (DoS). Add a `.where.not(column: descendants)` clause before
 *              `.pluck(...)` to break the cycle.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision low
 * @id rb/rails-misc-rm-010
 * @tags security
 *       external/cwe/cwe-674
 * @vr-id RB-QL-2526
 * @source-citation derived from GitLab security fix 9d135851bac2 (avoid recursive sidekiq calls on cyclic work item hierarchies); CWE-674
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `call` is a `.not(...)` call whose receiver is a `.where` call —
 * i.e., the `where.not(...)` guard pattern used to exclude cyclic descendants.
 */
predicate isWhereNotCall(MethodCall call) {
  call.getMethodName() = "not" and
  call.getReceiver().(MethodCall).getMethodName() = "where"
}

/**
 * Walks the receiver chain of `node` and holds if any call in the chain
 * is a `where.not(...)` guard.
 */
predicate chainContainsWhereNot(Expr node) {
  // Base: node itself is the where.not call
  isWhereNotCall(node)
  or
  // Recurse: receiver of a method call in the chain
  exists(MethodCall mc |
    mc = node and
    chainContainsWhereNot(mc.getReceiver())
  )
}

/**
 * Holds if `sym` is a symbol literal naming a parent-ID column in a
 * hierarchical (self-referencing) table.
 */
predicate isParentIdColumn(SymbolLiteral sym) {
  sym.getConstantValue().getSymbol().regexpMatch(".*parent_id.*")
}

/**
 * Holds if `callable` contains a `perform_async` call.
 */
predicate hasPerformAsync(Callable callable) {
  exists(MethodCall pa |
    pa.getMethodName() = "perform_async" and
    pa.getEnclosingCallable() = callable
  )
}

from Callable callable, MethodCall pluckCall, SymbolLiteral parentIdSym
where
  // The callable contains a perform_async call
  hasPerformAsync(callable) and
  // The callable also contains a .pluck(:parent_id...) call
  pluckCall.getEnclosingCallable() = callable and
  pluckCall.getMethodName() = "pluck" and
  // The pluck call targets a parent-ID column
  parentIdSym = pluckCall.getAnArgument() and
  isParentIdColumn(parentIdSym) and
  // The receiver chain of the pluck call does NOT contain a where.not guard
  not chainContainsWhereNot(pluckCall.getReceiver())
select pluckCall,
  "`.pluck(:" +
  parentIdSym.getConstantValue().getSymbol() +
  ")` collects parent IDs without a `.where.not(...)` exclusion of descendant IDs;" +
  " a `perform_async` in this method will cause infinite re-enqueuing on a cyclic hierarchy (DoS)."
