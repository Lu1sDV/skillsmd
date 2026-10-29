# Optimization and Enumeration

## 11. Backtracking

Define a state, candidate-generation rule, validity test, and completion condition. Choose, recurse, and undo every mutable change. Copy accepted paths before storing them.

Specify whether indices or values are unique, whether a candidate may be reused, and how duplicate outputs are suppressed. For reusable sum candidates, require a domain that ensures progress; zero/negative values can make naive remaining-sum recursion nonterminating.

Prune only with a valid lower/upper bound. Define the output for an empty input and target zero. Report the search-tree cost and output-writing cost; separately state recursion/workspace and materialized results.

## 12. Dynamic programming

1. Define exactly what one state means and why it captures all information needed by future choices.
2. Specify base cases, invalid states, recurrence, iteration order, and answer extraction.
3. Choose memoization for reachable-state exploration or tabulation for controlled order and stack safety.
4. Verify the full-state recurrence before reducing dimensions.
5. State state-count × transition-cost time and retained-state space.

For 0/1 knapsack with one dimension, iterate capacities in the direction that prevents reuse of the same item; reusable-item problems have a different dependency structure. Verify that weights, capacities, amounts, and coin denominations satisfy the intended domain.

For LIS, distinguish strictly increasing from nondecreasing. Return the defined empty-sequence length, normally zero. Do not use `Math.max(...dp)` on unbounded arrays. In the tails approach, explain that tails summarize feasible endpoints and do not directly form the recovered subsequence.

Check safe-integer limits when counting arrangements. Avoid using falsy cache values as evidence of absence.

## 13. Greedy

State the local choice, feasibility invariant, and proof that committing to that choice preserves an optimal solution. Use an exchange, dominance, cut, or stays-ahead argument appropriate to the problem.

Try a small counterexample against a brute-force or DP baseline before accepting an unfamiliar greedy rule. Define tie-breaking and input ordering. Include sorting costs.

For jump reachability, maintain the farthest reachable index and reject positions beyond it; define empty input. For gas/cost circuits, check matching lengths and nonempty-input policy and explain why a failed prefix excludes candidate starts in that prefix.

Do not transfer a proof from one objective or constraint set to another without rechecking it.

## 17. Bit manipulation

Define signedness, bit width, integer bounds, and the role of negative values. Number-based bitwise operators use 32-bit integer coercions; shift counts are reduced modulo 32.

Do not use `1 << n` as an unrestricted subset-count bound: it changes sign at bit 31 and wraps the count beyond that. Use backtracking or deliberate bigint masks when needed, while acknowledging exponential output size.

For XOR cancellation, state the multiplicity assumptions and number domain. For population count and power-of-two checks, define the accepted domain before applying a compact identity.

Keep bigint and number operations separate; bigint has no unsigned right-shift operator. Prefer arithmetic over bit tricks when the domain or readability makes the bit representation inappropriate.

## Verification prompts

- Enumerate with duplicate values and verify uniqueness and non-aliasing of stored outputs.
- Check DP at zero, one, unreachable states, and a case where reusing an item would change the answer.
- Compare a claimed greedy rule to exhaustive search on small inputs.
- Exercise zero, signed boundaries, and a bit index outside 0..31.
- Verify that reported memory distinguishes the working state from all returned combinations.

## Sources

- [StructWeave: backtracking](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#11-backtracking)
- [StructWeave: dynamic programming and greedy](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#12-dynamic-programming)
- [StructWeave: bit manipulation](https://github.com/nirajkvinit/StructWeave-Algorithms/blob/e2a796e212d431c906c85957ea3c203ce0e2218f/languages/typescript/04-interview-patterns.md#17-bit-manipulation)
- [ECMAScript Number left-shift semantics](https://tc39.es/ecma262/multipage/ecmascript-data-types-and-values.html#sec-numeric-types-number-leftShift)
