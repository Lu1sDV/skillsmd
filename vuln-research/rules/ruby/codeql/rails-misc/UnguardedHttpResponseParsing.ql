/**
 * @name HTTParty::Parser subclass missing Content-Type-agnostic parse override
 * @description A class that inherits from `HTTParty::Parser` customises JSON
 *              parsing (e.g. via a `json` override that enforces size limits) but
 *              does not override `parse`. A malicious server can return a large JSON
 *              payload with a non-JSON Content-Type (e.g. `text/plain`), bypassing
 *              the custom `json` method and causing unbounded memory allocation
 *              (DoS). Override `parse` to detect JSON-like bodies regardless of the
 *              Content-Type header.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/rails-misc-unguarded-http-response-parsing
 * @tags security
 *       external/cwe/cwe-400
 *       external/cwe/cwe-20
 * @vr-id RB-QL-2520
 * @source-citation derived from GitLab security fix b6249fd4c011 (DoS via Jira import Content-Type bypass in HTTParty::Parser subclass); CWE-400/20
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `cls` directly inherits from `HTTParty::Parser` (written as
 * `HTTParty::Parser` in the source).
 */
predicate inheritsHttpartyParser(ClassDeclaration cls) {
  exists(ConstantReadAccess base, ConstantReadAccess ns |
    base = cls.getSuperclassExpr() and
    base.getName() = "Parser" and
    ns = base.getScopeExpr() and
    ns.getName() = "HTTParty"
  )
}

/**
 * Holds if `cls` defines an instance method named `json` or
 * `validate_response_size!`, indicating it is a custom parser that
 * enforces size/depth limits — but only for known content-types.
 */
predicate hasCustomJsonParsing(ClassDeclaration cls) {
  exists(Method m |
    cls.getAMethod() = m and
    m.getName() = ["json", "validate_response_size!", "validate_response_size"]
  )
}

/**
 * Holds if `cls` defines an instance method named `parse`, which is the
 * guard that routes JSON-like bodies through the custom `json` method
 * regardless of Content-Type.
 */
predicate hasParseOverride(ClassDeclaration cls) {
  exists(Method m |
    cls.getAMethod() = m and
    m.getName() = "parse"
  )
}

from ClassDeclaration cls
where
  inheritsHttpartyParser(cls) and
  hasCustomJsonParsing(cls) and
  not hasParseOverride(cls)
select cls,
  "HTTParty::Parser subclass '" + cls.getName() +
    "' overrides `json` (with size/depth limits) but does not override `parse`. " +
    "A server returning JSON with a non-JSON Content-Type bypasses this check, " +
    "enabling unbounded memory allocation. Override `parse` to route JSON-like " +
    "bodies through `json` regardless of Content-Type."
