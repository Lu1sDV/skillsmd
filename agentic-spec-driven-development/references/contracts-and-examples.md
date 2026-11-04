# Contracts and examples

Use when drafting ambiguous requirements, quality targets or risky effects, or when the
four core questions leave consequential behavior ambiguous. These are original
illustrative contracts, not defaults to copy into an unrelated product. Numbers, error
codes and operational policies require the actual owner's agreement.

## A compact optional shape

```markdown
# Change: <name>
Intent and scope: <observable change; relevant preserved behavior/non-goals>
Basis: <owner request or adopted contract; observed behavior is labelled separately>
Rules and examples: <conditions, outcomes and observation points>
Open decisions: <choice; affected work; who can decide>
Acceptance: <what evidence would establish the obligations, and known limits>
```

Omit unnecessary headings. Add an invariant, quality target, migration or trace link
only when it helps resolve a real obligation. Reuse the project's existing format.
This is not a new schema, approval record or requirement to create a file.

## Discover before specifying

Inspect existing consumers and contracts before proposing behavior. Distinguish:

- **Observed:** the current implementation rounds each line item down.
- **Intended:** the adopted accounting rule rounds the invoice total once.
- **Unknown:** whether an external consumer relies on the old invoice values.

A snapshot test agreeing with the implementation establishes neither intended behavior
nor permission to break a consumer. An authorized repair may already cover the change;
otherwise expose the consequence and obtain the decision. Do not reverse-engineer the
whole system just to specify a bounded delta.

For a multi-capability request, map capabilities, consumers and shared obligations before
writing a monolithic spec. Dependency cycles signal an unresolved boundary to examine,
not an automatic instruction to merge modules. Split only where outcomes are independently
meaningful; preserve every requested capability unless the owner agrees to remove it.

## Example 1: login rate limiting with an open trust decision

**Request:** add a limit to an existing login route. The owner has agreed to five
failed attempts per account in a rolling minute; the service is behind a reverse proxy.

**Contract already settled:**
- Attempts below the agreed limit preserve the existing authentication response.
- After the limit, return the agreed rate-limit response without issuing a session.

**Still to resolve:** recovery after the window, successful-login handling and concurrent
attempt accounting must follow the owner's policy, not an invented library default.

**Discovery:** the proxy supplies `X-Forwarded-For`, but the trusted-proxy configuration
and origin reachability are unclear. An IP component of the policy would be attacker-
controlled if arbitrary clients could supply that header.

**Ask the actual gap:** is the limit account-only, or does it include a client-address
policy, and what trusted boundary establishes that address? Look up deployment facts
before asking the owner to supply them.

**While blocked:** characterize the existing route and specify the already-agreed account
behavior. Do not choose proxy trust or add an abstraction merely to look productive.
Continue implementation only where it stays valid under the concrete pending options.

**Acceptance:** exercise the route with agreed account/window cases and concurrent attempts
where applicable. If client-address behavior is included, test the actual proxy trust
boundary; a unit stub returning a trusted address cannot establish it.

## Example 2: concurrent partial refunds

**Assumed owner-approved policy for this example:** a captured payment permits partial
refunds in its original currency. Requests have an idempotency key; same-key/same-body
replay returns the recorded outcome; same-key/different-body reuse is rejected. The
retention window for keys and reconciliation after gateway uncertainty are explicit
owner decisions, not universal payment semantics.

**Starting state:** captured 100 units, already refunded 70, available 30.

| Condition | Required business outcome | Observation |
|---|---|---|
| A permitted 20-unit refund completes | One additional refund; refunded total 90 | Public payment/refund view and payment provider boundary |
| Two independent permitted 30-unit requests race and reach terminal outcomes with dependencies available | Exactly one succeeds; either may win; the other gets the agreed insufficient-availability outcome | Combined effects after both settle |
| Same key/body is retried | No second refund or money movement | Consumer-visible refund list and provider effect count, not just equal response bodies |
| Currency mismatch, invalid amount or unauthorized caller | Defined rejection, no unauthorized refund | State and provider effects; authorized audit/metrics may still occur |
| Provider accepted but the response was lost | Agreed pending/reconciliation behavior; no invented success | Failure injection at the provider/persistence boundary |

