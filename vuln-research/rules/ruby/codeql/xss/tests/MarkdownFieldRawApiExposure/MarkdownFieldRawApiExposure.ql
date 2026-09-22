/**
 * @name Grape entity exposes raw *_html field without MarkupHelper re-rendering
 * @description A Grape entity uses `expose :*_html` without a block that calls
 *              `MarkupHelper.markdown_field(...)`, returning cached raw HTML without
 *              user-context-aware sanitization or reference redaction. Wrap the
 *              exposure in a block: `expose :description_html do |obj, opts|
 *              MarkupHelper.markdown_field(obj, :description, current_user: opts[:current_user]) end`.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision medium
 * @id rb/xss-markdown-field-raw-api-exposure
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0812
 * @source-citation derived from GitLab security fix 590b4aea9321 (Use MarkupHelper.markdown_field when exposing *_html fields in API); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds when `call` is `expose :*_html` with a block containing a
 * `MarkupHelper.markdown_field` call — the safe pattern.
 */
predicate hasSafeMarkdownFieldBlock(MethodCall call) {
  exists(Block blk, MethodCall inner |
    blk = call.getBlock() and
    inner.getEnclosingCallable() = blk and
    inner.getMethodName() = "markdown_field" and
    inner.getReceiver().(ConstantReadAccess).getName() = "MarkupHelper"
  )
}

from MethodCall expose, SymbolLiteral fieldSym
where
  expose.getMethodName() = "expose" and
  // First positional argument is a symbol ending in _html
  fieldSym = expose.getArgument(0) and
  fieldSym.getConstantValue().getSymbol().matches("%_html") and
  // The call has NO safe block that calls MarkupHelper.markdown_field
  not hasSafeMarkdownFieldBlock(expose)
select expose,
  "Grape entity exposes `:" + fieldSym.getConstantValue().getSymbol() +
  "` without a MarkupHelper.markdown_field block; cached raw HTML is returned without user-context sanitization, risking XSS."
