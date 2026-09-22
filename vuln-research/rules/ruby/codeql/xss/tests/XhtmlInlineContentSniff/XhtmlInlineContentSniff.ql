/**
 * @name XHTML inline Content-Disposition without extension stripping
 * @description A call to `ContentDisposition.format` uses `disposition: 'inline'`
 *              with a non-nil filename, allowing Safari/iOS to sniff a `.xhtml` file
 *              as XHTML and execute embedded scripts. Strip the `.xhtml` extension
 *              before passing the filename (or pass `nil`) when serving inline content.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.1
 * @precision high
 * @id rb/xss-xhtml-inline-content-sniff
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0807
 * @source-citation derived from GitLab security fixes 07d5d2a09497 09d9235e3ebd 836d5100c658 (xhtml inline content-sniffing XSS); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c
where
  // Must be a call to `format` ...
  c.getMethodName() = "format" and
  // ... on a receiver named `ContentDisposition` (handles both the bare constant and
  //     `ActionDispatch::Http::ContentDisposition`)
  c.getReceiver().(ConstantReadAccess).getName() = "ContentDisposition" and
  // The `disposition:` keyword argument is the symbol or string 'inline'
  exists(Expr disp |
    disp = c.getKeywordArgument("disposition") and
    disp.getConstantValue().getStringlikeValue() = "inline"
  ) and
  // The `filename:` keyword argument is present and is NOT a nil literal
  // (nil means the extension was already stripped; any other value is suspect)
  exists(Expr fname |
    fname = c.getKeywordArgument("filename") and
    not fname instanceof NilLiteral
  )
select c,
  "ContentDisposition.format called with disposition:'inline' and a non-nil filename; " +
  "if the filename ends with .xhtml, Safari/iOS will sniff the content as XHTML and may execute scripts. " +
  "Strip the .xhtml extension (or pass filename: nil) before serving inline content."