Separate obligations:
- **Safety:** total refunded never exceeds captured; effects are not duplicated.
- **Cardinality:** the allowed number of accepted business effects is explicit.
- **Progress:** under stated healthy conditions, valid work is not simply refused forever.
- **Nondeterminism:** either concurrent request may win; do not require arrival order unless promised.

The cap alone accepts a refuse-everything implementation, and can miss a duplicate small
refund that stays under the cap. A test suite must discriminate the relevant wrong
outcomes collectively. An internal table layout is not the contract merely because it
is easy to assert. A database is the correct observation point when durable storage
itself is the promised boundary; otherwise prefer the consumer-visible interface.

## Example 3: retention amendment in an existing system

**Current contract:** logs older than 30 days are deleted; legal-hold records are exempt.
**New owner instruction:** make retention seven days. Existing tasks/tests still say 30.

Amend the existing obligation in place and preserve its change history. The clear new
instruction authorizes the new threshold; it does not answer whether existing 8–30-day
records should be immediately purged. Ask that rollout question, recording affected work.

- For records created after the policy takes effect, a non-held eight-day record is deleted.
  Treatment of pre-existing records remains subject to the pending rollout decision.
- A six-day record remains.
- A legal-hold record remains regardless of age.
- Exactly-at-threshold and timezone rules follow the adopted contract; clarify them if absent.
- The old 29-day-preservation expectation must change with a cited approved basis.
  Marking it expected-fail merely to keep a green suite does not implement the amendment.

Invalidate evidence that depended on the old threshold; update affected workers and
superseded tasks. A passing local database check is local evidence. If staging or recovery
is required but unavailable, report it unverified and do not infer rollout permission.

## Example 4: a new project with an adopted external schema

**Request:** build a small event-signup tool in an empty repository. The owner has adopted
a partner's event-file schema and says: “You pick the technology; keep running costs low.”

- **Adopted bases:** the partner schema and the cost instruction. Honor the schema; do not
  design one because nothing local parses it. Whether `event_code` is unique and what its
  date columns mean are facts to establish. If the schema is unreachable, report
  “blocked: import until the schema is obtained; tried <sources>” and ask the owner only
  for the document or access.
- **Delegated:** local technology, recorded with a one-line reason. It does not delegate
  what “join” means.
- **Owner decisions, asked once with the work each blocks:** whether joining confirms
  immediately or needs organizer approval; repeat joins and capacity; any choice that moves
  data off-site (a hosted identity provider) or incurs cost.
- **First slice, illustrative owner-supplied decisions:** organizers create title/date
  events; named synthetic volunteers join; joining confirms immediately; a repeat join is
  idempotent; no capacity, public access, real personal data or deployment. Acceptance
  observes exactly one membership after a repeat join. It is real authorized work, not a
  “local-only” label on an unresolved reading. The capability map keeps the blocked
  access and privacy rows; finishing the slice does not finish the application.

**Contrast:** an empty repository for a fully specified line-count CLI needs no interview,
spec file or reference reading.

## Example 5: “make the dashboard faster”

Label every number: *owner-accepted*, *vendor-discovered* or *observed*. None below is a
default.

- **Detect by rival implementations.** Caching, parallel fan-out, lazy loading and
  precompute each make it “faster” but differ on freshness, completeness, cost and what is
  measured. Those differences are the questions.
- **Facts first.** Look up per-widget call counts and vendor quota semantics. Request
  unavailable measurement data or access and report the claim unverified; that is not a
  policy question.
- **Vague outcome.** Propose a scenario with a recommended statistic and boundary—for
  example all-widgets browser p95 for the month-end overview, about 40 concurrent analysts,
  warm sessions—for the owner to accept. An earlier unqualified “2.8 s p95” is an
  *observed* baseline, not a target. A measurement allowance is a ceiling, not an
  obligation; production spend is not measurement spend.
- **Clear answer, new dependency.** “Display may be 15 minutes stale” settles display
  freshness only. If finance's close export needs a full cutoff owned by another authority,
  check the actual governance; ask one bounded question only if authority does not settle it.
- **Late fact.** A vendor limit of four concurrent queries per tenant (*vendor-discovered*)
  withdraws unbounded fan-out and returns cache refresh and batching to candidates, because
  they share the quota. A documented quota needs no owner question; a higher vendor tier or
  a relaxed obligation does.
