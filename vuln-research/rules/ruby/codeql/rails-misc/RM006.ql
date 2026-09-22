/**
 * @name YAML.safe_load called without prior bytesize guard
 * @description Calling `YAML.safe_load` (or `Psych.safe_load`) on input that
 *              has not been checked with `.bytesize` allows a malicious actor to
 *              supply extremely large YAML documents with deeply-nested anchors or
 *              aliases, exhausting memory before the parser can reject the payload.
 *              Add a `raise ... if content.bytesize > max_yaml_size_bytes` guard
 *              immediately before the `YAML.safe_load` call.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-rm-006
 * @tags security
 *       external/cwe/cwe-400
 * @vr-id RB-QL-2518
 * @source-citation derived from GitLab security fixes 168d025cd585,ff1a7d16d5af (Validate YAML size before parsing to prevent DoS); CWE-400
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a call to `YAML.safe_load`, `Psych.safe_load`, or `YAML.load`
 * on a constant receiver (i.e. the canonical form, not a method-chained variant).
 */
predicate isYamlLoadCall(MethodCall c) {
  c.getMethodName() = ["safe_load", "load"] and
  c.getReceiver().(ConstantReadAccess).getName() = ["YAML", "Psych"]
}

/**
 * Holds if `guard` is a `.bytesize` call present in the same callable as `yamlCall`.
 * This approximates "there is a size-check before the parse" without requiring
 * full taint flow.
 */
predicate hasBytesizeGuard(MethodCall yamlCall) {
  exists(MethodCall guard |
    guard.getMethodName() = "bytesize" and
    guard.getEnclosingCallable() = yamlCall.getEnclosingCallable()
  )
}

from MethodCall c
where
  isYamlLoadCall(c) and
  not hasBytesizeGuard(c)
select c,
  "Call to `" + c.getReceiver().(ConstantReadAccess).getName() + "." + c.getMethodName() +
    "` without a `bytesize` size-check in the same method. A large malicious payload can " +
    "exhaust memory before parsing completes. Add `raise ... if content.bytesize > max_yaml_size_bytes` before this call."
