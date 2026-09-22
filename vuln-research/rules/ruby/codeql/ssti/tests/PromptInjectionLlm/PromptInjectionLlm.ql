/**
 * @name LLM prompt injection via unsanitized user content in AI context
 * @description User-controlled content (e.g. issue notes, comments) is embedded
 *              directly into an LLM prompt string via `format(...)` with a
 *              `<comment>` XML wrapper without a preceding `Sanitize.fragment`
 *              or equivalent HTML-stripping step. An attacker can inject HTML or
 *              prompt-control directives that the LLM may act on. Fix: sanitize
 *              the content with `Sanitize.fragment(content, Sanitize::Config::RELAXED)`
 *              before embedding it into the prompt, and add system-prompt
 *              instructions to refuse acting on comment content.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/ssti-prompt-injection-llm
 * @tags security
 *       external/cwe/cwe-94
 * @vr-id RB-QL-0904
 * @source-citation derived from GitLab security fix 9e867d1f78e0 (ssti-prompt-injection-llm); CWE-94
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `fmtCall` is a `format(...)` (or `sprintf(...)`) call whose first
 * argument (the format string) contains the substring `<comment>`, indicating
 * the call is building an LLM prompt that wraps user content in XML tags.
 */
predicate isLlmCommentFormatCall(MethodCall fmtCall) {
  fmtCall.getMethodName() = ["format", "sprintf"] and
  exists(StringLiteral tmpl |
    tmpl = fmtCall.getArgument(0) and
    tmpl.getConstantValue().getString().matches("%<comment>%")
  )
}

/**
 * Holds if `sanitizeCall` is a call to `Sanitize.fragment(...)`,
 * which strips dangerous HTML before embedding into a prompt.
 */
predicate isSanitizeFragmentCall(MethodCall sanitizeCall) {
  sanitizeCall.getMethodName() = "fragment" and
  sanitizeCall.getReceiver().(ConstantReadAccess).getName() = "Sanitize"
}

from MethodCall fmtCall
where
  isLlmCommentFormatCall(fmtCall) and
  // No Sanitize.fragment call exists in the same enclosing callable
  not exists(MethodCall sanitizeCall |
    isSanitizeFragmentCall(sanitizeCall) and
    sanitizeCall.getEnclosingCallable() = fmtCall.getEnclosingCallable()
  )
select fmtCall,
  "User content is embedded into an LLM prompt via `format(...)` with a `<comment>` wrapper " +
    "without a prior `Sanitize.fragment` call; an attacker can inject prompt-control directives. " +
    "Sanitize the content with `Sanitize.fragment(content, Sanitize::Config::RELAXED)` first."
