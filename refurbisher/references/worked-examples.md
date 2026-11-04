# Worked examples

Each example shows the moment a passive agent would start scaffolding, and the
investigation that should come first. They follow the six steps in SKILL.md:
1. Downstream questions: what the result must answer or do.
2. Candidates: what already does it.
3. Fit: one real case mapped, or the hardest query prototyped.
4. Cost: deployment, extension points, license.
5. Vet: trust the source.
6. Gap: name what's missing.

Each ends the same way, by stopping the user with alternatives, a recommendation and an
offer of deeper research on that case. The **Report** line shows it.

The first two are the reference examples. Match their depth.

## Contents
1. Observability platform for agent harnesses
2. Intermediate representation of a codebase
3. Sandbox for agent-generated commands
4. File-edit tool for a coding agent
5. Benchmark on real GitHub issues
6. Exposing an internal API over MCP
7. A million connection timeouts
8. Matching Excel's XIRR
9. Customer-written automation rules
10. SQL over a custom storage format
11. Durable multi-step agent tasks
12. Error tracking

## 1. "Build an observability platform for our agent harnesses."

Before scaffolding ingestion services, trace storage, and a dashboard, the agent should
investigate how much of the requested product already exists in a platform such as
Langfuse. Map one representative run—with parallel agents, tool calls, retries, and
failures—into its actual data model. Inspect deployment requirements and extension points.
If the model fits, the project may become a harness adapter and a few specialized views. If
it fails, identify the precise missing capability before deciding to extend, fork, or build
a subsystem. (langfuse.com)

Facts for this case:
- Langfuse's data model is traces, observations (spans, generations, events), sessions and scores.
- Self-hosting it means Postgres, ClickHouse, Redis and S3-compatible storage.
- Langfuse is MIT outside its `ee/` directories. Arize Phoenix, the main alternative, is Elastic License 2.0: you can run it, but you can't offer it as a managed service.
- Emitting OpenTelemetry GenAI spans keeps the harness backend-neutral.

**Report:** Langfuse plus a harness adapter (if the run maps), Phoenix, extending either
with the missing view, or building the subsystem that neither covers. Recommend by the fit
test. Offer to deploy the candidate locally and push one real run through it.

## 2. "Extract an intermediate representation from this codebase."

"IR" is too broad to determine the implementation. The agent should first identify the
downstream questions: locating declarations, resolving call targets, following data through
functions, or transforming executable behavior. Prototype the hardest required query on real
source. CodeQL's C/C++ IR and dataflow facilities are candidates for semantic analysis; a
syntax tree with source ranges may suffice for extraction; compiler IR may suit
transformation. That investigation should determine the representation and toolchain before
the agent invents its own universal program model.

Facts for this case:
- The CodeQL CLI is licensed for open-source and research use only, so a commercial product needs another engine. Candidates: Joern's code property graph (Apache-2.0), SootUp (LGPL), or the MIT-licensed `github/codeql/shared/tree-sitter-extractor` as a model of extraction.

**Report:** the downstream questions, the result of the prototype query in each candidate,
and the representation it points to. Offer to prototype the second-hardest query before the
toolchain is fixed.

## 3. "Run the commands our agent generates in a sandbox."

Sandboxes are never improvised. A command blocklist or a subprocess with a timeout is not
isolation, and many excellent implementations run in production. The agent should first
write down the threat model:
- which paths may be written;
- whether the network is reachable, and where;
- which secrets must stay unreadable;
- whether the shell is interactive.

Then compare production implementations against that model:
- Codex's Linux sandbox (Landlock and seccomp, `openai/codex/codex-rs/linux-sandbox`) and its macOS Seatbelt policy;
- Anthropic's `sandbox-runtime`;
- bubblewrap;
- gVisor;
- Firecracker microVMs.

Run escape tests against each candidate: write outside the workspace, read `~/.ssh`,
reach `169.254.169.254`, start a fork bomb. What is left to write is your harness's
policy, not the isolation.

**Report:** the candidates that passed the escape tests, what each costs (a daemon, a kernel
feature, a VM per run) and which platforms it covers. Recommend one; building isolation is
not among the options.

## 4. "Design the file-edit tool for our coding agent."

This is the same reasoning as the sandbox, applied to the edit protocol. Models are trained
on specific edit formats:
- OpenAI documents that its models are tuned on `apply_patch`.
- Anthropic's text-editor tool has a fixed schema.

The agent should check which format the target model is tuned for. Then it takes that
format's parser and its tests (`openai/codex/codex-rs/apply-patch`, Apache-2.0) instead of
inventing a diff dialect the model has never seen. Replay real edits from past transcripts
through it. The failures that remain, such as matching despite whitespace drift, are the
precise gap to fill.

**Report:** the model's native format, the replay results, and the choice between taking it
as-is and taking it with a fuzzy-matching layer. Offer to replay a larger transcript set.

## 5. "Benchmark our coding agent on real GitHub issues."

A task that is new but popular has often been standardized already. Before writing a script
that clones repos and runs pytest, the agent should ask whether a benchmark format and
harness exist.
- SWE-bench (MIT) defines each instance: repository, base commit, gold patch, test patch, and the `FAIL_TO_PASS` and `PASS_TO_PASS` tests. It ships a Docker environment for each instance.
- `inspect_evals` wraps SWE-bench with scoring and logs.

