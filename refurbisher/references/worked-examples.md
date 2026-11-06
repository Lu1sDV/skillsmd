# Ten worked investigations

These are constructed cases with specified observations, not claims about work performed
on a user's repository. Each reaches a decision because of those observations. Technical
sources establish mechanisms and limits; they do not establish the fictional project's
integration results. Check the actual version and source revision when applying a lead.

The examples teach different decisions. They are not ten steps to run on every task.
A capable agent should notice when the first plausible implementation is acquiring
unearned responsibility, find where the difficult part has already been understood, and
use evidence to change the work. It should use known facts without pretending ignorance.

Code size does not measure the need for investigation. A few lines controlling a critical
numerical or state decision can deserve more source research than a large amount of
routine application code. Mature OSS can supply a public API, a small internal primitive,
regression cases, or a design insight; the useful unit is not always a package.

## Decisions illustrated

| Case | Distinct takeaway |
|---|---|
| [1. Fair scheduling](#1-fair-scheduling-discover-the-relevant-resource-accounting) | Reason toward a mature domain, then test its accounting assumptions. |
| [2. Bug variants](#2-bug-variants-discover-a-host-for-the-property-being-checked) | Find an existing engine that can express the actual property. |
| [3. IR extraction](#3-ir-extraction-remove-an-unnecessary-representation) | Delete a representation whose proposed consumer does not need it. |
| [4. Poor retrieval](#4-poor-retrieval-learn-how-the-installed-index-actually-searches) | Find the failure inside the installed component before adding another. |
| [5. Harness observability](#5-harness-observability-discover-which-product-is-already-built) | Adopt the shared product; implement the workflow that remains specific. |
| [6. Parallel checksums](#6-parallel-checksums-discover-a-small-algorithm-worth-porting) | Find and port a small, complete mechanism inside mature OSS. |
| [7. Geometric failures](#7-geometric-failures-replace-exceptions-with-a-reliable-predicate) | Research a short critical primitive instead of accumulating correctness patches. |
| [8. Raster serving](#8-raster-serving-let-a-standard-representation-remove-infrastructure) | Use a standard representation to eliminate a service architecture. |
| [9. Calibration fitting](#9-calibration-fitting-discover-computation-the-solver-can-avoid) | Change the computation before distributing or accelerating it. |
| [10. Assignment quotas](#10-assignment-quotas-reject-a-network-that-loses-a-constraint) | Reject an attractive borrowed model and keep a bounded custom policy. |

## 1. Fair scheduling: discover the relevant resource accounting

**Situation.** Bulk imports already run as resumable, bounded chunks. Two tenants get
equal queue turns, but the one with larger chunks consumes far more of the constrained
storage bandwidth. The first plan adds "large job" classes, urgency bonuses, and aging
exceptions.

**Research move.** Reformulate this as allocating a shared resource among flows with
differently sized work units. Networking is a promising search space because packet
schedulers face that structure. Search for fairness with variable work size, then follow
the discovered algorithm into an implementation. In Linux's
[DRR scheduler](https://codebrowser.dev/linux/linux/net/sched/sch_drr.c.html),
`drr_dequeue()` compares packet length with accumulated credit and charges that length
when serving it. The important discovery is the accounting contract, not the acronym.

**Deciding evidence.** Replay two backlogged tenants carrying equal total bytes in
different chunk sizes. Measure serviced bytes, next-chunk waiting time, and idle-to-busy
behavior. In this case, chunk boundaries and known byte costs support the transfer.

**Refurbishment.** Keep the durable queue and workers; replace the priority exceptions
with an appropriate credit-accounting selector. Use a compatible existing implementation
or a narrow adaptation with understood provenance. Do not transplant kernel infrastructure.

**Boundary.** Unknown-cost jobs that monopolize an uninterruptible GPU violate the useful
assumptions. That workload should redirect research toward admission, concurrency, or
decomposition. Networking was a reasoned hypothesis, not a claim about the universally
best scheduling domain.

## 2. Bug variants: discover a host for the property being checked

**Situation.** A TypeScript import endpoint crashes when a nested JSON value is null.
After fixing it, the agent must find equivalent mistakes across the repository. An AST
visitor is a reasonable first sketch, but it starts acquiring name resolution, wrapper
tracking, and rules for which guards make later reads safe. The requested check is
becoming another analysis engine.

**Research move.** Describe the property independently of syntax: a value originates in
parsed input and may still be null at a dereference. A check changes a fact about a
particular value; it does not certify every value subsequently read from it. That points
toward program analysis with state attached to value flow. Searching that vocabulary can
lead to [CodeQL's data-flow model](https://codeql.github.com/docs/writing-codeql-queries/about-data-flow-analysis/)
and its [flow-state extension](https://codeql.github.com/docs/codeql-language-guides/using-flow-labels-for-precise-data-flow-analysis/).
If the engine is already known, investigate this modeling boundary directly.

**Deciding evidence.** Build four small fixtures: an unchecked root, a checked root with
an unchecked nullable child, a correctly checked child, and a failing path through an
application wrapper. An initial query treating the root guard as a complete barrier
misses the second defect. The source explains how to preserve input origin while changing
the nullable state at guards and property reads. In this constructed investigation, that
model distinguishes the cases; only the wrapper needs an application-specific addition.
The selected language support, extraction setup, and usage terms fit the project.

**Refurbishment.** Deliver the stateful query, the wrapper model, and those fixtures.
Discard the proposed resolver, call-graph infrastructure, and bespoke guard analysis.
The application owns its property and models at the engine's extension boundary.

**Boundary.** Passing these cases establishes a useful check, not universal completeness.
Unsupported dynamic behavior or an unmodeled wrapper remains a coverage limit. A system
that can represent paths but cannot represent the required property has not earned adoption.

## 3. IR extraction: remove an unnecessary representation

**Situation.** The request is to extract reusable functions from a C++ repository. The initial
plan includes a universal IR with types, control flow, dataflow, and its own serialization
format. None of those layers has yet been consumed by an actual extraction.

**Research move.** Follow one desired function from source to its intended standalone use.
Identify the facts that determine the result, then search compiler interfaces, symbol
indexes, and source-analysis tools for those facts. Useful vocabulary comes from the
task: declaration identity, source ranges, referenced definitions, and compilation
context. Following those needs into
[Clang's tooling interface](https://clang.llvm.org/docs/LibTooling.html) exposes a way to
run compiler analysis with the project's compilation database. That context matters:
the same text can resolve differently under different include paths and definitions.

**Deciding evidence.** In this case, the consumer needs source text and a bounded set of
referenced declarations; the project already has a usable compiler toolchain and build
database. Exercise an extraction with aliases, a build-defined constant, and an external
helper. The compiler resolves the declarations under the real build context. An isolated
build and behavior checks then expose the helper that must be retained or made an explicit
dependency. No downstream operation consumes generic control-flow or dataflow objects.

**Refurbishment.** Implement extraction against that interface and make the external
dependency explicit. Drop the proposed IR schema, serializer, translators, and maintenance
of language semantics.

**Boundary.** Macros, generated definitions, implicit global state, or ABI assumptions can
make apparently local code inseparable. Source ranges and a successful build do not prove
arbitrary semantic independence. If the consumer must transform executable behavior or
query relationships the interface cannot answer, investigate an established representation
for that demonstrated need. The decision follows the consumer, not a blanket ban on IR.

## 4. Poor retrieval: learn how the installed index actually searches

**Situation.** A RAG service proposes a query-rewriting agent and a reranker. Failures
concentrate in small tenants: supporting documents are indexed, but a query asking for
several neighbors sometimes returns only one authorized row.

**Research move.** Translate the symptom into approximate nearest-neighbor search under a
selective filter. Read the installed index's documentation for incomplete filtered results.
[pgvector's filtering and iterative-scan guidance](https://github.com/pgvector/pgvector#filtering)
is a concrete lead. Following it into
[`hnswscan.c`](https://github.com/pgvector/pgvector/blob/master/src/hnswscan.c)
shows how a scan can resume from retained candidates subject to work limits. That is a
potential capability of the existing retrieval layer.

**Deciding evidence.** Keep the embedding, question, and tenant predicate fixed. Compare
the normal query with an exact filtered reference and the installed version's supported
iterative scan. Inspect plans and retrieved IDs. In this case, the latter two recover the
passage, and bounded iterative scanning meets the latency requirement.

**Refurbishment.** Keep the model, embeddings, database, and authorization predicate.
Correct the retrieval configuration and retain selective-tenant regression cases.
The proposed model calls, reranking service, and orchestration are unnecessary for this
failure.

**Boundary.** If exact filtered search also misses the passage, more approximate-search
effort is insufficient. If the passage already reaches the prompt, investigate the later
stage. Never loosen access filtering to improve apparent recall.

## 5. Harness observability: discover which product is already built

**Situation.** The plan for comparing agent harnesses starts with ingestion, a trace
database, search, timelines, authentication, and a dashboard. The distinctive user need
is comparing a failed run with a successful one across harness versions.

**Research move.** Describe that workflow before choosing the stack. Investigate distributed
tracing, experiment tracking, and workflow-history systems, including deployments already
available to the team. Follow feature claims into data models, ingestion APIs, and
extension examples. An OSS platform such as
[Langfuse](https://langfuse.com/docs/observability/overview) is a possible discovery because
it already represents model and tool activity.

**Deciding evidence.** Import a representative run with concurrent tools, retries, and a
failure. Follow the platform's [public data APIs](https://langfuse.com/docs/api-and-data-platform/features/public-api)
to retrieve observations with their trace and parent identities, timestamps, and metadata.
In this case, the deployed version preserves the required relationships. A thin comparison
view groups corresponding scenarios by harness version while retaining individual attempt
identities; it does not flatten concurrent branches into a fictional sequence. Complete
the failed-versus-successful comparison using that view. Deployment, retention, and export
requirements also fit.

**Refurbishment.** Adopt the platform, attach scenario and harness-version metadata during
ingestion, and implement the comparison against its supported read API. Keep that view
outside the platform's internals; no fork is needed in this case. The project owns the
specific comparison behavior and integration, and accepts the platform's documented
operating requirements. It no longer builds a replacement tracing backend.

**Boundary.** A dashboard screenshot does not establish fit. Lost causal relationships,
unexportable data, or a deployment larger than the requirement can overturn adoption.
Reusing existing internal tracing or a narrower component may then carry less responsibility.

## 6. Parallel checksums: discover a small algorithm worth porting

**Situation.** Parallel upload workers already return each ordered chunk's length and
CRC. A compatibility requirement also needs the whole file's CRC. The proposed solution
streams the assembled file through a second checksum worker, adding another complete
read and another job to recover.

**Research move.** Ask whether those summaries can compose before building another byte
pipeline. Compression, archives, and parallel storage are promising places to investigate
checksum concatenation. The [zlib manual](https://zlib.net/manual.html) documents a combine
operation using two CRCs and the second sequence's length. Inspecting
[`crc32.c`](https://github.com/madler/zlib/blob/develop/crc32.c) reveals the polynomial
arithmetic and powers-of-x machinery behind the wrapper. The reusable unit includes
those dependencies, not just the appealing public function.

**Deciding evidence.** In this case, the deployed checksum API lacks combination and
adding a native compression runtime would outweigh a small port. The CRC variant matches.
Compare the complete port with an independent bytewise reference over empty chunks,
uneven lengths, random partitions, and alternate groupings that preserve order. Check
unsigned arithmetic and length handling, including large lengths.

**Refurbishment.** Keep a reviewed combine primitive, its necessary arithmetic, provenance,
notices, and meaningful vectors. Fold the ordered summaries. Eliminate the second data
pass and checksum worker without importing the donor's compression subsystem.

**Boundary.** Different CRC conventions invalidate the transfer; cryptographic hashes do
not inherit this rule. If an installed compatible combine operation exists, call it.
Porting is justified here by the actual integration boundary, not by a preference for
copying code.

## 7. Geometric failures: replace exceptions with a reliable predicate

**Situation.** Polygon-intersection fixes have accumulated several epsilon values.
Nearly collinear edges fail inconsistently, and an adjustment that helps one coordinate
scale breaks another. Another special case would continue the pattern.

**Research move.** Reduce the failures and identify the decision that flips: the sign of
an orientation calculation near degeneracy. Search computational geometry for robust
orientation and degeneracy handling. This leads to work such as
[adaptive geometric predicates](https://www.cs.cmu.edu/~quake/robust.html), including
reference code and explanations of numerical assumptions. The useful discovery is a
systematic mechanism for that decision, not a recommendation to replace all geometry.

**Deciding evidence.** A concrete reduced case has points `(0, 0)`,
`(1000000000, 1000000001)`, and `(1999999999, 2000000001)`: the exact orientation
determinant is `1`, while direct binary64 products subtract to `0`. Compare the reference
mechanism on these failures, scaled inputs, and ordinary cases.
Inspect the target platform and arithmetic assumptions. In this case, the higher-level
intersection logic remains valid once the classification is reliable.

**Refurbishment.** Use an appropriate existing predicate implementation through an installed
library or a justified narrow extraction. Remove the compensating tolerance branches.
Preserve the relevant upstream tests and the application's failure cases.

**Boundary.** Exact orientation does not define the application's policy for coincident
edges, repair invalid topology, or make every constructed intersection coordinate exact.
If those cause the failures, keep investigating the actual mechanism rather than treating
"robust predicates" as a universal repair.

## 8. Raster serving: let a standard representation remove infrastructure

**Situation.** A map application reads a large, mostly immutable raster to render each small
viewport. The first plan introduces tile-generation workers, cache invalidation, retry
queues, and another storage service.

**Research move.** Describe the workload as spatial windows at multiple resolutions over
large static imagery. Investigate remote sensing and geospatial data access. Searches
for partial raster reads and overviews lead to the
[Cloud Optimized GeoTIFF standard](https://docs.ogc.org/is/21-026/21-026.html).
Its internal tiles, reduced-resolution images, and HTTP range access provide a mechanism
existing readers understand. [GDAL](https://gdal.org/en/stable/drivers/raster/cog.html)
already supplies relevant conversion and overview tooling.

**Deciding evidence.** Convert one representative image and serve it from the intended
endpoint. Capture actual byte ranges at several zoom levels. In this case, the reader
uses suitable overviews and transfers the necessary regions rather than the entire image.
Compare coordinates, nodata behavior, and visible output with the local reference.

**Refurbishment.** Prepare suitable assets at ingestion and reuse the reader with the
existing range-capable storage. Retain only required metadata, authorization, and rendering
integration. Do not build a second image-pyramid generator or durable tile-production system.

**Boundary.** Frequent updates, unsupported range access, or expensive per-request derived
imagery can justify a different architecture. Static viewing alone has not earned it.

## 9. Calibration fitting: discover computation the solver can avoid

**Situation.** A calibration job repeatedly evaluates all residuals while perturbing one
parameter at a time. Each measurement depends on only a local subset of parameters, but
the first plan distributes derivative evaluations to new workers.

**Research move.** Ask whether independent perturbations can share an evaluation without
ambiguous effects. Sparse numerical differentiation leads to grouping noninterfering
Jacobian columns, a graph-coloring connection. Follow that mechanism into the installed
solver: [SciPy's least_squares documentation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.least_squares.html)
and [group_columns](https://github.com/scipy/scipy/blob/main/scipy/optimize/_numdiff.py)
are concrete artifacts. The public `jac_sparsity` option can expose existing machinery;
the documented solver-path consequences matter too.

**Deciding evidence.** Derive a structural mask from the model. Compare with dense
differentiation on manageable instances and representative states. Count calls to the
residual function itself, since a solver's headline counter may exclude derivative work.
In this case, the mask is valid and the supported sparse path meets accuracy and runtime
requirements.

**Refurbishment.** Supply the model-specific sparsity information through the existing API.
The worker coordinator, serialization, distributed cancellation, and result assembly
disappear from the plan.

**Boundary.** A derivative that happens to be zero at one state is not structurally absent.
Global coupling can invalidate the mask. If the problem is dense, investigate analytic
derivatives, suitable automatic differentiation, or parallel evaluation on their merits.

## 10. Assignment quotas: reject a network that loses a constraint

**Situation.** An offline instrument planner selects six instruments from a fixed inventory of twelve, then assigns them to six assay slots. Exhaustively enumerating assignments is wasteful. The proposed replacement models calibration quotas as capacity gates in a minimum-cost flow network.

**Research move.** Recognize capacitated bipartite assignment, then inspect the actual [OR-Tools team construction](https://developers.google.com/optimization/flow/assignment_min_cost_flow). Its team gates charge a partition of workers. The application's calibration groups overlap: selecting one instrument can consume two quotas simultaneously. Check that semantic distinction before extending the graph.

**Deciding evidence.** Reduce the case to groups `{A, B}` and `{B, C}`, each permitting
one selected instrument. Fill two slots; assigning A or C to either slot costs `10`,
while assigning B costs `0`. The copied network can route A through the first group and
B through the second, charging only one gate for each instrument. It accepts cost `10`
while violating the first quota. The valid selection is A plus C, costing `20`.
The deployment bound also matters: twelve choose six is only `924` subsets.

**Refurbishment.** Reject the copied flow encoding. Enumerate instrument subsets, reject them using the real quota predicates, and solve each surviving six-by-six cost matrix with the already available [linear assignment implementation](https://docs.scipy.org/doc/scipy/reference/generated/scipy.optimize.linear_sum_assignment.html). The constructed exhaustive oracle confirms the result. Remove permutation search and the new capacity-gate machinery. The application owns a bounded selection policy, while the library owns matching.

**Boundary.** The inventory bound is part of this design. A substantially larger inventory would reopen the formulation; this result establishes no general impossibility theorem about flow encodings.

## Calibration boundaries

A clear local boundary error or a genuinely new, small product rule should receive a
direct implementation and focused verification. Do not manufacture a research episode.

Conversely, being able to implement a component quickly does not justify owning it.
The investigation should identify a reason to retain the chosen mechanism, not merely
find an impressive project or a familiar algorithm name. Reuse can be the wrong answer.

When revising an example, remove its product names mentally. It should still explain
where to look, why that field is relevant, which artifact or experiment changes the
decision, what implementation follows, what responsibility disappears, and what would
overturn the choice. Reject examples that only say "use a library," list facts a strong
programmer already knows, or end with an unresolved menu of possibilities.
