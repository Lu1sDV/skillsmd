# Sources, admission decisions and evaluation

Maintainer reference, researched 2026-11-04. Do not preload it during ordinary work.
Public mechanisms were synthesized into original wording and examples; no third-party
skill, template, script or private historical transcript is bundled here.

## Evidence policy

- Primary tool documentation establishes documented behavior, not measured usefulness.
- Source inspection establishes what a prompt/script says, not whether agents obey it.
- Practitioner reports expose failure examples; they do not establish prevalence.
- Empirical findings retain their task, model, comparator and measurement limits.
- Council agreement and model review are design evidence, not owner approval or efficacy.
- A quotation, trace link or hash establishes provenance/identity, not semantic correctness.

## Sources and what was admitted

| Source | Useful contribution | Limit / admission decision |
|---|---|---|
| [Addy Osmani, spec-driven-development](https://github.com/addyosmani/agent-skills/blob/main/skills/spec-driven-development/SKILL.md) | Assumptions, capability scoping, explicit review, existing-format reuse | MIT upstream. Adapt mechanisms; do not import sibling dependencies, file-count/time thresholds or duplicated project rules |
| [GitHub Spec Kit](https://github.com/github/spec-kit) and [existing-project guidance](https://github.github.io/spec-kit/how-to/existing-projects.html) | Bounded changes, separation of intent and plan, reuse in brownfield projects | MIT upstream. Tool conventions are not universal requirements; inspect the installed version |
| [Spec Kit evolving specs](https://github.github.io/spec-kit/how-to/evolving-specs.html) | Different persistence models and explicit reconciliation | No automatic semantic synchronization is assumed |
| [Kiro Quick Spec](https://kiro.dev/docs/specs/quick-spec/) and [bugfix specs](https://kiro.dev/docs/specs/bugfix-specs/) | Gate-free option for well-understood work; current/expected/unchanged distinction | Vendor guidance, not a controlled comparison; do not copy proprietary templates |
| [OpenSpec](https://github.com/Fission-AI/OpenSpec) | Capability deltas and maintained specifications | MIT upstream; a structural validator is not proof of code/spec correspondence |
| [Tech Leads Club skills](https://github.com/tech-leads-club/agent-skills) | Scoped approval records, obligation coverage, heavy/lean workflow alternatives | Skill prose is CC BY 4.0; code licensing differs. No text imported; validator presence cannot authenticate approval |
| [Böckeler, Kiro / spec-kit / Tessl](https://martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html) | Spec-first / spec-anchored / spec-as-source distinctions; overproduction and misread discovery notes | Practitioner experience on particular tool versions, not universal outcome evidence |
| [Example Mapping](https://cucumber.io/blog/bdd/example-mapping-introduction/) and [acceptance criteria versus scenarios](https://lizkeogh.com/2011/06/20/acceptance-criteria-vs-scenarios/) | Separate general rules, concrete examples and unanswered questions | Practice guidance; no mandatory Gherkin grammar or example quota adopted |
| [EARS](https://alistairmavin.com/ears/) | Optional condition/event/response phrasing | Grammar does not prove completeness; no language-specific prescription |
| [SWE-bench Verified](https://openai.com/index/introducing-swe-bench-verified/) | Underspecified tasks and checks that reject valid implementations | Benchmark-construction evidence, not a measured effect of this skill |
| [Mathews and Nagappan, test-generation evaluation](https://arxiv.org/abs/2412.14137) | Code-derived tests can preserve bugs rather than challenge intent | Particular tools/dataset; not a reason to ban reading implementation or characterization |
| [Tufano et al., Grounding AI Agents in Contracts](https://arxiv.org/abs/2608.17177) | Contract extraction before test generation in an industrial experiment | Contracts mined from already-fixed code; human approval bypassed; bundled treatment, not a spec-before-implementation experiment |
| [OpenAI, detecting misbehavior](https://openai.com/index/chain-of-thought-monitoring/) | Skip-all hook, weakened assertions and implementation-side oracle bypass examples | Illustrative RL-training examples, not deployed-agent failure rates |
| [pytest skip/xfail semantics](https://docs.pytest.org/en/stable/how-to/skipping.html) | Expected failure is not a passing product check | Framework mechanism; project policy still decides appropriate retention of findings |
| [Anthropic multi-agent research](https://www.anthropic.com/engineering/multi-agent-research-system) | Explicit delegated context, artifact handoffs and coordination limits | Vendor experience; no universal mandate for multiple agents |
| [Agent Skills specification](https://agentskills.io/specification) and [evaluation guidance](https://agentskills.io/skill-creation/evaluating-skills) | Portable bundle structure, progressive disclosure, matched baseline runs | Format validation is not behavioral validation; small pilots are not superiority evidence |
| [OMX deep-interview @509a299](https://github.com/Yeachan-Heo/oh-my-codex/blob/509a299d586b48f145c2c7a7baac8ce08d01a015/skills/deep-interview/SKILL.md) | Facts before questions, assumption follow-ups, boundary scenarios, closure test | Not the OMC namesake. Weights, thresholds and caps are uncalibrated; the final spec is Markdown, while mode state and question payloads are JSON. Its non-numeric gates are prose; question-obligation coordination is runtime, not semantic readiness or an edit barrier (static reading, not executed) |
| [Ambig-SWE](https://arxiv.org/abs/2502.13069) | Models detect underspecification unreliably and interact mainly when prompted; interaction helped (relative gain) | One benchmark, simulated user, prompted interaction. Supports asking, not any wording, score or runtime gate; over-asking was also observed |
| [Nygard, architecture decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) | Architecturally significant choices; consequences and status of a decision | Normative. Supports a comparison, not a mandatory ADR or gate; no study of agents making architecture decisions was found |

## Important empirical boundary

The Google study used 90 historical bugs and generated contracts from fixed code before
test generation. It bypassed human approval. Its reported detection gain was 9.8 percentage
points at five attempts per bug; the single-attempt difference was not statistically
significant. The treatment also used approximately 38% more tokens and included test
suggestions. These findings do not isolate contract wording, human gates, or this skill.
Model-judge preference over tests is not executed bug-detection superiority over humans.

Other inspected evidence included a [self-published Uvik benchmark](https://uvik.net/blog/spec-driven-development-benchmark/)
and [SkillsBench](https://arxiv.org/abs/2602.12670). The former has commercial-interest,
single-team/model/language and harness-comparison limits; the latter concerns skills broadly,
not this SDD workflow. Neither licenses a universal size threshold or a claim that this
bundle is the “best” or improves delivered software.

## Explicit admission decisions

| Decision | Rationale |
|---|---|
| Adopt a four-question semantic core | Keep intended behavior, preservation, acceptance basis and open decisions visible without a mandatory form |
| Adopt risk-proportionate approval | Honor existing gates and missing material decisions; repeated document approval is not an established universal optimum |
| Preserve strict phase gates as an alternative | Appropriate when the owner or governance requires them, without making them every user's default |
| Improve assumptions into scoped decisions/holds | Surfacing an assumption is not permission to implement it; durable handoffs must preserve unresolved choices |
| Reuse existing contracts and formats | Avoid competing sources of truth and maintenance burden |
| Default to a dated change record, not perpetual maintenance | A living specification needs a real consumer and owner; follow established project policy |
| Use meaning-based amendments | Byte changes cannot reliably classify intent; uncertain acceptance changes need the authorized decision |
| Preserve stage-relative completion | A reproduction, a characterization and a repair have different expected evidence |
| Report actual skip/expected-fail status | Do not mislabel skipped tests as failed, or expected failures as passing product evidence |
| Reject mandatory separate spec/code/test agents | Role names and fresh contexts are not independent truth or enforcement |
| Reject universal falsifiers, fail-first, mutation or repetition quotas | Complementary checks and task stages require different evidence; target genuine oracle doubt |
| Reject hash/status schemas, scripts, adapters and deny-until-approved hooks in this bundle | No demonstrated need for a new runtime; use existing host controls when required |
| Keep execution and critical boundaries inline | They are needed before a reference can be missed; references deepen rather than hide the core |
| Keep council deliberation outside runtime instructions | The authoring process is not a user workflow requirement |
| Adopt an action-specific readiness check (§3) | Separates information, authority and required evidence for one action; a visible line only for a material item, hold, delegation or handoff. Benefit unmeasured; examples-only and no change remain credible |
| Adopt a compact design-comparison prompt (§4) | Pattern names and reversibility do not settle semantics or authority; recommend, adopt and implement stay separate. Not an ADR, option quota or gate |
| Reject ambiguity scores, thresholds, round caps, one-question rounds, JSON state and gate agents | Uncalibrated, compensating arithmetic; no consumer needing structured state. A READY label or score is a claim, never authorization |
| Reject duration, file-count or description-phrase triggers | Consequence and coupling, not minutes or file count, determine process depth. No new-project, architecture or duration phrase has selection evidence |
| Teach through examples 4–7; require inline only what is a rule | Greenfield, vague quality, version-skew and design-comparison cases were the missing teaching; any required rule stays in SKILL.md |
| Do not change repository licensing | Original prose and public citations; no imported licensed template needing a new repo-wide decision |
| Adopt an optional two-file default layout (`spec.md` + `implementation.md`) | Applies only where no spec system exists, so "no mandatory file layout" holds. Split by authority: owner approves WHAT; agent maintains HOW. Matches Spec Kit/Kiro separation; benefit unmeasured |
| Adopt a checklist closeout (§5) | User-requested: after implementation, each checklist item is verified verbatim, none omitted. One pass over delivered state, one row per item; self-authored unless an independent reviewer was requested. Not a loop-until-clean rule and not a gate agent |
| Name drafting, resuming and checklist closeout in the description; mark §2 rows from “Data and state” down as conditional | Routing probe (simulated, one model, 2 samples) lost these body capabilities to plain-verb rival skills; the always-matching rows contradicted “smallest form”. Effect of the new wording unmeasured. Not a duration/file-count/new-project phrase |

## Evaluate claims separately

[Scenario cases](../evals/scenarios.json) supply realistic prompts and expected outcomes,
not a new harness. Execute them in a disposable workspace, never against real production
resources. Expected outcomes belong to the grader, not the agent's task prompt.
Use an agent-facing bundle copy without `evals/`; keep grading data outside the agent's
workspace and restrict access when the host supports it. A “do not read the grader”
instruction alone is not isolation. Preserve a complete bundle separately for link and
installation checks; a deliberately reduced exercise copy is not an installation test.

1. **Static validity:** frontmatter, links, bundle portability. Does not test agent behavior.
2. **Explicit-use smoke:** fresh context reads this skill, performs a scenario, and leaves
   observable output/effects. Grade harmful actions, omissions and false completion—not
   exact wording, required heading count, or a claim that the skill was read.
3. **Incremental value:** matched with/without runs under the same model, tools, task and
   owner answers. A fuller comparison can add plain planning and the Addy Osmani skill.
4. **Natural discovery:** a separate trial exposes only normal skill metadata and a natural
   request. Forcing the agent to read SKILL.md cannot measure activation or routing.
5. **Reliability:** use repeated/held-out tasks and analysis appropriate to clustered runs
   before making comparative claims. No fixed repeat count or statistical test is mandated.

Pilot a baseline before scoring a larger experiment. Keep pilot selection separate from
scored runs; do not hide required information simply to make the baseline fail. Hide the
grader, not the user's requirements. Check fixtures/reference outputs independently when
they are treated as truth. Score verified completion, harmful action, wrong completion,
appropriate unresolved work and unnecessary abstention together; otherwise refusal wins.

Record authorship and review of tasks, skill, references and scorer. Author-designed cases
are an author-run diagnostic even when another model grades them. Report costs and raw
results honestly. A small null result, a ceiling task or an unrelated test cannot establish
that guidance is useless or justify deleting a safety guard.

When revising the bundle, inventory removed capabilities, activation triggers and consumer
promises. Preserve them elsewhere, replace them deliberately or explain their removal.
Use observed failures to improve general rules, not to add special cases matching a grader.
Keep bulky run transcripts and private research outside the installed bundle.
