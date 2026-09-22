/**
 * @name Banzai filter calls node.replace() without prior sanitization
 * @description In a Nokogiri-based Banzai filter, `node.replace(html_string)` is
 *              called where the HTML argument was derived from user-controlled wiki
 *              or markdown content without first passing through
 *              `Banzai::Filter::SanitizationFilter.new(html).call`. An attacker can
 *              inject arbitrary HTML that survives the filter pipeline, leading to
 *              stored XSS. Pass the replacement HTML through SanitizationFilter
 *              before replacing the node.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.3
 * @precision medium
 * @id rb/xss-banzai-node-replace-without-sanitization
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0817
 * @source-citation derived from GitLab xss security fixes (shas 068fd0faa9c4,4ba8bee6bb39,af05de9f8d3b); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when the call is in a file under lib/banzai/filter/ (production only,
 * not specs or vendor) — this is the only location where Nokogiri-based Banzai
 * filters call node.replace() on user-generated HTML.
 */
predicate inBanzaiFilterPath(MethodCall c) {
  exists(string path | path = c.getLocation().getFile().getRelativePath() |
    path.matches("lib/banzai/filter/%") and
    not path.matches("spec/%") and
    not path.matches("test/%") and
    not path.matches("vendor/%")
  )
}

/**
 * Holds when `c` is a `node.replace(...)` call whose argument is not a
 * constant/literal value. Literal arguments (hard-coded HTML strings) are safe
 * because they cannot carry attacker-controlled content.
 */
predicate isNonLiteralReplace(MethodCall c) {
  c.getMethodName() = "replace" and
  // Must have exactly one argument (the HTML to inject)
  exists(Expr arg | arg = c.getArgument(0) |
    // Exclude plain string literals and integer literals — they are safe constants.
    not arg instanceof StringLiteral and
    not arg instanceof IntegerLiteral
  )
}

/**
 * Holds when the callable enclosing `c` contains a call to SanitizationFilter
 * (i.e. `SanitizationFilter.new(...)`), indicating the author sanitized before
 * replacing.
 */
predicate hasSanitizationInCallable(MethodCall c) {
  exists(MethodCall san |
    san.getMethodName() = "new" and
    san.getReceiver().(ConstantReadAccess).getName() = "SanitizationFilter" and
    san.getEnclosingCallable() = c.getEnclosingCallable()
  )
}

from MethodCall replace
where
  isNonLiteralReplace(replace) and
  inBanzaiFilterPath(replace) and
  not hasSanitizationInCallable(replace)
select replace,
  "Banzai filter calls node.replace() with potentially user-controlled HTML without prior SanitizationFilter sanitization; " +
  "pass the replacement HTML through Banzai::Filter::SanitizationFilter.new(html).call before replacing the node."
