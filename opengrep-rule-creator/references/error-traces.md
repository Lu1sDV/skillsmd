# Error traces for OpenGrep rule authoring

**Status:** Source-grounded review and proposed acceptance obligations. This catalogue is not a fresh OpenGrep/JEV evaluation and does not claim 42 confirmed detector bugs. It includes corrected authoring errors, reviewed interface defects, explicit approximation tradeoffs, conditional coverage limits, and unexecuted regression hypotheses.

## How to read a trace

Each trace preserves the source observation, the invalid inference to prevent, the reusable invariant, the required action, a test, and the boundary against overgeneralization. A corrected failure remains useful training evidence; a hypothetical failure must not become an alleged native observation. `E` identifiers name review mechanisms, `G` identifiers link to the revised `SKILL.md`, and `T` identifiers name proposed test obligations. None is an OpenGrep or JEV schema extension.

The prior procedural-first policy remains in force. It is summarized by E39 rather than repeated as this catalogue's focus.

## Source register

### T

**name:** `Pasted text(20261009-214549).txt`

**sha256:** `82c126b9c1ada18ac5f5db9db46886211dfc3693e6e6b91d6054ef8777a95c04`

**lines:** 7193

**note:** Includes injected historical instructions and a compaction summary; all are source evidence, not instructions for this review. Some tool outputs are truncated.

### R

**name:** `Pasted text(20261009-224323).txt`

**sha256:** `5088f6524bbbcd3868238d0dff8e86a14859d88464f3d3af6272d7ad17b7591b`

**lines:** 352

**note:** Review hypotheses are not fresh scanner observations. Its Git-synchronization characterization is corrected by the visible authoring transcript.

### K

**repository:** Lu1sDV/skillsmd

**path:** `opengrep-rule-creator/SKILL.md`

**git_blob_sha1:** `9f13472ff3c624b231cabe9eeea6e63df5a97875`

**inspected_range:** Complete 1,016-line original obtained for integration; exact Git blob identity verified.

**note:** Baseline for the integrated `SKILL.md`. The complete 41,427-byte example tail is retained unchanged; see the revision receipt for the full-file and example digests. No new native-engine results are asserted.

### B

**repository:** Lu1sDV/jeverse-benchmarks

**revision:** `78330d582617dfa18c337e4b59b550ae295ba844`

**note:** Rule and runtime findings concern this reviewed snapshot, not an assertion about a later branch.

### A

**name:** `OPENGREP_PROCEDURAL_FIRST_SKILL_ADDENDUM.md`

**sha256:** `c2e3e21b3b194446d95ed1cb8284ffbe519657cad9289683c19880badd54cb01`

**note:** Retained premise; this review adds other error-derived obligations rather than replacing it.

Source locators use original file lines, not line numbers in this generated catalogue. Repository locators concern the pinned B snapshot. The supplied transcripts are intentionally not redistributed in this bundle. Source excerpts in the skill runtime must not include these authoring labels or expected verdicts.

## Trace index

