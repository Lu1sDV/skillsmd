# Oracles — Turning Generated Programs into Bug Signals (FuzzGPT §3.3)

Run each generated program, then apply oracles. General oracles apply to any
target; the differential oracles below are DL-specific — swap them for a
target-appropriate differential/metamorphic oracle when generalizing.

## 1. Crashes (general — always applicable)

Detect bugs from **unexpected crashes** during execution:
- aborts
- segmentation faults
- `INTERNAL_ASSERT_FAILED` (and similar internal invariant failures)

Crashes are the cheapest, most portable signal and approximate bug-finding
capability well — the paper uses **unique crashes** as the head-to-head metric vs
TitanFuzz. Crashes may further escalate into **security vulnerabilities** (the
paper found 11 high-priority/security bugs this way).

## 2. CPU/GPU differential oracle (wrong-computation)

Run the same program on **two backends (CPU and GPU)** and flag **inconsistent
output values**. Use a **significance tolerance threshold** for the comparison to
account for the legitimately non-deterministic nature of some operations across
backends (following FreeFuzz / TitanFuzz). Catches silent numerical bugs a crash
oracle misses.

## 3. Automatic Differentiation (AD) differential oracle

Targets bugs in the **autodiff engine** (critical for training). Compare the
computed gradient across three modes (oracle from ∇Fuzz [Yang et al.]):
- **reverse-mode AD** (the common default in DL libs)
- **forward-mode AD**
- **numerical differentiation (ND)**

Disagreement beyond tolerance = gradient-computation bug. In the paper, **30 of 49**
confirmed new bugs were AD-related — don't skip this oracle if the target has an
autodiff engine.

## Validity filter (needed before/with oracles)

A generated program is a **unique valid program** if it (a) executes **without
exceptions** AND (b) **actually exercises the target fuzz target at least once**
(invokes the API, hits the code path, parses the field, …), after
**deduplication**. Track valid programs separately from crashes — valid-rate is a
core metric (see `evaluation.md`) and an exception is not automatically a bug
(could be a legitimately rejected input).

## Generalizing the oracles to non-DL targets

| Target type | Crash oracle | Differential / metamorphic replacement for CPU-GPU + AD |
|-------------|--------------|---------------------------------------------------------|
| Compiler / interpreter | abort/segfault/ICE | EMI (equivalence-modulo-inputs); same program at `-O0` vs `-O2` |
| DB system | server crash | same query across engines / optimization levels; result-set equivalence |
| SMT solver | crash | sat/unsat agreement across solvers; type-aware operator mutations |
| Any library | unhandled crash | reference implementation differential, or known invariants/metamorphic relations |

Crash detection ports unchanged; the differential oracle is the part you redesign
per target.
