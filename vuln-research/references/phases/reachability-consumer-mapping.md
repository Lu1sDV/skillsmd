# Reachability & Consumer Mapping — Phase 1.3

> **Load when**: After Decompose / Plan and **before** the Hunt. This phase builds two whole-tree inventories — `reachable_surface` and `consumer_graph` — that the Hunt consumes as a prior and Confirm Gate 1 reads instead of re-deriving per finding.

No phase owns reachability or the consumer graph, so without this phase every finding re-derives both ad-hoc at Confirm time — usually by closing a DAG at the *sink* and stopping, which is why "sink reached" launders into "consumer harmed". Phase 1.3 computes both **once, whole-tree, finding-agnostically** before any hunting, so the Hunt starts with a reachability prior and Confirm reads a shared inventory instead of re-tracing.

This is a heavy lane. On a large target it competes for the budget Confirm needs; cap it (own tier / time box) and build it once per `commit_sha`, not per finding.

---

## Inventory 1 — `reachable_surface` (per source)

For **each** untrusted source (entry point), enumerate the critical functions / sinks **provably reachable** from it under the **default configuration**. The unit is `(source → critical_fn/sink)` with a reachability tier.

```
reachable_surface(source_id, critical_fn_id | sink_id, tier, default_config_gate, evidence_ref)
```

`tier` is one of:

| `tier` | Meaning | Hunt / Confirm consequence |
|---|---|---|
| `proven` | A live attacker-reachable call path traced end-to-end under default config | Full-weight Hunt prior; Confirm Gate 1 = satisfied for this edge |
| `conditional` | Reachable only behind a non-default config flag, an extra privilege, or an unproven precondition | Hunt prior down-weighted; the gate/privilege is recorded as a severity-capping fact |
| `unreachable` | No live path under default config (dead caller, central-planner enforcement upstream, removed path, EOL-only version gate) | A candidate landing here needs an explicit reopen rationale |

Rules that keep the tiering honest:

- **Absence of a local guard ≠ reachable.** A missing local `checkAccess` does not make a function `proven` — enforcement may live in a central planner / router upstream. Trace to the *first* real guard before tiering.
- **Default config is the baseline.** A path that needs a non-default flag is `conditional`, and the flag is carried as a severity-capping precondition — not silently treated as `proven`.
- **Version gates demote to `unreachable`.** A sink exploitable only on an EOL runtime / config the target does not run is `unreachable` here, not a live edge.
- Stamp `default_config_gate` (the flag/privilege/version that the edge depends on) and an `evidence_ref` (the trace artifact) on every non-`proven` row so Confirm reads the gate, not a re-derivation.

## Inventory 2 — `consumer_graph` (per sink)

A sink *reached* is not a consumer *harmed*. For **each** sink (or each tainted value's resting place), enumerate the downstream components that **read / dispatch / trust** its output, and the harm each suffers.

```
consumer_graph(sink_id, consumer_symbol, consumer_action ∈ read|dispatch|trust, harm_class, default_config BOOLEAN, evidence_ref)
```

- `consumer_action` — does a default-config component **read** the tainted bytes, **dispatch** on them (call/branch/route), or **trust** them as an authorization/integrity decision? A sink whose corrupted bytes are read by *no* consumer is the canonical false-HIGH: the DAG closes, but `consumer_graph` has zero rows for it.
- `harm_class` — the concrete consequence (info-leak, RCE, authz-bypass, integrity-violation, availability/DoS), used as the `harm_class` input to the severity rubric (`exploitability-gate.md` § Read-Time Severity Rubric).
- For **sink-less classes** (authz / IDOR / business-logic), the "consumer" is the *privileged operation reached past the broken guard* — the graph still applies: name the operation and the harm.
- A sink with **no default-config consumer** is recorded with zero consumer rows; that is the signal to auto-demote any finding on it to an Observation.

---

## How the Hunt consumes it (as a prior)

The Hunt receives both inventories as input, not as a thing to rebuild:

- **Reachability prior.** Hunt lanes weight their effort by `reachable_surface.tier`: `proven` edges are front-loaded; `conditional` edges are pursued with the gate noted; an `unreachable` edge is *not* hunted by default. A candidate whose sink is `unreachable` carries a mandatory **reopen rationale** (e.g. "the slice moved", "a new caller appeared") — it is not silently re-opened.
- **Consumer prior.** A Hunt lane that flags a sink reads `consumer_graph` for it; if there is no default-config consumer, the lane emits the candidate as an **Observation** with the empty-consumer fact attached, rather than a HIGH finding. This pushes the consumer check *upstream* of Confirm, so the recall-maxed front end stops minting false HIGHs that the back end must then starve to refute.
- The inventories are also a **dedup prior**: an `unreachable`/closed edge is a pre-spawn signal not to fund a lane on that surface (see the ledger-dedup invariant).

## How Confirm Gate 1 reads it

Confirm's reachability gate (Gate 1 of the five-gate doctrine, `references/v2/confirmation-rigor-doctrine.md`) **reads `reachable_surface` instead of re-deriving** a path per finding:

- Gate 1 passes for a finding only if its source→sink edge is `tier='proven'` in `reachable_surface`. A `conditional` edge passes Gate 1 only with its `default_config_gate` carried into the severity computation as a `reachability_cap`. An `unreachable` edge fails Gate 1.
- The **consumer gate** (the terminal "consumer harmed, not sink reached" check) reads `consumer_graph`: a confirmed finding must name a `consumer_symbol` with a default-config `consumer_action`. Zero consumer rows ⇒ auto-demote to Observation.
- Because both gates read a *shared, pre-built* inventory, two findings on the same edge cannot disagree about reachability, and the reachability/consumer facts feed the severity rubric directly (`reachability_cap`, `harm_class`) rather than being re-litigated ad hoc.

The implementation-plan companions are `impact_proofs` (the per-finding consumer/reachability evidence row) and the `closures` table (closed surfaces consulted before spawning); this phase is the inventory those tables key against.