Convert one of the user's own issues into a SWE-bench instance and run it through the
harness. If it fits, the project becomes a dataset in that format plus an agent adapter,
and the results are comparable with published numbers. Only a capability the format can't
express, such as a multi-repo task or a live service, justifies a custom harness.

**Report:** adopt the SWE-bench format and harness, wrap it in Inspect, or build custom,
with the instance that did or didn't convert as evidence.

## 6. "Expose our internal API to agents over MCP."

The bright move is reading, not remembering. MCP has changed its transports and
authorization between spec revisions, so a server written from memory targets a spec that
no longer exists. Before coding, the agent should:
1. Read the current specification and the SDK documentation.
2. Check whether the SDK, or FastMCP (`PrefectHQ/fastmcp`, Apache-2.0), already generates a server from the API's OpenAPI document.
3. Prototype one endpoint against a real MCP client.

The work that remains is curation: which operations to expose, how they are named and
described, and how the API's auth maps to MCP's.

**Report:** generated server plus curation, or a hand-written server for the few operations
that need custom logic. Name the spec revision targeted.

## 7. "Our proxy keeps a timeout for every connection; make it scale to a million."

Before tuning a heap of deadlines, the agent should recognize a problem the Linux kernel has
solved for decades: the hierarchical timer wheel in `kernel/time/timer.c`. Its 2016 rework
(Linux 4.8) is the instructive part. It stopped cascading timers between levels and
accepted coarser expiry for long timeouts, because most timeouts are cancelled before they
fire.

Measure whether the proxy's timers behave like that: how many there are, how precise they
need to be, and how often they are cancelled. The kernel is GPL-2.0, so take the design and
the commit's rationale. Take code from a permissive wheel: Netty's `HashedWheelTimer`
(Apache-2.0) or tokio's timer (MIT).

**Report:** the measured timer profile, the wheel design it calls for, and port versus
depend on the runtime's own timer. Offer a benchmark against the current heap.

## 8. "Our XIRR must return exactly what Excel returns."

A passive agent writes Newton's method. It ends up off in the fourth decimal, or fails to
converge where Excel succeeds. "Exactly what Excel returns" means the reference is another
product's behavior, and LibreOffice Calc has spent years matching it.

Before coding, the agent should collect Excel outputs for the hard cases (no sign change,
extreme rates, unsorted dates) as test vectors. Run them against LibreOffice and against the
candidate libraries, then port the implementation that passes. LibreOffice is MPL-2.0, so
ported files stay under the MPL; whether that fits the project is the user's call.

**Report:** which candidates matched Excel on the vectors, the MPL consequence of porting
LibreOffice, and the alternatives that don't match.

## 9. "Let customers script their own automation rules."

Before inventing a DSL or embedding `exec`, the agent should pin down what the scripts must
do. Expressions over a record (conditions, computed fields) are a different problem from
programs with loops and state.

Collect three real rules from the user and write them in each candidate language:
- CEL (`cel-expr` implementations) is not Turing-complete and is built for untrusted expressions; Kubernetes admission policies use it.
- Luau is the sandboxed Lua that Roblox runs for millions of untrusted scripts.

Compare the resource limits each offers. If CEL expresses the rules, it's the safer choice;
if a rule needs loops, use Luau. The precise gap, such as one custom function, becomes an
extension rather than a new language.

**Report:** the three rules written in each language, the one that didn't fit, and CEL
versus Luau versus a DSL, with the threat model behind the recommendation.

## 10. "Add SQL querying over our custom storage format."

Before writing a parser and planner, the agent should check whether an embeddable query
engine can sit on top of the storage:
- Apache DataFusion supplies parsing, planning, optimization and execution once you implement a `TableProvider` for the format.
- DuckDB's extension API is the alternative.

Prototype the hardest query users need, such as a join across two tables with a filter.
Check that the filter reaches the storage through filter pushdown instead of forcing a full
scan. If pushdown works, the project is a table provider. If a needed operation is missing,
that operation is the gap.

**Report:** DataFusion versus a DuckDB extension, with the prototype query plan as evidence
and the missing operation if there is one.

## 11. "Make multi-step agent tasks survive crashes and retries."

Durable execution is an existing category. Before chaining Celery tasks around a status
table, the agent should map one real run into a workflow engine's model:
- parallel subagents become sub-workflows started from the parent;
- each tool call becomes a step with a retry policy;
- waiting for human approval becomes a durable wait on an external event.

Then compare what each engine needs to run. Temporal needs its own cluster; DBOS (MIT) keeps
workflow state in the Postgres the project already has. If the run maps cleanly, the project
is a set of workflow definitions. Whatever doesn't map, such as streaming partial model
output, needs its own channel alongside the engine.

**Report:** Temporal versus DBOS versus keeping Celery, with the mapped run, the operational
cost of each, and the part that needs its own channel.

## 12. "Build error tracking for our apps."

Error tracking is a product category with a de facto protocol: Sentry's SDKs exist for every
language. The agent should establish what the backend must do (grouping, release tracking,
alerting) and which servers accept those SDKs:
- GlitchTip (MIT) does.
- Self-hosted Sentry uses the Functional Source License, which allows running it internally but not offering a competing service.

Send real events from the app through the SDK into the candidate and inspect the grouping.
If it fits, the work is SDK setup and alert rules. If the business needs something neither
does, such as linking errors to agent traces, that integration is the project.

**Report:** GlitchTip versus self-hosted Sentry versus a hosted plan, with license limits and
the grouping result from the real events.
