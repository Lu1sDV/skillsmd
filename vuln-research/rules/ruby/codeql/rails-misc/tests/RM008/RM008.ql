/**
 * @name Grape::Entity exposes CI variable value without masking block
 * @description A Grape::Entity subclass that serializes CI variable objects calls
 *              `expose :value` without a block, returning the raw secret value in API
 *              responses even when the variable is hidden or masked. Wrap the expose
 *              in a block and gate on `variable.respond_to?(:hidden)` with
 *              `Ci::VariableValue.new(variable).evaluate` to suppress masked values.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision high
 * @id rb/rails-misc-rm-008
 * @tags security
 *       external/cwe/cwe-200
 * @vr-id RB-QL-2508
 * @source-citation derived from GitLab security fix 1bd9033103a4 (Use CI::VariableValue in BasicEntity to prevent exposing hidden values); CWE-200
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c, ClassDeclaration cls
where
  // The call is `expose :value`
  c.getMethodName() = "expose" and
  c.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() = "value" and
  // It lives inside a CI variable entity serializer class
  c.getEnclosingModule() = cls and
  cls.getName().matches("%Variable%Entity") and
  // No inline block — `expose :value do ... end` is the safe (fixed) shape
  not c.hasBlock()
select c,
  "Bare `expose :value` in CI variable serializer '" + cls.getName() +
  "' leaks the raw secret in API responses. Wrap in a block and use " +
  "`Ci::VariableValue.new(variable).evaluate` to mask hidden/masked variables."
