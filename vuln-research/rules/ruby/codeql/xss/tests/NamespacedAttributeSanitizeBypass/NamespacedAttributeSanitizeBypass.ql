/**
 * @name Sanitize transformer accesses node attributes without checking namespaced attributes
 * @description A Banzai/Sanitize transformer method reads or mutates HTML node
 *              attributes via `.attributes` (a local-name-keyed hash) but never
 *              calls `.attribute_nodes` to inspect namespace-qualified attributes
 *              such as `xlink:href`. The HTML5 parser produces namespaced attribute
 *              nodes inside SVG/MathML foreign content; these share a local name
 *              with plain HTML attributes but live in a separate XML namespace.
 *              Accessing `node['href']` only affects one of the two, so a
 *              `javascript:` URL carried in `xlink:href` can survive sanitisation.
 *              Add an `attribute_nodes.each { |a| a.remove if a.namespace }` pass
 *              before other attribute mutations.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/xss-namespaced-attribute-sanitize-bypass
 * @tags security
 *       external/cwe/cwe-79
 * @vr-id RB-QL-0814
 * @source-citation derived from GitLab security fix f06762cfa84b (Remove all namespaced attributes in BaseSanitizationFilter); CWE-79
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `nodeExpr` is an expression that resolves a Sanitize `env` hash to
 * `:node`, i.e. it is a bracket-access of the form `env[:node]` or an access on
 * any variable named `node`.
 *
 * We match both shapes:
 *   (a) `env[:node]`  — ElementReference where the key literal is `:node`
 *   (b) any call chain rooted at a local/param variable named `node`
 */
predicate isNodeAccess(Expr nodeExpr) {
  // Shape (a): env[:node] — an ElementReference whose index is the symbol :node
  exists(ElementReference er |
    er = nodeExpr and
    er.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "node"
  )
  or
  // Shape (b): variable named "node"
  nodeExpr.(LocalVariableReadAccess).getVariable().getName() = "node"
  or
  // Shape (c): method parameter named "node"
  nodeExpr.(MethodCall).getMethodName() = "node"
}

/**
 * Holds if `attrCall` is a `.attributes` call whose receiver is a node expression.
 * This is the pattern that reads only unnamespaced attributes.
 */
predicate isAttributesCall(MethodCall attrCall) {
  attrCall.getMethodName() = "attributes" and
  isNodeAccess(attrCall.getReceiver())
}

/**
 * Holds if `attrNodesCall` is a `.attribute_nodes` call anywhere in callable `c`.
 * Presence of this call means the method already handles namespaced attributes.
 */
predicate hasAttributeNodesCall(Callable c) {
  exists(MethodCall anc |
    anc.getMethodName() = "attribute_nodes" and
    anc.getEnclosingCallable() = c
  )
}

from MethodCall attrCall
where
  isAttributesCall(attrCall) and
  // The method processes attributes but never guards against namespaced ones
  not hasAttributeNodesCall(attrCall.getEnclosingCallable())
select attrCall,
  "This call reads `.attributes` (local-name-keyed hash) without a corresponding " +
  "`.attribute_nodes` check; namespaced attributes such as `xlink:href` are invisible " +
  "to this accessor and may carry dangerous values (e.g. `javascript:` URLs) through " +
  "sanitisation. Add `attribute_nodes.each { |a| a.remove if a.namespace }` before " +
  "processing attributes."
