/**
 * @name GraphQL mutation passes skip_authorization: true to service — bypasses auth guard
 * @description A hash merge in a GraphQL mutation resolver includes `skip_authorization: true`,
 *              which disables the service object's internal `can?` check and allows
 *              unprivileged or unauthenticated callers to execute the underlying operation.
 *              Remove `skip_authorization: true` from the params passed to the service.
 * @kind problem
 * @problem.severity error
 * @security-severity 8.1
 * @precision high
 * @id rb/auth-session-graphql-skip-authorization-service-flag
 * @tags security
 *       external/cwe/cwe-285
 * @vr-id RB-QL-1316
 * @source-citation derived from GitLab security fix 1b19c469feb7 (Approval rule lock bypass via GraphQL mutations); CWE-285
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is a call to `merge` or `merge!` that includes
 * `skip_authorization: true` as a keyword argument.
 */
predicate hasMergeWithSkipAuthorization(MethodCall c) {
  c.getMethodName() = ["merge", "merge!"] and
  exists(BooleanLiteral b |
    b = c.getKeywordArgument("skip_authorization") and
    b.isTrue()
  )
}

from MethodCall c
where hasMergeWithSkipAuthorization(c)
select c,
  "Hash merge passes `skip_authorization: true` to a service call, disabling the service's `can?` authorization guard. Remove `skip_authorization: true` from the params."
