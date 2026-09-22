/**
 * @name CSV export missing newline replacement (formula injection via newlines)
 * @description A call to `CsvBuilder.new` does not pass `replace_newlines: true`,
 *              so embedded newlines in cell values break CSV row boundaries and
 *              allow injection of leading `=`/`+`/`-` formula characters into
 *              adjacent cells. Pass `replace_newlines: true` to sanitize output.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-csv-formula-injection-newlines
 * @tags security
 *       external/cwe/cwe-1236
 * @vr-id RB-QL-2509
 * @source-citation derived from GitLab security fix 6bf822e17040 (escape newlines from vulnerability export); CWE-1236
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c
where
  c.getMethodName() = "new" and
  c.getReceiver().(ConstantReadAccess).getName() = "CsvBuilder" and
  // Missing the safe keyword: replace_newlines: true
  not exists(BooleanLiteral b |
    b = c.getKeywordArgument("replace_newlines") and
    b.isTrue()
  )
select c,
  "CsvBuilder.new called without `replace_newlines: true`; embedded newlines in cell values " +
  "can break CSV row boundaries and inject formula characters in adjacent cells."
