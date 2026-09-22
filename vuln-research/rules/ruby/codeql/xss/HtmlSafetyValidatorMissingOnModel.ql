/**
 * @name ActiveRecord model attribute missing `html_safety: true` validator
 * @description An ActiveRecord model validates a human-facing string attribute
 *              (name, title, description, bio, etc.) with only standard validators
 *              (presence, length, uniqueness, format) but omits `html_safety: true`.
 *              Without this guard, HTML injected into the attribute is stored and
 *              later rendered unescaped in email templates or HAML views, causing
 *              stored XSS. Add `html_safety: true` to the validates call.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id rb/xss-html-safety-validator-missing-on-model
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0813
 * @source-citation derived from GitLab security fix bd8b58bf861e (HTML injection via achievements email); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * The set of human-facing string attribute names that are rendered in views
 * or emails and therefore require XSS sanitisation.
 */
string humanFacingAttr() {
  result =
    [
      "name", "title", "description", "bio", "note", "notes", "body",
      "content", "message", "comment", "summary", "label", "subject",
      "caption", "text", "header", "footer", "display_name", "full_name",
      "username", "nickname", "tagline", "excerpt"
    ]
}

/**
 * Standard Rails validators that carry no XSS protection.
 */
string standardValidatorKey() {
  result =
    [
      "presence", "length", "uniqueness", "format", "inclusion",
      "exclusion", "numericality", "confirmation", "acceptance",
      "allow_nil", "allow_blank", "on", "if", "unless", "strict",
      "message", "case_sensitive"
    ]
}

/**
 * Holds if `call` is a `validates :attr` call in a model where:
 * - the attribute name is a human-facing string field,
 * - at least one standard validator keyword is present (non-trivial validates),
 * - and the `html_safety:` keyword argument is absent.
 */
predicate isMissingHtmlSafety(MethodCall call, string attrName) {
  call.getMethodName() = "validates" and
  // First argument is a symbol naming the attribute.
  attrName = call.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() and
  // The attribute is a human-facing string field.
  attrName = humanFacingAttr() and
  // At least one standard validator keyword is present — avoids bare `validates :attr`.
  exists(string k |
    k = standardValidatorKey() and
    exists(call.getKeywordArgument(k))
  ) and
  // The html_safety: keyword argument is absent.
  not exists(call.getKeywordArgument("html_safety"))
}

from MethodCall call, string attrName
where isMissingHtmlSafety(call, attrName)
select call,
  "validates :" + attrName +
    " is missing `html_safety: true`; user-supplied HTML stored in this attribute " +
    "may be rendered unescaped in emails or views, causing stored XSS."
