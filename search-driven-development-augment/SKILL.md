---
name: search-driven-development-augment
description: >
  Use when writing, revising, or reviewing index entries for repositories that
  search-driven-development agents route through: deciding which repositories to open,
  skip, or start from. Not for analyzing a single repository's code or for the search
  workflow itself.
---

# Writing repository index entries

## Purpose
The index is the first stop for an agent doing search-driven development. The agent reads
the index, decides which repositories to open, then investigates inside them. An entry has
three jobs:
- get the repository opened for problems it can inform;
- get it skipped for problems it cannot;
- show where exploration should start.

An entry is neither documentation nor evidence. The agent verifies everything in the source.

## Format
One entry per repository: the name in bold, then five paragraphs, about 250–400 words,
always in this order.

1. **What it does.** Plain-language purpose: who uses it, what goes in, what comes out,
   its form (library, CLI, service) and its language/stack. The first sentence must work
   on its own; in a large index it is the line that gets scanned.
2. **Core mechanism.** Follow one input through to its output: the central data structure
   and algorithm, and the main design decision with its cost.
3. **Problem structure.** The problem in structural terms: resource managed, invariant
   preserved, state transitions, failure modes. Add the names the same problem has in
   neighbouring domains. Searches by structure match on this paragraph.
4. **What studying it gives you.** The 2–4 most notable items that are true of this repo:
   - Adopt: code or packages usable as-is, with path and dependencies.
   - Borrow: designs or algorithms worth porting when the code itself doesn't fit.
   - Invariants and edge cases it handles that a first attempt would miss.
   - Lessons paid for: bugs it fixed, approaches it tried and abandoned.
   - Practices: testing strategy, error handling, concurrency patterns, conventions.
   - Weaknesses: what it gets wrong or leaves out, and when that matters.
   - Decisions: deliberate trade-offs and why they were made.
5. **Limits and fit.** Hard assumptions; what it is not for; the cost of adopting it
   (dependencies, services, persistent state, license); maturity as neutral facts; how it
   differs from sibling entries; the path where exploration should start.

## Writing rules
- State facts. Don't address the reader ("always", "make sure"): agents follow such lines
  literally and explore more than needed.
- No adjectives or self-claims: fast, robust, simple, production-ready, best.
- Every sentence must come from something observed in the code, tests, history or issues.
  A README is only a claim until the code confirms it. Include a weakness only if it is
  visible in the code or reported in an issue.
- Leave out anything the agent can find with one search: file trees, module lists, feature
  lists, setup steps, commit IDs, lists of test files.
- Give paths only for starting points and adoptable parts, in backticks.
- Keep the paragraph order and the length similar across entries.
- Entries that share a mechanism must differ in paragraphs 2 and 5. If a reader cannot
  choose between two entries from those paragraphs, rewrite them.

## Analysis workflow
1. **Purpose and form:** read the manifest and README; treat both as claims.
2. **Core mechanism:** trace one real input from the entry point to its output. Check
   paragraph 1 against what the code actually does.
3. **Structure:** name the resource, the invariant and the failure modes; collect the
   neighbouring-domain names for the same mechanism.
4. **What it gives:**
   - bugs and lessons: fix commits and issues (`git log --grep=fix -- <path>`);
   - invariants and practices: the tests, which show what the authors felt they had to
     pin down;
   - decisions and rejected alternatives: ADRs, design docs, PR discussions;
   - weaknesses: open issues, and reading the code for hidden assumptions, missing
     failure handling, races, unbounded work, and complexity that adds nothing;
   - adoptable parts: modules with few imports and their own tests; check their full
     dependency closure.
5. **Limits:** read the assumptions from the code (global state, single process, platform,
   workload). Note dependencies, services, persistent state, license, and release and
   maintenance history.
6. **Write** in the fixed order. Compare with sibling entries and sharpen paragraphs 2 and 5.
7. **Routing test:** give a fresh agent only the full index and a set of probe tasks, and
   check that it opens the right repositories and skips the rest. Cover:
   - a task the repository solves as a whole;
   - a task that needs only one of its parts;
   - an edge-case or invariant question;
   - a "what mistakes should we avoid" question;
   - a testing or practices question;
   - near-miss tasks it must skip.

   Rewrite entries that lead to wrong picks or that force the agent to open several
   repositories before it can decide.
8. **Maintenance:** revisit an entry when the repository's mechanism, form or limits
   change, or when new fixes or issues add a lesson. Other changes do not affect it.

## Example (fictional repository)

> **ratelim**
>
> Rust library that limits how often each client (API key, IP, user) may call an endpoint,
> returning allow or deny with a retry-after delay. It is embedded in-process by HTTP
> servers and gateways.
>
> It uses GCRA: each key stores one timestamp, its theoretical arrival time (TAT). A
> request is admitted when `now >= TAT - burst_tolerance`, and admission advances TAT by
> one emission interval. This was chosen over a token bucket to keep one integer per key
> and avoid a refill timer, giving O(1) checks; the cost is that "tokens remaining" must be
> derived rather than read.
>
> Structurally it is admission control on a shared resource over a time window: rate
> invariant per key, burst tolerance, failure on clock jumps and on overflow over long
> periods. The same mechanism is called token bucket, leaky bucket or GCRA in network
> traffic shaping.
>
> Worth studying for: overflow-safe duration arithmetic on long periods, and the fix for
> miscounted bursts at window boundaries, both from bugs it hit; burst tolerance expressed
> as a time offset rather than a token count; property tests that check the admitted rate
> against a reference model under random arrivals. The sharded key map in `src/table.rs`
> is usable on its own. Weakness: idle-key eviction is a periodic full scan that stalls
> with millions of keys; avoid copying it for high-cardinality keys.
>
> It assumes a single process with in-memory state, lost on restart, and uses a monotonic
> clock. MIT-licensed, no dependencies beyond std, 14 releases through 2026-08. Unlike
> **quotad**, which shares limits across replicas through Redis, it cannot enforce one
> limit across several instances. Start at `src/gcra.rs`.
