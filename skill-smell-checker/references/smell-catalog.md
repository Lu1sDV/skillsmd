# Skill Smell Catalog

Source: David Boram Hong, Aaron Imani, and Iftekhar Ahmed, *From Anatomy to
Smells: An Empirical Study of SKILL.md in Agent Skills*, arXiv:2607.01456v2,
Table III.

The paper defines 26 smells. Its hybrid detector treats five as statically
detectable and 21 as semantically detectable. Use the published definitions
below as the decision boundary; do not add new smells to a paper-based audit.

## Static smells

Run `scripts/check_static_smells.py`; do not replace these checks with model
judgment.

| ID | Smell | Published decision rule |
|---|---|---|
| LSB | Lengthy Skill Body | Body exceeds 5,000 words. |
| LSN | Lengthy Skill Name | Frontmatter `name` exceeds 64 characters. |
| LSD | Lengthy Skill Description | Frontmatter `description` exceeds 1,024 characters. |
| XID | XML Included Description | Frontmatter `description` contains XML tags. |
| BP | Backslash Path | `SKILL.md` denotes paths with backslashes instead of forward slashes. |

Harness implementation notes:

- Word counts use whitespace-separated body tokens and exclude frontmatter.
- Character counts use Unicode code points as counted by Python.
- `XID` matches tag-shaped text, not bare angle-bracket comparisons.
- `BP` matches path-shaped backslashes, not every code escape.
- Missing or unsupported frontmatter syntax produces a warning. It is not
  evidence that frontmatter smells are absent.

## Semantic smells

For each smell, inspect the full file and relevant bundled resources. Return
`present`, `absent`, or `uncertain`, with a quote or precise section reference.

### Under-Specified Guidance

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| TSW | The Stepless Workflow | Describes an entire workflow as one prose block instead of decomposing it into steps. | Can the agent identify the workflow stages and their order without reconstructing them from prose? |
| TOB | The Option Buffet | Provides multiple alternative tools or libraries without recommending a default. | Where alternatives exist, is a default or selection rule stated? |
| MUS | Missing Utility Script | Omits utility scripts for tasks better handled with scripts. | Does repeated, fragile, or deterministic work have a bundled script when one would materially improve reliability? |
| MDT | Missing Decision Tree | Lacks decision guidance for choosing the right situational approach. | When execution branches materially, are the conditions and choices explicit? |

### Over-Prescribed Guidance

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| SOC | Series of Commands | Prescribes exact steps and order instead of allowing the agent to adapt execution. | Are commands an adaptable example/objective, or an unnecessarily rigid script encoded in prose? |

Do not flag necessary low-freedom procedures merely because they are ordered.
Look for rigidity that prevents adaptation without adding correctness or safety.

### Missing Verification and Feedback Loop

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| NVS | No Validation Step | Treats output generation as one-shot, without validation loops. | Does the skill require a check that can falsify the completion claim? |
| EWP | Execute Without a Plan | Directs complex execution without an intermediate planning or validation stage. | For genuinely complex work, is there a plan/checkpoint before irreversible or broad execution? |
| NAH | Never Asks Human | Provides no mechanism to request human feedback. | Does it identify conditions where missing intent, authority, or destructive choice requires a human? |

### Missing Follow-Through Guards

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| RL | Rationalization Loophole | Gives no guidance discouraging skipped required steps. | Is there an explicit completion guard against silently skipping required work or validation? |
| NPT | No Progress Tracking | Requires a multi-step workflow without a progress mechanism. | For long or multi-file work, can the agent track pending, complete, and blocked items? |

### Context Bloat

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| UD | Undelegated Detail | Embeds low-level implementation detail instead of delegating it to references or scripts. | Does core `SKILL.md` contain bulky detail that is only conditionally needed or executable deterministically? |
| CSD | Confusing Skill Description | Description lacks at least one of what it does, when to use it, or keywords. | Can routing determine capability, trigger context, and distinguishing terms from frontmatter alone? |

`CSD` is semantic even though it concerns frontmatter: deciding whether the
three elements are meaningfully present requires contextual judgment.

### Missing Safeguards

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| NG | No Guardrails | Lacks guardrails against inappropriate or impossible tasks. | Are trust boundaries, destructive actions, impossible prerequisites, and unsafe scope changes handled? |
| BG | Buried Gotchas | Fails to highlight critical warnings or caveats with recommended gotcha headers. | Are easy-to-miss critical warnings prominent rather than buried in prose? |
| MUR | Missing Usage Rules | Omits rules governing when or how the skill should be used. | Are invocation boundaries and core usage constraints explicit? |
| MC | Missing Caveats | Omits common caveats and their resolution. | Are likely failure modes paired with recovery or escalation guidance? |

### Inadequate Contextual Grounding

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| ME | Missing Example | Provides no examples that help the agent obtain sufficient context. | Is at least one concrete example present where examples materially disambiguate use? |
| TSS | Time Sensitive Skill | Contains time-sensitive information that requires current time and becomes outdated. | Does the file hardcode facts likely to expire without requiring live verification? |

### Convention and Style Violations

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| USN | Unclear Skill Name | Name does not clearly convey the capability or action. | Does the name distinguish this skill's purpose from unrelated tasks? |
| NTPD | Non Third Person Description | Description is not written in third person, risking inconsistent discovery. | Does the description state what the skill does in third-person form rather than addressing the reader? |

### Unstructured Output

| ID | Smell | Published definition | Review question |
|---|---|---|---|
| MT | Missing Template | Omits a template even though the agent must produce a specific format. | If output structure matters, is a schema or template supplied? |

## Interpretation limits

- The taxonomy is derived by inverting 26 best practices collected from 29
  sources; the paper does not establish a causal effect for each smell.
- The paper reports weighted precision `0.79`, recall `0.78`, and F1 `0.78` for
  its 21-smell LLM detector on 53 manually labeled skills.
- Existing authoring guidance covered only 7 of 13 observed high-level semantic
  components. Do not label unsupported preferences as paper-defined smells.
- Presence is contextual. Examples, plans, templates, scripts, decision trees,
  and human feedback mechanisms are required only where the skill's task shape
  makes them useful.
