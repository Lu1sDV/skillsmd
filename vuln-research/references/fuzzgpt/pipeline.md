# Dataset Construction & Annotation (FuzzGPT §3.1, §4)

The dataset is pairs of `(bug-triggering code snippet, buggy fuzz-target label)`,
plus the issue/PR title used as a natural-language "bug description". This is the
fuel for all three generation variants. ("Fuzz target" = the unit you steer
generation toward — an **API** in the paper's DL-library study, but equally a
compiler flag, SQL feature, syscall, or format field; see `SKILL.md`. The paper's
examples below use APIs because the subjects are PyTorch/TensorFlow.)

## 3.1.1 — Mining bug history from GitHub

Crawl the target repo's **issues and pull requests**. Identify bug-triggering code
from two sources:

1. **Issues associated with accepted or pending PRs.** Search these bug reports for
   *all* code blocks (the reproduction snippets) and **concatenate them together**
   per issue into one snippet.
2. **PRs containing code blocks in their commit messages.** Included because some
   PRs fix bugs that never had an issue.

For each issue/PR, also extract the **title** — it becomes the `Bug description`
in prompts and fine-tuning samples.

The paper used an HTML crawler with Python `requests`. **In practice, just use `gh`:**

```bash
# Issues that are bug reports, with body (contains repro code blocks)
gh issue list -R pytorch/pytorch --label bug --state all --limit 2000 \
  --json number,title,body > issues.json

# Closed PRs (mine commit messages + linked issue bodies)
gh pr list -R pytorch/pytorch --state closed --limit 2000 \
  --json number,title,body,commits > prs.json

# Extract fenced code blocks from a body field (python/py/```), then filter
```

Code-block extraction: pull everything inside triple-backtick fences (and
indented blocks in older issues). Concatenate multiple blocks from the same
issue in order.

### Cleaning (do all of these — §4)

- Filter out **error messages / tracebacks** pasted into the code blocks.
- Remove code lines that contain **only the inputs and outputs of executions**
  (e.g. REPL echo lines, printed tensor dumps).
- Drop snippets that **fail a syntax check** (`ast.parse` for Python; the target
  language's parser otherwise).
- Drop snippets **longer than 256 tokens**.

### Reference corpus sizes (what the paper collected)

| Library | Snippets | Note |
|---------|----------|------|
| PyTorch | **1750** | |
| TensorFlow | **633** | Fewer PRs; TF devs less active confirming bugs, rarely include code blocks in PRs |

Fewer snippets directly hurts zero-shot (less real code to reuse) — see
`evaluation.md` (FuzzGPT-ZS underperforms on TF for exactly this reason).

## 3.1.2 — Automated buggy fuzz-target annotation (self-training)

Each snippet exercises **multiple** fuzz targets (several APIs, in the DL case),
so the buggy one can't be extracted directly. Use a **self-training** approach:
manually label a few seeds, then let the LLM label the rest.

- **K = 6** randomly-sampled snippets are **manually annotated** with the buggy
  fuzz-target name. These become the few-shot examples.
- For each unlabeled snippet, build a prompt = the 6 labeled examples + the target
  snippet, and query the LLM to **complete the buggy fuzz-target name**.
- Query with **`temperature = 0`** (deterministic greedy decoding) to get the most
  confident prediction.

### Figure 3 — buggy-fuzz-target annotation prompt template

Reproduced verbatim from the paper, so the literal completion label is `Buggy API:`
(the paper's subjects are DL libraries). Each example block is
`code snippet → Title → Buggy API`. Repeat K=6 times, then append the target snippet
and let the model complete `Buggy API:`. **When retargeting, rename the label to
your unit** — `Buggy syscall:`, `Buggy SQL feature:`, `Buggy opcode:` — the
self-training mechanism is identical.

```
x = torch.randn(3, 3)
x.apply_(lambda a: a+1)
Title: Tensor.apply_ fails
Buggy API: torch.Tensor.apply_

...  (5 more labeled examples)  ...

x = torch.Tensor([1,1,1])
x.index_fill_(0, torch.LongTensor([100]), -1)
a = torch.Tensor([1,1,1]).cuda()
a.index_fill_(0, torch.LongTensor([100]).cuda(), -1)
Title: x.index_fill_() on cuda tensors doesn't do bounds checks
Buggy API:                       ← model completes: torch.Tensor.index_fill_
```

### Why imprecise labels are OK

The goal is only to **steer** the model to generate many programs per targeted
fuzz target by pairing a fuzz target with code that contains interesting
bug-triggering patterns. Even a "wrong" label is fine as long as the labeled fuzz
target actually appears in the code: the model still learns the non-strict
fuzz-target→pattern mapping, and FuzzGPT often reveals a bug in a *different* fuzz
target than the one targeted.

**Measured labeling quality:** 76% precision on a random sample of 100 PyTorch
issues/PRs. Mislabeled examples still let FuzzGPT-FS beat the zero-shot baseline.

## Output of this phase

An annotated dataset of `(buggy_target, bug_description_title, code_snippet)`
triples (the `buggy_target` field holds an API name in the DL case), one per mined
bug, ready to feed `prompt-templates.md`.
