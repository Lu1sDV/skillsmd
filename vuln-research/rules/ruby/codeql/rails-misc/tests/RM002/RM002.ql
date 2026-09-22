/**
 * @name ActiveRecord query result passed to serializer or response without .limit()
 * @description A controller or service method invokes an ActiveRecord scope chain
 *              (e.g. finder.execute, Model.all, .where(...)) and passes the result
 *              to a serializer or response helper without an intervening .limit(N) or
 *              .paginate call. Any client can trigger an unbounded database read that
 *              exhausts server memory. Add a .limit(MAX_N) or paginate guard before
 *              returning the collection.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-rm-002
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2512
 * @source-citation derived from GitLab security fixes 0558ebc55d79,ca41813cb5a4 (unbounded AR result sets at HTTP endpoints); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a call to an ActiveRecord finder or scope method that returns
 * a potentially unbounded collection.
 */
predicate isArFinderCall(MethodCall c) {
  c.getMethodName() =
    [
      "execute", "all", "preload", "eager_load", "includes", "joins",
      "where", "order", "reorder", "unscoped", "recent", "find_all",
      "load_records", "fetch_records"
    ]
}

/**
 * Holds if `c` is a call to a response / serializer sink that materialises a
 * collection for the HTTP response.
 */
predicate isResponseSink(MethodCall c) {
  c.getMethodName() =
    [
      "render", "represent", "serialize", "to_json", "as_json",
      "to_a", "present", "paginate", "respond_with"
    ]
}

/**
 * Holds if `limiter` is a .limit() or .paginate() call inside `callable`,
 * providing a bound on the result set size.
 */
predicate hasLimitGuard(Callable callable) {
  exists(MethodCall limiter |
    limiter.getEnclosingCallable() = callable and
    limiter.getMethodName() = ["limit", "paginate", "page", "keyset_paginate"]
  )
}

from MethodCall finder, Callable callable
where
  isArFinderCall(finder) and
  callable = finder.getEnclosingCallable() and
  // The same method also calls a serializer/response helper (it materialises the result)
  exists(MethodCall sink |
    isResponseSink(sink) and
    sink.getEnclosingCallable() = callable
  ) and
  // No .limit() / .paginate() guard anywhere in the same callable
  not hasLimitGuard(callable)
select finder,
  "ActiveRecord query `." + finder.getMethodName() +
    "` result is used in a response/serializer in this method without a .limit(N) or paginate guard; " +
    "add .limit(MAX_N) to prevent unbounded memory exhaustion."