- **Owner unreachable and every feasible option needs a higher cost ceiling.** Stop that
  dependent work; report the conflicting obligations, alternatives, a recommendation and
  the decision needed. Do not buy a tier, relax freshness or declare the goal impossible
  from the first three ideas.
- **Reading replies.** “Stop asking” ends questions and resolves no hold. “Choose the cache
  strategy within the agreed limits” delegates that choice, if the speaker has authority.

**Negative case:** an adopted SLO and cost policy already fix target, boundary, statistic,
freshness and spend. Asking “what latency target?” manufactures a gap.

## Example 6: clean cutover versus a mixed-version obligation

**(a) Clean cutover.** “Rename the internal key `event_key` to `message_key` across parser,
store and pipeline; the public JSON stays `eventKey`.” If every call site is owned and the
serialized representation is kept, no migration or compatibility layer is needed. Discover
the boundary before choosing a migration; evidence follows the obligations actually claimed.

**(b) Mixed-version obligation.** The adopted support contract says messages already queued
in the old format and a listed partner client already deployed must keep working. Different
files still disagree if one writer emits amounts in minor units and another renders major
units; both suites can pass.
- Expected results come from the adopted contract or provider convention, not from the
  writers' own shared fixtures.
- One integration owner coordinates field meaning, scale and rounding; that role confers
  no money-policy authority. If supported currencies are unsettled, pause dependent work
  and ask the competent owner.
- Serialize only affected work whose meaning is unresolved or cannot be separated.
- Compatibility code follows an adopted support obligation; never add it merely to keep
  parallel writers busy. A consumer existing is not the same as a consumer being supported.
- Report evidence narrowly: “real producer at revision P and consumer at revision C
  processed the adopted examples; old-queue fixtures passed the exercised cases; no live
  partner delivery verified.” A consumer-driven contract test carries semantics only for
  the interactions it exercises, not unexercised behavior, other consumers, or the deployed pair.

## Example 7: choosing a notification delivery design

**Drivers (owner-adopted here):** a burst of 500 requests/second; acknowledgement under
200 ms with the statistic still undecided; business notifications must not silently
disappear. A provider timeout can follow acceptance. PostgreSQL is backed up; Redis is a
disposable cache.

Compare inline delivery, a durable PostgreSQL outbox with a worker, and a disposable-queue
design against those drivers; keep the current approach as a candidate where credible.
- **Pattern names do not fix semantics.** Inline delivery can retry; an outbox relay may
  suspend an uncertain send instead of replaying it. Guarantees depend on the adopted policy
  and the actual configuration, not the pattern's name.
- **Policy stays with the owner whichever option wins:** whether duplicates are acceptable
  after an uncertain provider outcome, what an acknowledgement now means to existing callers,
  and recovery ownership. Look up discoverable facts first: the provider's idempotency and
  status contract, instance capacity, replication mode, current consumers.
- **A conditional recommendation is a legitimate result:** “prefer PostgreSQL-backed pending
  work if durable acceptance is the agreed response and recovery capacity is adequate.”
  “Zero loss across database failover” is a proposed interpretation until a recovery
  objective is adopted. Measure only where the pivotal uncertainty needs it and spend is authorized.
- **Recommend, adopt and implement stay separate.** An authorized recommendation is not
  adoption, and adoption is not authorization to build. Delegating a cheap library choice
  needs one sentence of rationale, not an artifact.
- **Reopening.** An authorized owner amendment or a material new fact reopens an adopted
  choice; an implementer's preference does not. A newly adopted platform runbook can
  supersede the mechanism while the drivers and open policy carry forward; earlier
  measurements stay true of their setup but may no longer be relevant.

## Optional phrasing and deeper review

For rule-like behavior, EARS-style state/event/response wording can reveal missing
conditions. Given/When/Then can express examples. Plain precise prose is equally valid;
syntax does not establish completeness. The [EARS author](https://alistairmavin.com/ears/)
provides its canonical forms; this bundle does not require an external grammar guide.

When missed dimensions would be costly, make an explicit review pass over relevant
actors/permissions, inputs/errors, state/concurrency, effects/recovery, compatibility,
quality constraints and operations. Record omissions that matter. Do not fabricate
requirements or require an N/A row for every dimension on every task.

For difficult high-consequence protocols, a state machine, property-based tests or formal
model may help. Use the project's established tools and a concrete proof obligation;
passing a model checks that model and its assumptions, not arbitrary production behavior.
