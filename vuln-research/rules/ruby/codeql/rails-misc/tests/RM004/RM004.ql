/**
 * @name Regexp literal with unbounded quantifier on character class or group (ReDoS)
 * @description A regular expression literal contains a `+`- or `*`-quantified
 *              character class (`[...]+`, `[...]*`) or capturing group
 *              (`(...)+`, `(...)*`) with no upper bound. Crafted input that
 *              partially matches can cause catastrophic backtracking or
 *              exponent-induced resource exhaustion. Replace the unbounded
 *              quantifier with a bounded one (e.g. `{1,N}`) or anchor the
 *              pattern.
 * @kind problem
 * @problem.severity error
 * @security-severity 5.4
 * @precision medium
 * @id rb/rails-misc-rm-004
 * @tags security
 *       external/cwe/cwe-1333
 * @vr-id RB-QL-2506
 * @source-citation derived from GitLab security fix 74014108b681 (Add limits on autolinker regex) and 3e13e2c38e2a (reject dangerous exponent regex in webhook templates); CWE-1333
 * @license derived-original
 */

import codeql.ruby.AST as AST
import codeql.ruby.Regexp

/**
 * Gets a human-readable label for the operand type.
 * Only holds for the two structural shapes that indicate ReDoS risk:
 * a character class `[...]` or a capturing/non-capturing group `(...)`.
 * Simple escapes like `\w+` or `\d+` are excluded to reduce FP noise on
 * intentional single-token patterns.
 */
string operandKind(InfiniteRepetitionQuantifier quant) {
  quant.getChild(0) instanceof RegExpCharacterClass and result = "character class"
  or
  quant.getChild(0) instanceof RegExpGroup and result = "group"
}

from AST::RegExpLiteral lit, InfiniteRepetitionQuantifier quant, string kind
where
  lit.getParsed() = quant.getRootTerm() and
  kind = operandKind(quant)
select lit,
  "This regexp contains an unbounded '" + quant.getQualifier().charAt(0) +
  "'-quantified " + kind +
  " that can cause catastrophic backtracking (ReDoS); replace with a bounded quantifier such as {1,N}."
