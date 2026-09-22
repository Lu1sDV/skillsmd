/**
 * @name GraphQL field skips type-level authorization
 * @description A GraphQL `field` declaration passes a non-empty array to
 *              `skip_type_authorization:`, causing the framework to bypass the
 *              type's standard `authorize` enforcement when resolving that field.
 *              An attacker can traverse the skipped type and read objects they
 *              are not permitted to see. Remove `skip_type_authorization:` to
 *              restore the type-level permission check.
 * @kind problem
 * @problem.severity error
 * @security-severity 7.5
 * @precision high
 * @id rb/auth-session-graphql-skip-type-authorization
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1312
 * @source-citation derived from GitLab security fix 0bb8c45bda09 (Fix unauthorized project exposure via WorkItem GraphQL traversal); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

from MethodCall c, ArrayLiteral arr
where
  // Target the GraphQL DSL `field` method
  c.getMethodName() = "field" and
  // It must have a non-empty skip_type_authorization: [...] keyword argument
  arr = c.getKeywordArgument("skip_type_authorization") and
  arr.getNumberOfElements() > 0
select c,
  "GraphQL field declaration uses skip_type_authorization: with a non-empty scope list, bypassing type-level authorization; remove skip_type_authorization: to restore the permission check."