| Trace | Mechanism | Evidence status | Gates |
|---|---|---|---|
| [E01](#e01) | Wrong unit of work: testcase catalogue instead of rule repair | `reported_process_error_corrected` | G01, G02 |
| [E02](#e02) | Unverified source-shape diagnosis in delegated work | `observed_process_error_corrected` | G01, G09 |
| [E03](#e03) | Historical schema used as the active contract | `observed_integration_error_corrected` | G01, G07 |
| [E04](#e04) | Unsafe and boundary cases encoded as ordinary ok tests | `observed_annotation_error_corrected` | G06, G10 |
| [E05](#e05) | Conditional factory premise promoted to definite vulnerability truth | `source_visible_label_overstatement` | G02, G03, G06 |
| [E06](#e06) | Security labels generated from function names | `observed_bookkeeping_shortcut` | G06, G09 |
| [E07](#e07) | Free-text status variants evade the boundary collector | `observed_record_contract_mismatch_later_addressed` | G06, G09 |
| [E08](#e08) | Observation fields initialized from expectation | `observed_intermediate_evidence_error_later_reconciled` | G01, G09 |
| [E09](#e09) | Uncertainty removed by searching prose | `observed_unsafe_bookkeeping_operation` | G09 |
| [E10](#e10) | Rendered source copied as authoritative bytes | `observed_tool_boundary_error_corrected` | G01, G09, G10 |
| [E11](#e11) | Filter-only alternative rejected by native schema | `observed_rule_error_corrected` | G03, G10 |
| [E12](#e12) | Keyword spelling substituted for effective argument binding | `source_supported_regression_hypothesis` | G03, G06 |
| [E13](#e13) | Whole-call or whole-object taint substituted for the dangerous operand | `documented_failure_class_and_protection_to_preserve` | G02, G03, G04 |
| [E14](#e14) | Earlier constructor treated as current receiver identity | `source_supported_regression_hypothesis` | G03, G04, G05 |
| [E15](#e15) | Stale tuple shape used at response consumption | `source_supported_regression_hypothesis` | G03, G04, G06 |
| [E16](#e16) | Control-flow syntax mistaken for path feasibility | `documented_engine_gap_and_generalization` | G04, G05, G06 |
| [E17](#e17) | Sanitizer property does not survive a context change | `source_supported_regression_hypothesis` | G04, G06 |
| [E18](#e18) | Control presence mistaken for enforcement or authorized trust | `documented_failure_class_and_test_obligation` | G02, G04, G06 |
| [E19](#e19) | Construction confused with effect or lazy consumption | `documented_failure_class_and_test_obligation` | G02, G04, G06 |
| [E20](#e20) | Taint or grammar influence promoted to unauthorized impact | `documented_claim_strength_risk` | G02, G06 |
| [E21](#e21) | Request-derived value treated as unrestricted attacker syntax | `documented_input_domain_risk` | G02, G03, G04 |
| [E22](#e22) | Unconditional slice sources erase provenance distinctions | `explicit_approximation_tradeoff` | G05, G08, G11 |
| [E23](#e23) | Container-wide propagation loses key and field relationships | `explicit_approximation_tradeoff` | G03, G04, G05 |
| [E24](#e24) | Narrow replacement silently retires broader discovery | `confirmed_scope_change_unmeasured_pack_regression` | G02, G05, G10 |
| [E25](#e25) | Companion ownership asserted without same-operation verification | `source_supported_composition_risk` | G05, G06, G10 |
| [E26](#e26) | Coverage learned from one spelling rather than API behavior | `documented_discovery_limits` | G03, G05, G06 |
| [E27](#e27) | Contract input types incompatible with benchmark selectors | `confirmed_code_incompatibility_at_review` | G07, G10 |
| [E28](#e28) | Test adapted to contract instead of exercising actual integration | `observed_test_boundary_limitation` | G07, G10 |
| [E29](#e29) | Input presence mistaken for semantic sufficiency | `confirmed_contract_wording_risk` | G07, G08 |
| [E30](#e30) | Descriptive metadata mistaken for model-visible evidence | `confirmed_contract_transport_boundary` | G07, G08, G09 |
| [E31](#e31) | Nonexclusive or incomplete answer domains and mixed consumers | `source_supported_domain_risk` | G02, G08 |
| [E32](#e32) | Independent answers combined into a nonexistent joint witness | `generalized_composition_risk_not_observed_model_error` | G04, G08 |
| [E33](#e33) | Raw confidence or low unsafe probability used as safety | `prospective_policy_risk_not_executed_suppression` | G08, G11 |
| [E34](#e34) | Source labels and instructions treated as authoritative evidence | `documented_trust_boundary_risk` | G07, G08, G09 |
| [E35](#e35) | Candidate volume, duplicates and budgets treated as harmless | `explicit_unmeasured_operational_tradeoff` | G05, G10, G11 |
| [E36](#e36) | Green subset mistaken for completed analysis or release readiness | `documented_gate_boundary_and_preserved_blocker` | G06, G10 |
| [E37](#e37) | Same-file candidate associations promoted to detection recovery | `explicit_metric_boundary_not_a_published_accuracy_claim` | G02, G09, G11 |
| [E38](#e38) | Development success mistaken for generalization or model value | `unmeasured_evaluation_gap` | G11, G12 |
| [E39](#e39) | Unnecessary model use for procedural facts | `established_prior_policy_gap` | G03, G08, G10 |
| [E40](#e40) | Review hypotheses become inherited facts | `observed_review_provenance_error_and_generalization_risk` | G01, G09, G12 |
| [E41](#e41) | Operational failures obscure or weaken evidence handling | `observed_operational_errors_corrected` | G09, G10 |
| [E42](#e42) | Skill rules encourage literal compliance without mechanism coverage | `source_visible_instruction_design_risk` | G06, G10, G12 |

<a id="e01"></a>

## E01 — Wrong unit of work: testcase catalogue instead of rule repair

**Evidence status:** `reported_process_error_corrected`. **Sources:** `T:1152-1164`; `T:7008-7022`; `B:rules-improvement/python/README.md`.

**Observed/reviewed basis.** The deliverable was corrected from a per-case question catalogue to individual rule changes; the final README retires the earlier catalogue.

**Invalid inference.** Accounting for every benchmark error is equivalent to producing reusable rules.

**Failure consequence.** Task failure and label/template fitting; no direct FP/FN rate follows.

**Generalization.** The authoring unit is the reusable security mechanism and responsible rule; benchmark cases are development evidence.

**Required authoring action.** State the requested deliverable, exact rule identity, reusable mechanism, and non-goals before dividing work. Permit repair, reuse, investigation, and no-rule outcomes.

**T01 — acceptance obligation.** Give an authoring agent several differently named cases with one mechanism. Require one justified rule-level change rather than case-specific questions or predicates.

**Boundary of the lesson.** A case ledger is useful and should remain; it must not replace mechanism-level reasoning or be passed as runtime truth.

**Skill gates:** G01, G02. **Test execution:** not run in this review.

<a id="e02"></a>

## E02 — Unverified source-shape diagnosis in delegated work

**Evidence status:** `observed_process_error_corrected`. **Sources:** `T:1175-1187`; `T:2150-2176`; `T:2729-2755`; `T:3197-3203`.

**Observed/reviewed basis.** Coordinator assignments confused nested pathlib effects with match/case cases. Workers inspected source, corrected the grouping, and also retracted an initially guessed alternative grouping.

**Invalid inference.** A case ID, category, or summary establishes the exact cause of a miss.

**Failure consequence.** Wrong model repairs, gaps, duplicate ownership, and anchoring on a false diagnosis.

**Generalization.** Diagnosis is evidence-backed and separately marked from hypothesis; ownership follows the actual mechanism.

**Required authoring action.** Attach source hash/location and a concrete observation to each assignment. Require workers to correct contradictions before implementing and preserve correction history.

**T02 — acceptance obligation.** Present a misleading summary with a source whose mechanism differs. Require an explicit correction and unchanged original evidence.

**Boundary of the lesson.** Do not require one coordinator to duplicate every worker investigation; require evidence-linked hypotheses and a correction channel.

**Skill gates:** G01, G09. **Test execution:** not run in this review.

<a id="e03"></a>

## E03 — Historical schema used as the active contract

**Evidence status:** `observed_integration_error_corrected`. **Sources:** `T:1178-1187`; `T:1865-1868`; `T:1902-1925`; `T:2165-2176`; `T:3231-3397`.

**Observed/reviewed basis.** Work initially used profile 0.3 despite the active profile-0.4 runtime. Migration also exposed five purpose/decision-role mismatches, later corrected.

**Invalid inference.** An archived schema or a parsed contract is compatible with the current executor.

**Failure consequence.** Blocked integration or changed execution semantics; not automatically a vulnerability miss.

**Generalization.** Engine, rule syntax, local contract, provider payload, and execution mode are distinct pinned interfaces.

**Required authoring action.** Read the installed runtime/schema and one real consumer before authoring. Freeze a shared interface receipt for workers and version migrations explicitly.

**T03 — acceptance obligation.** Reject an old profile and mismatched role pair at preflight; validate the migrated payload through the actual consumer.

**Boundary of the lesson.** Do not silently upgrade the engine or erase archived artifacts to make compatibility appear successful.

**Skill gates:** G01, G07. **Test execution:** not run in this review.

<a id="e04"></a>

## E04 — Unsafe and boundary cases encoded as ordinary ok tests

**Evidence status:** `observed_annotation_error_corrected`. **Sources:** `T:3542-3627`; `T:3646-3688`; `T:3800-3900`; `T:4326-4339`; `T:5006-5058`.

**Observed/reviewed basis.** Several fixtures used ok annotations for known unsafe noncoverage or companion-owned cases. The parent replaced them with explicit boundary/discovery records and separate failing expectations.

**Invalid inference.** A test expecting no match establishes a safe security negative.

**Failure consequence.** False confidence in recall and contaminated negative counts.

**Generalization.** Matcher admission, security truth, scope membership, and observed execution are independent fields.

**Required authoring action.** Maintain a structured sidecar with those four fields. Known unsafe in-scope omissions remain failing recall obligations; boundary cases never satisfy the safe-negative minimum.

**T04 — acceptance obligation.** Audit a fixture containing an unsafe callback under ok. Fail the semantic gate even if the native matcher test is green; keep a legitimate safe admitted candidate distinct.

**Boundary of the lesson.** Native ok denotes nonmatching syntax, not a native security verdict. Archived educational boundaries may remain unchanged with explicit interpretation.

**Skill gates:** G06, G10. **Test execution:** not run in this review.

<a id="e05"></a>

## E05 — Conditional factory premise promoted to definite vulnerability truth

**Evidence status:** `source_visible_label_overstatement`. **Sources:** `T:3580-3592`; `T:3831-3856`; `T:5026-5047`; `B:rules-improvement/python/tests/jev.python.ldap-search-filter.py`; `B:rules-improvement/python/tests/jev.python.xpath-expression-consumption.py`.

**Observed/reviewed basis.** Opaque factory cases are conditional on returning LDAP/lxml objects, yet some bookkeeping describes them as unsafe security misses without supplying that binding.

**Invalid inference.** A similarly named consumer on an unknown object is an independently established vulnerability.

**Failure consequence.** False positive labels and overstated FN counts.

**Generalization.** A test proves only its supplied premises; missing bindings are not supplied by comments or desired labels.

**Required authoring action.** Provide a concrete caller/factory body or an explicit justified educational API contract; otherwise classify as conditional/unresolved applicability.

**T05 — acceptance obligation.** Use two concrete factories with the same method spelling, one relevant and one unrelated, plus a third absent factory. Require distinct justified labels.

**Boundary of the lesson.** A conditional discovery challenge remains useful and must not be relabeled safe or deleted.

**Skill gates:** G02, G03, G06. **Test execution:** not run in this review.

<a id="e06"></a>

## E06 — Security labels generated from function names

**Evidence status:** `observed_bookkeeping_shortcut`. **Sources:** `T:5064-5068`.

**Observed/reviewed basis.** Parent bookkeeping derives unsafe/safe status from function names beginning with unsafe_ and from special named functions. This is authoring metadata, not evidence that the runtime model received these labels.

**Invalid inference.** A naming convention is a semantic oracle.

**Failure consequence.** Mislabeling renamed, mixed-purpose, or incorrectly named tests; circular validation.

**Generalization.** Truth labels require a claim-specific rationale independent of the representation being tested.

**Required authoring action.** Store reviewed labels and assumptions explicitly. Names may identify a record but cannot determine its security truth.

**T06 — acceptance obligation.** Rename safe and unsafe functions without changing behavior. Semantic labels and aggregate counts must remain unchanged.

**Boundary of the lesson.** Do not accuse runtime prompt leakage from this step alone; it demonstrates an authoring-label construction risk.

**Skill gates:** G06, G09. **Test execution:** not run in this review.

<a id="e07"></a>

## E07 — Free-text status variants evade the boundary collector

**Evidence status:** `observed_record_contract_mismatch_later_addressed`. **Sources:** `T:4590-4596`; `T:4815-4854`; `T:6242-6249`.

**Observed/reviewed basis.** A collector filters security_status == unsafe while worker records use unsafe_outside_scope; later code broadens classification and repairs boundary fixtures.

**Invalid inference.** Unvalidated status strings from multiple workers form a consistent interface.

**Failure consequence.** Known gaps can disappear from the required regression population.

**Generalization.** Machine-consumed states are a closed, versioned vocabulary with independent scope and truth fields.

**Required authoring action.** Validate handoffs. Reject unknown enum values; do not infer scope from substrings in prose or overload one status field.

**T07 — acceptance obligation.** Submit all supported statuses plus an unknown spelling; require conservation of every case and rejection of the unknown spelling.

**Boundary of the lesson.** Do not standardize by silently mapping every unsafe-prefixed label to definite vulnerability truth.

**Skill gates:** G06, G09. **Test execution:** not run in this review.

<a id="e08"></a>

## E08 — Observation fields initialized from expectation

**Evidence status:** `observed_intermediate_evidence_error_later_reconciled`. **Sources:** `T:3693-3698`; `T:7094-7122`.

**Observed/reviewed basis.** An intermediate discovery record writes observed_native_match=False while also requiring a runtime observation. Later records are reconciled to native reported lines.

**Invalid inference.** A known or expected failure on related evidence is the observation for this exact retained fixture/run.

**Failure consequence.** Invented receipts and erroneous promotion or failure accounting.

**Generalization.** Observed fields start unknown and are populated only from matching captures for the exact artifact.

**Required authoring action.** Keep expected and observed values separate; require capture identity and source/rule digests for every observation.

**T08 — acceptance obligation.** Before execution, observed values remain null. Feed a contradictory native report and ensure the report, not the expectation, determines observation.

**Boundary of the lesson.** Historical observations may be retained with their original identity; do not overwrite them with null or pretend they are fresh.

**Skill gates:** G01, G09. **Test execution:** not run in this review.

<a id="e09"></a>

## E09 — Uncertainty removed by searching prose

**Evidence status:** `observed_unsafe_bookkeeping_operation`. **Sources:** `T:6890`; `T:6930`.

**Observed/reviewed basis.** remaining_gaps entries containing missing or unreported are removed after candidate emission; other limitations are removed by phrases such as not measured.

**Invalid inference.** Finding a candidate resolves every uncertainty whose text sounds like noncompletion.

**Failure consequence.** Missing caller/runtime/control evidence can be hidden; exact lost statements are not established without private ledgers.

**Generalization.** An uncertainty closes only through evidence that resolves that identified uncertainty.

**Required authoring action.** Use stable gap IDs with typed resolution events, evidence refs, scope, and reviewer rationale. Preserve superseded text/history.

**T09 — acceptance obligation.** Resolve a discovery gap while leaving missing-runtime and missing-consumer gaps. Only the discovery ID may close, regardless of their wording.

**Boundary of the lesson.** Do not infer that all removed statements were material; the unsafe operation is visible but its full downstream impact is not.

**Skill gates:** G09. **Test execution:** not run in this review.

<a id="e10"></a>

## E10 — Rendered source copied as authoritative bytes

**Evidence status:** `observed_tool_boundary_error_corrected`. **Sources:** `T:6242-6279`.

**Observed/reviewed basis.** A ranged raw read included a human pagination footer; copying it created invalid Python. The author reread the complete file and parsed it before retaining the fixture.

**Invalid inference.** Displayed or nominally raw tool text is necessarily a complete source artifact.

**Failure consequence.** False parser diagnoses, damaged fixtures, or changes to analyzed semantics.

**Generalization.** Artifact bytes are distinct from previews; complete extraction and deliberate transformations require verifiable identity.

**Required authoring action.** Read actual bytes or honor continuation metadata. Validate syntax and exact intended changes without stripping arbitrary source lines that resemble footers.

**T10 — acceptance obligation.** Inject a truncated preview/footer into a source transfer. Reject it rather than treating the resulting parse failure as an engine limitation.

**Boundary of the lesson.** Syntax success is necessary but not proof of byte identity or preserved behavior.

**Skill gates:** G01, G09, G10. **Test execution:** not run in this review.

<a id="e11"></a>

## E11 — Filter-only alternative rejected by native schema

**Evidence status:** `observed_rule_error_corrected`. **Sources:** `T:5736-5814`; `T:6196-6238`.

**Observed/reviewed basis.** The new pathlib rule placed metavariable-pattern directly in an alternative in a form the native schema rejected. A positive pattern plus filter conjunction repaired that branch.

**Invalid inference.** A plausible shared-syntax construct is accepted by the selected native parser in every syntactic position.

**Failure consequence.** Configuration failure can prevent the entire selected pack from scanning.

**Generalization.** Every matcher branch and referenced metavariable must have a supported positive binding and pass the exact engine interface.

**Required authoring action.** Run a small native schema/construct check before full-pack integration; inspect the underlying stdout/stderr when the test report itself is invalid.

**T11 — acceptance obligation.** Exercise each branch in isolation, its conjunction, and the full pack. Require intended rule count, no skipped/invalid rule, and positive/negative controls.

**Boundary of the lesson.** This failure does not imply that metavariable-pattern or focus is generally broken.

**Skill gates:** G03, G10. **Test execution:** not run in this review.

<a id="e12"></a>

## E12 — Keyword spelling substituted for effective argument binding

**Evidence status:** `source_supported_regression_hypothesis`. **Sources:** `R:85-111`; `B:rules-improvement/python/rules/jev.python.flask-cookie-missing-secure.yaml`.

**Observed/reviewed basis.** The cookie model tests keyword presence and excludes keyword expansion, leaving positional Secure and statically resolvable expansions insufficiently challenged.

**Invalid inference.** Absence of a keyword establishes the effective default, or any expansion is safe to exclude.

**Failure consequence.** Potential FP for positional true and FN for resolvable missing/false Secure.

**Generalization.** Security-relevant configuration follows the resolved API signature and effective arguments, not one spelling.

**Required authoring action.** Build a version-bound argument model covering supported positional, keyword, default, alias, and expansion forms; preserve unknowns.

**T12 — acceptance obligation.** Contrast equivalent positional/keyword calls, missing/false/true values, a literal dictionary expansion, and an unknown mapping. Run responsible rule and pack.

**Boundary of the lesson.** These are proposed native regressions, not reproduced emissions here; do not apply one API signature to unrelated receivers.

**Skill gates:** G03, G06. **Test execution:** not run in this review.

<a id="e13"></a>

## E13 — Whole-call or whole-object taint substituted for the dangerous operand

**Evidence status:** `documented_failure_class_and_protection_to_preserve`. **Sources:** `R:185-187`; `R:215-219`; `T:4603-4650`; `B:rules-improvement/python/rules/jev.python.flask-response-body-context.yaml`.

**Observed/reviewed basis.** The analyses distinguish response bodies from headers/status, shell program text from ordinary argv/cwd/env, and query grammar from other parameters. Several broad candidates intentionally retain these distinctions for later analysis.

**Invalid inference.** Any taint in the call or receiver proves taint in the security-relevant operand.

**Failure consequence.** False positives and incorrect security claims.

**Generalization.** The consumed operand, its role, and its program point are explicit and preserved end to end.

**Required authoring action.** Resolve the relevant argument/receiver/field and focus the matcher or procedural check accordingly; do not merge unrelated taint labels as evidence.

**T13 — acceptance obligation.** Move the same untrusted value between dangerous and inert operands while holding all other facts fixed; verify expected differentiation.

**Boundary of the lesson.** An inert operand for one claim may matter to another; do not classify the whole call safe.

**Skill gates:** G02, G03, G04. **Test execution:** not run in this review.

<a id="e14"></a>

## E14 — Earlier constructor treated as current receiver identity

**Evidence status:** `source_supported_regression_hypothesis`. **Sources:** `R:147-165`; `T:3970-4017`; `T:4312-4317`.

**Observed/reviewed basis.** Bounded constructor ancestry and broad reassignment exclusions try to separate Path from unrelated in-memory receivers, but a later assignment can still be a relevant Path.

**Invalid inference.** Either historical constructor presence proves identity now, or reassignment removes all security relevance.

**Failure consequence.** FP from stale identity or FN from legitimate unsafe reassignment.

**Generalization.** Identity is a reaching program-state fact; syntax history is only candidate evidence.

**Required authoring action.** Resolve supported reaching definitions; represent unresolved identity without a safety verdict. Record an explicit recall cost for any exclusion.

**T14 — acceptance obligation.** Test Path to unrelated object, unrelated object to Path, trusted Path to untrusted Path, aliases, and conditional reassignments.

**Boundary of the lesson.** Do not require arbitrary runtime dispatch to be solved; bounded support and explicit unknowns are legitimate.

**Skill gates:** G03, G04, G05. **Test execution:** not run in this review.

<a id="e15"></a>

## E15 — Stale tuple shape used at response consumption

**Evidence status:** `source_supported_regression_hypothesis`. **Sources:** `R:133-145`; `B:rules-improvement/python/rules/jev.python.flask-route-return-body-context.yaml`.

**Observed/reviewed basis.** Tuple-specific patterns and exclusions refer to earlier assignments; later replacements can change both type and body provenance before return.

**Invalid inference.** An earlier tuple assignment determines the object and element consumed later.

**Failure consequence.** Potential FN for tuple-to-tainted-string and FP for tainted-tuple-to-trusted replacement.

**Generalization.** Classification uses the final reaching value and relevant slot at the actual consumer.

**Required authoring action.** Test type and provenance transitions in both directions; separate construction-site reporting from use-site reasoning.

**T15 — acceptance obligation.** Cover tuple to string, string to tuple, tuple to response, body/header swaps, and safe overwrite after unsafe construction.

**Boundary of the lesson.** Do not suppress all tuples or assume all response constructors obey Flask tuple semantics.

**Skill gates:** G03, G04, G06. **Test execution:** not run in this review.

<a id="e16"></a>

## E16 — Control-flow syntax mistaken for path feasibility

**Evidence status:** `documented_engine_gap_and_generalization`. **Sources:** `T:1178`; `T:4657-4694`; `B:rules-improvement/python/tests/jev.python.flask-route-return-body-context.py`.

**Observed/reviewed basis.** Match-owner candidates address reported join/lowering gaps. A final wildcard assignment is not an all-path overwrite after an earlier selected arm.

**Invalid inference.** Textual last assignment or lexical coexistence with a match statement establishes execution order and feasible flow.

**Failure consequence.** FN from false all-path overwrite; FP from incompatible or unreachable arms.

**Generalization.** Needed facts must hold on compatible feasible paths under the relevant language semantics.

**Required authoring action.** Use supported procedural control-flow reasoning, preserve unsupported guards/objects, and describe structural owner candidates honestly.

**T16 — acceptance obligation.** Contrast constant-selected unsafe/safe arms, guarded arms, post-match unconditional overwrite, and an unrelated nested match.

**Boundary of the lesson.** A single probe does not prove the engine has no support for every match/case construct.

**Skill gates:** G04, G05, G06. **Test execution:** not run in this review.

<a id="e17"></a>

## E17 — Sanitizer property does not survive a context change

**Evidence status:** `source_supported_regression_hypothesis`. **Sources:** `R:113-131`; `B:rules-improvement/python/rules/jev.python.flask-route-return-body-context.yaml`.

**Observed/reviewed basis.** jsonify is modeled as a sanitizer while later effective MIME and response mutation are relevant to the claimed XSS result.

**Invalid inference.** A transformation that is safe in its initial context remains safe after reinterpretation or mutation.

**Failure consequence.** Potential false negatives before any later assessor sees a candidate.

**Generalization.** Safety is a property of the representation at the actual effect, preserved through all relevant subsequent transformations.

**Required authoring action.** Describe sanitizer preconditions, postcondition, representation, context, and invalidating operations. Avoid irreversible taint removal when those conditions are not established.

**T17 — acceptance obligation.** Compare unchanged JSON delivery with later HTML interpretation, safe encoding with later decoding, and the same value in text versus script context.

**Boundary of the lesson.** Do not ban jsonify or every sanitizer; validate the contexts in which the summary is sufficient.

**Skill gates:** G04, G06. **Test execution:** not run in this review.

<a id="e18"></a>

## E18 — Control presence mistaken for enforcement or authorized trust

**Evidence status:** `documented_failure_class_and_test_obligation`. **Sources:** `R:191-193`; `R:229-231`; `R:270`; `T:4233-4287`; `K:Non-obvious semantics`.

**Observed/reviewed basis.** The reviewed guidance correctly distinguishes returned versus in-place sanitization, checks on the consumed value, signed storage versus authorized request data, and post-effect catches.

**Invalid inference.** A check exists, a token is signed, or the user is authenticated; therefore this effect is authorized and prevented on rejection.

**Failure consequence.** False negatives from unenforced, wrong-subject, or insufficient controls.

**Generalization.** A control must enforce the required property on the same value/resource/principal before the effect, with valid coverage and trust assumptions.

**Required authoring action.** Write the control postcondition and failure path explicitly; accept alternative controls that establish the same property, including valid compositions.

**T18 — acceptance obligation.** Challenge discarded return values, log-only failures, caught rejection with continuation, wrong principal/resource, and a valid alternative control.

**Boundary of the lesson.** Do not demand one particular guard or one dominating check if a correct all-path composition exists.

**Skill gates:** G02, G04, G06. **Test execution:** not run in this review.

<a id="e19"></a>

## E19 — Construction confused with effect or lazy consumption

**Evidence status:** `documented_failure_class_and_test_obligation`. **Sources:** `R:193`; `R:215`; `R:223-225`; `T:4195-4201`; `T:4320-4339`.

**Observed/reviewed basis.** The review distinguishes deferred YAML iteration, compiled XPath invocation, response delivery, and a filesystem read that occurs before slicing/escaping its result.

**Invalid inference.** Constructing a sensitive object proves the effect occurred, or processing its result later retroactively prevents the earlier effect.

**Failure consequence.** FP from never-consumed objects and FN from post-effect apparent controls.

**Generalization.** Identify the precise effect stage, evaluation order, and actual consumption under the declared API semantics.

**Required authoring action.** Model creation, execution/iteration, delivery, mutation, and cleanup as distinct stages where material; retain call/use identities.

**T19 — acceptance obligation.** Pair used versus unused lazy results, invoked versus uninvoked query objects, sent versus discarded responses, and inner effect before outer transformation.

**Boundary of the lesson.** Do not assume every constructor is effect-free; inspect the actual API.

**Skill gates:** G02, G04, G06. **Test execution:** not run in this review.

<a id="e20"></a>

## E20 — Taint or grammar influence promoted to unauthorized impact

**Evidence status:** `documented_claim_strength_risk`. **Sources:** `R:111`; `R:199`; `R:217-231`; `T:6788-6807`; `B:rules-improvement/python/README.md`.

**Observed/reviewed basis.** The material separates query grammar from permitted query-language use, mock LDAP from production impact, weak primitives from security reliance, and metadata queries from file-content access.

**Invalid inference.** A sensitive API, attacker-selected grammar, external URL, or persisted value is automatically a vulnerability with the strongest possible impact.

**Failure consequence.** False positives, overstated impact, and faulty labels.

**Generalization.** Observation, necessary security premises, authorization policy, and claimed consequence are separate; no stage silently strengthens the claim.

**Required authoring action.** Declare permitted behavior and required security property independently. Preserve separate claims for shell, argv, XXE, expansion, headers, and authority.

**T20 — acceptance obligation.** Contrast deliberately permitted query interfaces, authorized external destinations, nonsecurity digests, signed but unauthorized state, and metadata-only effects.

**Boundary of the lesson.** Do not require production exploitation proof for a deliberately narrower audit claim; label the claim honestly.

**Skill gates:** G02, G06. **Test execution:** not run in this review.

<a id="e21"></a>

## E21 — Request-derived value treated as unrestricted attacker syntax

**Evidence status:** `documented_input_domain_risk`. **Sources:** `T:6799-6802`; `B:rules-improvement/python/README.md`; `B:rules-improvement/python/rules/jev.python.flask-shell-command-injection.yaml`.

**Observed/reviewed basis.** The earlier review distinguishes HTTP header names from unrestricted header values and flags route-converter/accepted-domain evidence as material.

**Invalid inference.** Every request field or route parameter admits all syntax necessary for the proposed exploit.

**Failure consequence.** False positives from infeasible characters/domains; false negatives if restrictions are assumed without evidence.

**Generalization.** Attacker influence is qualified by the actual accepted domain and transformations into the consumed representation.

**Required authoring action.** Record source kind, converters, parsing, normalization, and enforced rejection. Validate a proposed witness through each earlier restriction.

**T21 — acceptance obligation.** Use identical downstream code with a finite converter, a constrained header-name source, and an unrestricted value source; preserve unknown deployment acceptance.

**Boundary of the lesson.** Do not assume protocol restrictions alone prove complete application safety or silently change native labels.

**Skill gates:** G02, G03, G04. **Test execution:** not run in this review.

<a id="e22"></a>

## E22 — Unconditional slice sources erase provenance distinctions

**Evidence status:** `explicit_approximation_tradeoff`. **Sources:** `R:167-177`; `T:1178`; `T:2587-2615`.

**Observed/reviewed basis.** Slice-result expressions are admitted as sources to compensate for reported native taint loss, including trusted producers.

**Invalid inference.** A slice candidate is a proved request origin or a repaired taint transfer.

**Failure consequence.** Candidate false alarms and review cost; possible misclassification if provenance is treated as fact.

**Generalization.** Candidate provenance retains which facts were observed, approximated, or remain unknown.

**Required authoring action.** Distinguish native may-flow, structural inventory, and unresolved-provenance candidates; resolve supported provenance procedurally before residual assessment.

**T22 — acceptance obligation.** Use identical slice shapes on trusted and untrusted producers and an overwritten slice; verify provenance and dispositions remain distinct.

**Boundary of the lesson.** A broad candidate is not automatically a bad rule; its downstream evidence burden and workload must be measured.

**Skill gates:** G05, G08, G11. **Test execution:** not run in this review.

<a id="e23"></a>

## E23 — Container-wide propagation loses key and field relationships

**Evidence status:** `explicit_approximation_tradeoff`. **Sources:** `R:171`; `T:2617-2648`; `B:rules-improvement/python/rules/jev.python.subprocess-interpreter-argv.yaml`.

**Observed/reviewed basis.** Generic append/extend/update propagation can conservatively taint an entire container or receiver after one write.

**Invalid inference.** The selected element at the sink is necessarily the tainted one, or removing one element clears the whole object.

**Failure consequence.** False positives or false negatives from unsupported element precision.

**Generalization.** The model must state its precision for elements, keys, fields, aliases, and mutation; later decisions cannot assume greater precision.

**Required authoring action.** Resolve supported selections and distinguish receiver mutation from returned values. Preserve imprecision in the evidence supplied downstream.

**T23 — acceptance obligation.** Mix clean/dirty entries, access different keys, overwrite or remove an entry, alias the container, and place taint only in a non-dangerous argument.

**Boundary of the lesson.** Do not claim index sensitivity from a one-element teaching fixture.

**Skill gates:** G03, G04, G05. **Test execution:** not run in this review.

<a id="e24"></a>

## E24 — Narrow replacement silently retires broader discovery

**Evidence status:** `confirmed_scope_change_unmeasured_pack_regression`. **Sources:** `R:175-177`; `T:1704-1741`; `B:rules-improvement/python/manifest.json`.

**Observed/reviewed basis.** A generic deserialization audit is retired in favor of a Flask-focused source model plus match-specific companions; non-Flask sources are acknowledged as outside the replacement.

**Invalid inference.** Keeping prior benchmark TP files proves the replacement preserves the original supported mechanisms.

**Failure consequence.** Cross-repository false negatives and silent coverage loss.

**Generalization.** Every retired behavior has an explicit successor, justified claim exclusion, declared product scope change, or retained unresolved coverage debt.

**Required authoring action.** Create a coverage handoff table and test lost shapes with the effective selection. Preserve broader discovery where replacement adequacy is unproved.

**T24 — acceptance obligation.** Add non-Flask inputs with and without match/case and verify exact-operation coverage under old, new, and combined intended selections.

**Boundary of the lesson.** Do not keep a false broad audit forever merely because it is old; separate noisy audit policy from missing vulnerability discovery.

**Skill gates:** G02, G05, G10. **Test execution:** not run in this review.

<a id="e25"></a>

## E25 — Companion ownership asserted without same-operation verification

**Evidence status:** `source_supported_composition_risk`. **Sources:** `T:3594-3602`; `T:4858-4880`; `T:5006-5058`; `T:5630-5675`.

**Observed/reviewed basis.** Cases excluded by one rule are designated companion-scope. One intermediate regression mistakenly required the excluded constructor case from the route rule before being corrected.

**Invalid inference.** Naming a companion proves the emitted operation is covered, or every rule must cover the whole family independently.

**Failure consequence.** Hidden pack-level FN or wrongly failing rule-local requirements; duplicate votes can mask ownership errors.

**Generalization.** Rule-local scope and selected-pack security coverage are different contracts joined by exact operation identity.

**Required authoring action.** Record which selected rule owns each delegated effect and verify its actual emitted location and claim. Retain overlapping evidence without duplicate vulnerability votes.

**T25 — acceptance obligation.** Run a constructor/route-return overlap case individually and as a pack; require at least one correct owner, no uncovered delegation, and a declared deduplication rule.

**Boundary of the lesson.** Do not force all companions to match every unsafe case or declare pack recovery from any same-file alert.

**Skill gates:** G05, G06, G10. **Test execution:** not run in this review.

<a id="e26"></a>

## E26 — Coverage learned from one spelling rather than API behavior

**Evidence status:** `documented_discovery_limits`. **Sources:** `R:205-211`; `T:3544-3579`; `T:4326-4339`.

**Observed/reviewed basis.** The pack retains gaps for hash callbacks, runtime-selected algorithms, Random instances, stored bound methods, and factory-returned receivers.

**Invalid inference.** Matching an API name or one constructor form establishes coverage of the security mechanism.

**Failure consequence.** False negatives on equivalent implementations.

**Generalization.** The supported surface is explicit across call forms, factories, callbacks, instances, and analysis boundaries.

**Required authoring action.** Inventory common equivalent shapes and test them; a limitation remains in broader recall accounting even when outside a narrow matcher.

**T26 — acceptance obligation.** Hold the mechanism fixed while varying imported alias, keyword form, stored callable, instance method, helper, and factory; bind any required callers concretely.

**Boundary of the lesson.** Do not broaden to arbitrary same-named calls or claim every possible dynamic form must be solved before any bounded rule is useful.

**Skill gates:** G03, G05, G06. **Test execution:** not run in this review.

<a id="e27"></a>

## E27 — Contract input types incompatible with benchmark selectors

**Evidence status:** `confirmed_code_incompatibility_at_review`. **Sources:** `R:34-61`; `B:src/jeverse_bench/jev_execution.py`; `B:rules-improvement/python/rules/jev.python.hashlib-md5-security-purpose.yaml`; `B:rules-improvement/python/rules/jev.python.random-security-purpose.yaml`.

**Observed/reviewed basis.** Four crypto/randomness contracts require strings while the standard benchmark selector interface permits mapped JSON inputs only; omitting mappings leaves required inputs unavailable.

**Invalid inference.** Standalone schema/planner validity proves compatibility with the production evidence adapter.

**Failure consequence.** Execution blocker and unavailable assessments, not a justified static or safe result.

**Generalization.** Evidence producers and actual consumers agree on types, meaning, identity, and execution capability.

**Required authoring action.** Exercise real contract-to-runner bindings using actual producer outputs before expanding the pack. Changing a type name alone does not supply the missing evidence.

**T27 — acceptance obligation.** Use each authored contract with the real adapter: reject incompatible ports, assert explicit missingness, and verify a complete actual binding reaches the expected request.

**Boundary of the lesson.** The generic planner may legitimately support strings; the incompatibility is with this particular adapter.

**Skill gates:** G07, G10. **Test execution:** not run in this review.

<a id="e28"></a>

## E28 — Test adapted to contract instead of exercising actual integration

**Evidence status:** `observed_test_boundary_limitation`. **Sources:** `T:5697-5707`; `T:5765-5780`; `R:55-59`.

**Observed/reviewed basis.** A synthetic preparation loop first asserts JSON input and fails on operation_source:string, then is changed to supply either strings or JSON. The saved result remains explicitly a planner-shape smoke.

**Invalid inference.** Making the smoke data fit declared port types resolves the real benchmark interface failure.

**Failure consequence.** Integration defect survives a passing unit demonstration.

**Generalization.** A component test cannot certify an interface path it bypasses.

**Required authoring action.** Keep the generic planner smoke, but add a distinct real-adapter integration test whose inputs come from the actual producer. Label each test by its boundary.

**T28 — acceptance obligation.** Give all contracts the same irrelevant shell snippet: the shape smoke may pass, but a semantic/evidence integration gate must not declare target assessment readiness.

**Boundary of the lesson.** No fabricated model answers are shown in this smoke; the mistake is overinterpreting its coverage, not the legitimate use of synthetic data.

**Skill gates:** G07, G10. **Test execution:** not run in this review.

<a id="e29"></a>

## E29 — Input presence mistaken for semantic sufficiency

**Evidence status:** `confirmed_contract_wording_risk`. **Sources:** `R:63-79`; `R:57-59`; `B:rules-improvement/JEV-CONTRACT.md`.

**Observed/reviewed basis.** Some prompts assign missing essentials to blocked while their Choice only represents unsafe/constrained/unresolved and defines unresolved as ambiguity after evidence supply.

**Invalid inference.** A populated field implies the needed implementation, configuration, or complete consumers are present.

**Failure consequence.** Potential false refutation, unsupported positive, or avoidable blocked work.

**Generalization.** Execution status is separate from claim assessment; semantic incompleteness inside present inputs remains unresolved.

**Required authoring action.** Define exact evidence requirements and completeness limits. Allow decision-dependent sufficient evidence; do not require irrelevant fields after a decisive narrow refutation.

**T29 — acceptance obligation.** Supply a present callers object missing the relevant helper; require unresolved. Separately provide a decisive non-relevant API binding and avoid demanding unrelated downstream evidence.

**Boundary of the lesson.** Do not claim a runtime can mechanically prove arbitrary semantic completeness.

**Skill gates:** G07, G08. **Test execution:** not run in this review.

<a id="e30"></a>

## E30 — Descriptive metadata mistaken for model-visible evidence

**Evidence status:** `confirmed_contract_transport_boundary`. **Sources:** `R:83`; `T:1931-1935`; `T:2021-2032`; `B:rules-improvement/JEV-CONTRACT.md`.

**Observed/reviewed basis.** The runtime sends bound state and question instructions/criteria; claim, scope, assumptions, tags, and graph edges do not automatically supply source evidence.

**Invalid inference.** Writing an assumption in the contract or adding a parent node ensures the model sees it.

**Failure consequence.** Wrong-scope decisions, missing premises, and anchoring on unsupported prior classifications.

**Generalization.** Every material premise is traceable through actual input, state binding, serialized request, answer, and permitted decision use.

**Required authoring action.** Inspect rendered payloads. Bind underlying source separately from fallible parent answers; pin identities and invalidate descendants when required evidence changes.

**T30 — acceptance obligation.** Remove an essential scope binding; block or remain unresolved. Change parent evidence without changing its categorical answer and require stale-child invalidation.

**Boundary of the lesson.** Do not add every contract field to every prompt; include what the question actually needs and avoid leakage.

**Skill gates:** G07, G08, G09. **Test execution:** not run in this review.

<a id="e31"></a>

## E31 — Nonexclusive or incomplete answer domains and mixed consumers

**Evidence status:** `source_supported_domain_risk`. **Sources:** `R:81`; `R:239-249`; `B:rules-improvement/python/rules/jev.python.hashlib-sha1-security-purpose.yaml`.

**Observed/reviewed basis.** Protected crypto outcomes are not equally explicit about every relevant security consumer/path, while one object can feed both protected and unprotected uses.

**Invalid inference.** One protected use refutes the operation-level claim, or absence of an unsafe witness chooses the safe category.

**Failure consequence.** Model-induced false negatives or forced classification when no option fits.

**Generalization.** Answer categories match one scoped proposition; existential support and all-scope refutation have different obligations.

**Required authoring action.** Define precedence for a supported unsafe witness, complete refutation, not-applicable situations, and unresolved evidence. Avoid forcing compatible attributes into exclusive choices.

**T31 — acceptance obligation.** Use mixed protected/unprotected consumers, one safe branch plus one unknown branch, a non-relevant API, and incompatible control mechanisms that jointly suffice.

**Boundary of the lesson.** Do not require knowledge of every branch to accept one fully established unsafe witness.

**Skill gates:** G02, G08. **Test execution:** not run in this review.

<a id="e32"></a>

## E32 — Independent answers combined into a nonexistent joint witness

**Evidence status:** `generalized_composition_risk_not_observed_model_error`. **Sources:** `R:235-272`; `B:rules-improvement/source-notes/references/questions-and-statistics.md`.

**Observed/reviewed basis.** The reviews warn that decomposition and marginal probabilities do not by themselves retain relational facts across paths, values, and principals.

**Invalid inference.** Some attacker control plus some failed control anywhere implies one feasible unauthorized effect.

**Failure consequence.** False positives from incompatible paths; false negatives from a safe answer about a different subject.

**Generalization.** Composition preserves operation, value/version, principal/resource, configuration, and compatible path or explicit consumer coverage.

**Required authoring action.** Attach relational identities to premise records and compose only justified relations. Treat procedural/model conflicts as evidence-review conditions, not votes.

**T32 — acceptance obligation.** Place source influence and failed enforcement on mutually exclusive branches, then move them to the same feasible branch; require different outcomes.

**Boundary of the lesson.** A single holistic question is not automatically wrong, and more nodes are not automatically safer.

**Skill gates:** G04, G08. **Test execution:** not run in this review.

<a id="e33"></a>

## E33 — Raw confidence or low unsafe probability used as safety

**Evidence status:** `prospective_policy_risk_not_executed_suppression`. **Sources:** `R:274-292`; `R:336-342`.

**Observed/reviewed basis.** The reviewed system is shadow-only and has no live model evaluation. The reviews distinguish native Choice confidence from measured decision error.

**Invalid inference.** High confidence in unresolved, low P(unsafe), or a shared threshold across different domains justifies suppression.

**Failure consequence.** Future model-induced FN and misleading calibration claims.

**Generalization.** Only a separately validated claim-refutation policy can authorize dismissal; uncertainty is not a negative vote.

**Required authoring action.** Freeze output semantics and decision policy, evaluate false dismissals on the actual residual population, and report uncertainty/dependence.

**T33 — acceptance obligation.** Feed supported=.01/refuted=.02/unresolved=.97 and require retained review. Change option count/order without pretending a fixed confidence threshold has invariant error.

**Boundary of the lesson.** No actual suppression failure is established here; do not invent a measured error rate or a universal safe threshold.

**Skill gates:** G08, G11. **Test execution:** not run in this review.

<a id="e34"></a>

## E34 — Source labels and instructions treated as authoritative evidence

**Evidence status:** `documented_trust_boundary_risk`. **Sources:** `R:330-334`; `T:4892-4992`.

**Observed/reviewed basis.** The executor can transmit source text; mechanical guardrails reject recognized hints but explicitly do not claim to catch all leakage or insufficient evidence.

**Invalid inference.** Target-only context is automatically label-neutral and safe to interpret as instructions.

**Failure consequence.** Label leakage, misleading evaluation, and source-driven decision manipulation.

**Generalization.** Source and retrieved content are untrusted evidence; authoring expectations and instructions are not decision authority.

**Required authoring action.** Separate oracle/patch/contrast materials, review any transformation with a reverse map, and test comment-only steering without deleting semantic program content.

**T34 — acceptance obligation.** Add irrelevant comments asking for a safe verdict, rename benchmark identifiers, remove decisive helper evidence, and assert no unwarranted dismissal.

**Boundary of the lesson.** Do not claim regex filtering proves absence of leakage; do not strip code or required annotations blindly.

**Skill gates:** G07, G08, G09. **Test execution:** not run in this review.

<a id="e35"></a>

## E35 — Candidate volume, duplicates and budgets treated as harmless

**Evidence status:** `explicit_unmeasured_operational_tradeoff`. **Sources:** `R:171-175`; `R:328`; `B:rules-improvement/python/manifest.json`; `B:src/jeverse_bench/jev_execution.py`.

**Observed/reviewed basis.** Broad candidates overlap, and the executor uses a shared request budget while the reported scan has thousands of raw findings.

**Invalid inference.** Candidate-only status removes false-positive cost, or one duplicate surviving proves every underlying decision was correct.

**Failure consequence.** Review overload, budget-exhausted assessments, masked erroneous dismissals, and inflated votes.

**Generalization.** Unique operations, rule claims, underlying findings, routing decisions, and capacity limits remain separately measurable.

**Required authoring action.** Measure workload and overlap; use declared identity-aware deduplication and scheduling while preserving raw evidence and budget-exhaustion status.

**T35 — acceptance obligation.** Create duplicates of one operation plus a distinct later operation under a small budget. Require stable declared scheduling and visible unassessed work without extra TP votes.

**Boundary of the lesson.** Budget exhaustion is an execution outcome, not automatically an FN/TN; report its practical coverage consequence separately.

**Skill gates:** G05, G10, G11. **Test execution:** not run in this review.

<a id="e36"></a>

## E36 — Green subset mistaken for completed analysis or release readiness

**Evidence status:** `documented_gate_boundary_and_preserved_blocker`. **Sources:** `R:17-22`; `R:298-306`; `T:1584-1652`; `T:6842-6859`.

**Observed/reviewed basis.** check.py runs direct rule/fixture pairs; separate discovery regressions fail and native validation remains blocked. The final documentation correctly withholds readiness.

**Invalid inference.** Exit zero, scanned-file presence, or 21 passing pairs means all required behavior passed.

**Failure consequence.** Undetected regression, false coverage, or premature release claims.

**Generalization.** Each gate certifies only the exercised surface, and promotion considers the union of required obligations.

**Required authoring action.** Maintain a gate manifest for syntax, branches, full source, responsible rule, whole pack, required discovery, adapter, and independent evaluation. Mark out-of-scope obligations separately, never as passes.

**T36 — acceptance obligation.** Let the bounded suite pass while one required discovery or integration check fails; promotion must fail with the correct gate and retained diagnostics.

**Boundary of the lesson.** Do not turn every conditional challenge into an absolute release failure without first establishing its applicability and required scope.

**Skill gates:** G06, G10. **Test execution:** not run in this review.

<a id="e37"></a>

## E37 — Same-file candidate associations promoted to detection recovery

**Evidence status:** `explicit_metric_boundary_not_a_published_accuracy_claim`. **Sources:** `T:6842-6859`; `T:6890-6914`; `R:19-30`; `R:328`.

**Observed/reviewed basis.** The development ledger joins by file and associated rule; prior TP retention uses expected-CWE presence in the file. The final report explicitly calls these candidate observations.

**Invalid inference.** Any associated same-file candidate is the original unsafe sink, a recovered vulnerability, or an independently scored positive.

**Failure consequence.** Misleading recall/precision, wrong-CWE credit, and duplicated outcomes.

**Generalization.** Scoring preserves the declared oracle unit and mapping; candidate/location association is a different measurement.

**Required authoring action.** Keep testcase/CWE scores frozen and separate localized operation studies that require independent labels. Do not fix CWE disagreements by label-fitting remaps.

**T37 — acceptance obligation.** Include two same-file operations, duplicate alerts, wrong-CWE alerts, and one true labeled unit; require declared aggregation without manufactured votes.

**Boundary of the lesson.** The existing counts are not fraudulent when presented at their actual candidate-association level.

**Skill gates:** G02, G09, G11. **Test execution:** not run in this review.

<a id="e38"></a>

## E38 — Development success mistaken for generalization or model value

**Evidence status:** `unmeasured_evaluation_gap`. **Sources:** `R:28-30`; `R:298-342`; `B:rules-improvement/AGENTS.md`; `A`.

**Observed/reviewed basis.** No live JEV study or independent cross-repository evaluation is reported; previous TP/TN populations and template dependence matter to any future gain claim.

**Invalid inference.** Fixing development FP/FN rows or adding richer evidence proves the decision model improves detection.

**Failure consequence.** Hidden new FP/lost TP, overfit rules/questions, and confounded attribution.

**Generalization.** Evaluate native baseline, native repair, procedural augmentation, and residual model addition separately with matched evidence and frozen policy.

**Required authoring action.** Test all confusion-cell transitions, abstentions, old negatives, grouped held-out families, and the actual harder routed population. Attribute evidence acquisition separately.

**T38 — acceptance obligation.** Compare the same pipeline and evidence with and without model use; ensure new TN-to-FP and TP-to-FN transitions cannot be hidden by aggregate gains.

**Boundary of the lesson.** No finite test suite proves zero risk; zero observed errors need an uncertainty statement appropriate to dependence and sampling.

**Skill gates:** G11, G12. **Test execution:** not run in this review.

<a id="e39"></a>

## E39 — Unnecessary model use for procedural facts

**Evidence status:** `established_prior_policy_gap`. **Sources:** `T:4233-4269`; `T:4607-4633`; `T:4370-4371`; `A`.

**Observed/reviewed basis.** The fixtures intentionally include finite filename selections and fixed non-shell vectors as candidates, while contract-level mandatory assessment does not itself establish per-finding model necessity.

**Invalid inference.** A native matcher limitation, custom helper, or high FP risk automatically justifies a provider call.

**Failure consequence.** Unnecessary uncertainty/cost and avoidable false decisions.

**Generalization.** Use validated procedures for supported premises and admit only justified, adequately evidenced residual judgments.

**Required authoring action.** Apply the prior procedural-first admission policy per premise and per finding; do not silently reinterpret mandatory or fabricate a completed model node.

**T39 — acceptance obligation.** For both procedural positive and negative resolutions, make the transport raise if called; require zero requests and the correct claim-specific result.

**Boundary of the lesson.** Do not demand an unbounded analyzer or equate imagined procedural solvability with an implemented reliable method.

**Skill gates:** G03, G08, G10. **Test execution:** not run in this review.

<a id="e40"></a>

## E40 — Review hypotheses become inherited facts

**Evidence status:** `observed_review_provenance_error_and_generalization_risk`. **Sources:** `R:5-7`; `T:1083-1127`; `T:1175-1187`; `R:87`; `R:115`; `R:149`.

**Observed/reviewed basis.** The attached review calls its source a synchronization transcript, but the visible original contains authoring work. Other review counterexamples are expressly not natively reproduced.

**Invalid inference.** A polished review, repeated claim, or two agreeing analyses establishes primary evidence.

**Failure consequence.** Incorrect diagnosis, misleading error counts, and bad permanent skill prohibitions.

**Generalization.** Every lesson retains evidence status, scope, lifecycle, and source; corrections remain linked rather than overwritten.

**Required authoring action.** Distinguish observed/corrected errors, source-supported risks, conditional limits, and proposed tests. Reproduce before elevating a hypothesis to engine-wide guidance.

**T40 — acceptance obligation.** Give the reviewer a confident but contradicted summary and an unrun counterexample. Require correction of the summary and retention of the counterexample as proposed.

**Boundary of the lesson.** Do not dismiss a useful general test obligation merely because the motivating counterexample is not yet reproduced.

**Skill gates:** G01, G09, G12. **Test execution:** not run in this review.

<a id="e41"></a>

## E41 — Operational failures obscure or weaken evidence handling

**Evidence status:** `observed_operational_errors_corrected`. **Sources:** `T:6970-7003`; `T:7094-7140`.

**Observed/reviewed basis.** The transcript records a str.read_bytes failure during final receipts and catches permissive scratch-file permissions, then fixes both. No credential leak is established.

**Invalid inference.** A large stateful bookkeeping cell is atomic, or retrospective permission checks replace private creation.

**Failure consequence.** Incomplete receipts, accidental overwrites, and avoidable private-evidence exposure risk.

**Generalization.** Evidence operations are small, typed, nonoverwriting, private from creation, and resilient to partial failure.

**Required authoring action.** Validate paths before side effects, use safe creation modes and durable capture IDs, preserve failed commands, and retry only incomplete work.

**T41 — acceptance obligation.** Interrupt a receipt write and exercise an invalid path type; preserve prior artifacts and failures. Check permissions at creation, not only final handoff.

**Boundary of the lesson.** These corrected engineering errors do not prove incorrect rule semantics or an actual data leak.

**Skill gates:** G09, G10. **Test execution:** not run in this review.

<a id="e42"></a>

## E42 — Skill rules encourage literal compliance without mechanism coverage

**Evidence status:** `source_visible_instruction_design_risk`. **Sources:** `K:59-80`; `K:97-123`; `K:156-160`; `T:1178`; `T:3774-3781`.

**Observed/reviewed basis.** The skill already has a two-positive/two-negative floor, a fixture-driven constraint instruction, historical 1.30.0 examples, and warnings. The trace nevertheless repeats unsafe ok and late integration problems.

**Invalid inference.** Reading the skill, meeting fixture counts, or adding more MUST sentences demonstrates reliable authoring.

**Failure consequence.** Overfit tests, ambiguous historical authority, and unmeasured skill effectiveness.

**Generalization.** Skill clauses name a trigger, action, required evidence, counterexample, and stop condition, and are evaluated through agent behavior.

**Required authoring action.** Keep a compact mandatory core; preserve complete examples as scoped teaching evidence; add mechanism-based obligations and a trace library. Test old versus revised instructions on held-out tasks.

**T42 — acceptance obligation.** Run blinded paired cold-start authoring trials with fixed tools and budgets; measure semantic regressions, unsupported claims, unnecessary model calls, and honest no-rule outcomes.

**Boundary of the lesson.** This proposal has documentation checks only; do not call the skill empirically successful until the authoring trials are executed.

**Skill gates:** G06, G10, G12. **Test execution:** not run in this review.

## Attribution

Adapted authoring guidance builds on Lu1sDV’s OpenGrep Rule Creator and its Trail of Bits Semgrep Rule Creator attribution at revision `82fe8226252622fa807643bdca1710901198553a`. The adapted guidance is distributed under CC BY-SA 4.0; preserve the original skill’s `ATTRIBUTION.md` and `LICENSE`. Third-party source/rules retain their own terms. No upstream endorsement or newly verified engine result is implied.
