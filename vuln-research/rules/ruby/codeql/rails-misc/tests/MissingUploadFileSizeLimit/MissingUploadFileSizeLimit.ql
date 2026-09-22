/**
 * @name Rails controller upload action missing file-size limit guard
 * @description A Rails controller accesses an uploaded file's tempfile without a
 *              `before_action` that enforces a size limit. Accepting unbounded uploads
 *              allows attackers to exhaust server memory and disk, causing denial of
 *              service. Add a `before_action` that checks `params[:file].tempfile.size`
 *              against a constant before processing the upload.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-missing-upload-file-size-limit
 * @tags security
 *       external/cwe/cwe-400
 *       external/cwe/cwe-770
 * @vr-id RB-QL-2511
 * @source-citation derived from GitLab security fix 5ffaddcf (manifest import file-size guard); CWE-400/770
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `tempfileCall` is a call to `.tempfile` whose receiver is (directly or
 * transitively) derived from a `params` access — i.e. `params[:x].tempfile` or
 * `params[:x].tempfile.size`, etc.
 */
predicate isParamsTempfileAccess(MethodCall tempfileCall) {
  tempfileCall.getMethodName() = "tempfile" and
  // The direct receiver is an element-reference on `params`, e.g. params[:manifest]
  tempfileCall.getReceiver().(ElementReference).getReceiver().(MethodCall).getMethodName() = "params"
}

/**
 * Holds if `ba` is a `before_action` (or `before_filter`) call in `cls` whose
 * first symbol argument contains a size- or file-check hint.
 */
predicate hasSizeLimitBeforeAction(ClassDeclaration cls, MethodCall ba) {
  ba.getEnclosingModule() = cls and
  ba.getMethodName() = ["before_action", "before_filter"] and
  exists(SymbolLiteral sym |
    sym = ba.getAnArgument() and
    (
      sym.getConstantValue().getSymbol().matches("%size%") or
      sym.getConstantValue().getSymbol().matches("%limit%") or
      sym.getConstantValue().getSymbol().matches("%check_file%") or
      sym.getConstantValue().getSymbol().matches("%file_size%")
    )
  )
}

from MethodCall tempfileCall, ClassDeclaration ctrl
where
  isParamsTempfileAccess(tempfileCall) and
  ctrl = tempfileCall.getEnclosingModule() and
  not hasSizeLimitBeforeAction(ctrl, _)
select tempfileCall,
  "Uploaded file accessed via .tempfile in this controller without a size-limiting before_action; " +
  "add a before_action that checks params[:file].tempfile.size against a maximum."
