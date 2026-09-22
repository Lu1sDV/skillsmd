/**
 * @name GraphQL field missing authorize keyword
 * @description A GraphQL field declaration for a sensitive resource type lacks the
 *              `authorize:` keyword argument, which means the field is accessible to
 *              any caller who can reach the parent type — even unprivileged users.
 *              Add `authorize: :read_<resource>` to enforce per-field access control.
 * @kind problem
 * @problem.severity error
 * @security-severity 6.5
 * @precision medium
 * @id rb/auth-session-graphql-field-missing-authorize
 * @tags security
 *       external/cwe/cwe-862
 * @vr-id RB-QL-1310
 * @source-citation derived from GitLab security fixes 196c2ee92ee6 (compliance frameworks), 386b19160aef (deployment job), 00cc23a68e37 (runner maintenance note), 37106cf504e1 (pipeline schedule inputs); CWE-862
 * @license derived-original
 */

import codeql.ruby.AST

/**
 * Holds if `c` is enclosed in a class whose name ends with `Type` or `Object`
 * — the conventional base for GraphQL field declarations in Ruby graphql-ruby.
 * This is the structural discriminator used instead of a file-path filter, which
 * would exclude test fixtures.
 */
private predicate inGraphqlTypeClass(MethodCall c) {
  exists(ClassDeclaration cls |
    c.getEnclosingModule() = cls and
    (
      cls.getName().matches("%Type") or
      cls.getName().matches("%Object")
    )
  )
}

/**
 * A `field` call whose type argument or field name signals a sensitive resource.
 * We check both the first positional argument (field name — symbol or string) and
 * the second positional argument (type constant name), using LIKE patterns matching:
 * variable, input, secret, setting, token, credential, key (case-insensitive).
 */
private predicate hasSensitiveName(MethodCall c) {
  // Field name (first positional arg — symbol)
  exists(string sym |
    sym = c.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() and
    (
      sym.matches("%variable%") or
      sym.matches("%input%") or
      sym.matches("%secret%") or
      sym.matches("%setting%") or
      sym.matches("%token%") or
      sym.matches("%credential%") or
      sym.matches("%key%")
    )
  )
  or
  // Field name (first positional arg — string literal)
  exists(string s |
    s = c.getArgument(0).(StringLiteral).getConstantValue().getString() and
    (
      s.matches("%variable%") or
      s.matches("%input%") or
      s.matches("%secret%") or
      s.matches("%setting%") or
      s.matches("%token%") or
      s.matches("%credential%") or
      s.matches("%key%")
    )
  )
  or
  // Type argument (second positional arg — rightmost constant in a scope chain)
  exists(ConstantAccess typeArg |
    typeArg = c.getArgument(1) and
    (
      typeArg.getName().matches("%Variable%") or
      typeArg.getName().matches("%Input%") or
      typeArg.getName().matches("%Secret%") or
      typeArg.getName().matches("%Setting%") or
      typeArg.getName().matches("%Token%") or
      typeArg.getName().matches("%Credential%") or
      typeArg.getName().matches("%Key%")
    )
  )
}

from MethodCall c
where
  // Must be a call named `field`
  c.getMethodName() = "field" and
  // Must be inside a GraphQL type/object class
  inGraphqlTypeClass(c) and
  // The field has a sensitive name or type
  hasSensitiveName(c) and
  // No `authorize:` keyword argument present
  not exists(c.getKeywordArgument("authorize"))
select c,
  "GraphQL field '" + c.getArgument(0).(SymbolLiteral).getConstantValue().getSymbol() +
  "' in a sensitive type is missing an `authorize:` keyword; add `authorize: :read_<resource>` to enforce per-field access control."
