/**
 * @name Asciidoctor output marked html_safe before Banzai sanitization
 * @description A block or method calls `Asciidoctor.convert()` and then
 *              calls `.html_safe` on an expression that is NOT the direct
 *              result of `Banzai.render()`. If a `Timeout::Error` interrupts
 *              the Banzai sanitization pass, the raw Asciidoctor HTML is
 *              returned as safe, leading to stored XSS. Move `html_safe` to
 *              after `Banzai.render()` and return a safe constant on the
 *              error path.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.7
 * @precision high
 * @id rb/xss-asciidocrawhtmlbeforebanzai
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0810
 * @source-citation derived from GitLab security fix c1a17833 (Asciidoctor html_safe before Banzai sanitization — pipeline ordering bug); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

predicate isAsciidoctorConvert(MethodCall c) {
  c.getMethodName() = "convert" and
  c.getReceiver().(ConstantAccess).getName() = "Asciidoctor"
}

predicate isBanzaiRender(MethodCall c) {
  c.getMethodName() = "render" and
  c.getReceiver().(ConstantAccess).getName() = "Banzai"
}

from MethodCall htmlSafeCall, Callable sharedScope
where
  // html_safe is called somewhere in this callable scope
  htmlSafeCall.getMethodName() = "html_safe" and
  htmlSafeCall.getEnclosingCallable() = sharedScope and
  // the receiver of html_safe is NOT a direct Banzai.render() call
  not isBanzaiRender(htmlSafeCall.getReceiver()) and
  // the same callable scope also contains an Asciidoctor.convert() call
  exists(MethodCall convertCall |
    isAsciidoctorConvert(convertCall) and
    convertCall.getEnclosingCallable() = sharedScope
  )
select htmlSafeCall,
  "html_safe is called in a scope that also calls Asciidoctor.convert() but the receiver is not Banzai.render(); " +
  "if sanitization times out the raw Asciidoctor HTML is returned as safe - move html_safe to after Banzai.render() " +
  "and return a safe constant on the error path."
