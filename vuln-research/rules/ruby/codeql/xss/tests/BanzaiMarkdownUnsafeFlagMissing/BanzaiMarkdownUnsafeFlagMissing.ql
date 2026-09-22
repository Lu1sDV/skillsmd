/**
 * @name Banzai/GlfmMarkdown renderer configured with `unsafe: true`
 * @description A hash literal or options hash passed to a Banzai/CommonMark
 *              markdown renderer sets `unsafe: true`, which disables raw-HTML
 *              stripping and lets user-supplied HTML tags pass through the
 *              CommonMark renderer unsanitised, leading to stored or reflected
 *              XSS. Replace with a context-guarded expression such as
 *              `unsafe: !raw_html_disabled?` and ensure callers set
 *              `context[:disable_raw_html]` when handling user input.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id rb/xss-banzai-markdown-unsafe-flag-missing
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0806
 * @source-citation derived from GitLab xss security fixes (shas 049504cecf62,90a990814d75); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when `pair` is a `unsafe: true` key-value pair in a hash or
 * keyword-argument position.
 */
predicate isUnsafeTruePair(Pair pair) {
  pair.getKey().(SymbolLiteral).getConstantValue().getSymbol() = "unsafe" and
  pair.getValue().(BooleanLiteral).isTrue()
}

/**
 * Holds when `pair` is within a source file under `lib/` or `app/` and NOT
 * under `spec/`, `test/`, or `vendor/` — avoiding test-fixture false positives.
 */
predicate inProductionPath(Pair pair) {
  exists(string path | path = pair.getLocation().getFile().getRelativePath() |
    (path.matches("lib/%") or path.matches("app/%")) and
    not path.matches("spec/%") and
    not path.matches("test/%") and
    not path.matches("vendor/%")
  )
}

from Pair unsafePair
where
  isUnsafeTruePair(unsafePair) and
  inProductionPath(unsafePair)
select unsafePair,
  "The `unsafe: true` option enables raw HTML pass-through in the markdown renderer; " +
  "use `unsafe: !raw_html_disabled?` and set `context[:disable_raw_html]` for user-supplied content to prevent XSS."
