# The Three Generation Variants — Exact Templates & Formulas (FuzzGPT §3.2)

Notation: `M` = the LLM (probability of generating a sequence). `p_target` = the
target query naming the **fuzz target** (an API in the paper's DL examples; equally
a syscall, SQL feature, opcode, … — see `SKILL.md`). `d` = bug description.
`c` = code.

Both variants consume the annotated `(fuzz target, description, code)` dataset from
`pipeline.md`. Few-shot is the **default** (FuzzGPT-FS). For the retrieval pathway
(RT), see `references/retrieval.md` — it feeds into these same templates with
retrieved examples instead of randomly-selected ones.

---

## 3.2.1 — Few-shot learning (FuzzGPT-FS) — DEFAULT

Prepend the target query with **K examples** from the annotated dataset. Each
example has three parts: **fuzz-target name** (an API name in the paper's
examples), **Bug description** (the issue/PR title), and the **bug-triggering
code**.

### Chain-of-Thought (CoT) prompting — this is the key design choice

Instead of jumping straight to code, the query gives only the target fuzz target
and asks the model to **first predict a plausible `Bug description:`** (a NL guess
at the bug + its triggering condition), **then** generate code conditioned on it.
This "reason then generate" step is what lets FuzzGPT produce unusual programs —
the predicted description (e.g. *"buffer sharing issue when copying array…"*) primes
rare code. **Ablation (Table 3): CoT raises coverage** (23945 vs 22922) and
fuzz-target diversity; without CoT valid-rate is higher but coverage and diversity drop.

### Few-shot prompt template (Figure 4 ①)

```
API: torch.Tensor.apply_
Bug description: Tensor.apply_ fails
x = torch.randn(3, 3)
x.apply_(lambda a: a+1)

...  (K total examples, K=6 default, picked randomly)  ...

API: torch.gather
Bug description:            ← model completes the description, THEN the code
```

The header of the final block is the **target query**: the target fuzz target and
an empty `Bug description:` for the model to fill. (Template shown verbatim with
the paper's `API:` label and PyTorch examples; when retargeting, rename `API:` to
your unit and supply examples of that unit.)

**Few-shot probability:**
```
M(c_fs | E_K, p_target) = M(c_fs | E_K, p_target, d_fs) · M(d_fs | E_K, p_target)
```
where `E_K = {<p1,d1,c1>, …, <pK,dK,cK>}` is the concatenation of K example tuples.
The factorization *is* the CoT: predict `d_fs` first, then `c_fs` given `d_fs`.

`K` matters (Table/Figure 8): `K=0` is by far the worst; coverage rises sharply as
K grows, then **decreases** if K is too large (too many examples distract the model
and restrict creativity). K=6 is the paper's sweet spot.

### w/o CoT baseline

Remove the `Bug description: …` line from every example and the query; ask the
model to generate code directly from the fuzz target. Higher valid-rate, lower
coverage and fuzz-target diversity — keep CoT unless you specifically need more
valid programs.

---

## 3.2.2 — Zero-shot learning (FuzzGPT-ZS)

No examples. Reuse a **real** historical snippet directly, so concrete bug
ingredients (special values, edge shapes) survive verbatim into the new program.

### Completion (default ZS variant)

1. Emit the comment: `# The following code reveals a bug in {fuzz_target}`
2. Randomly pick a real bug-triggering snippet `c_e` from the dataset.
3. Randomly **remove a portion of its suffix**; keep the first `j` lines `c_e[:j]`
   as the prompt for the model to complete.

```
# The following code reveals a bug in torch.gather
x = torch.randn(3, 3)          ← c_e[:j], real partial snippet (suffix truncated)
                               ← model completes from here
```

**Probability:** `M(c_zs-comp | p_comp, c_e[:j])`. The full fuzzing program is
`c_e[:j] + c_zs-comp` (partial real code + completion).

### Editing

Give a **complete** real snippet and ask the model to edit it to use the new fuzz
target — designed so the LLM reuses most of the original code.

```
# Edit the code to use torch.gather
x = torch.randn(3, 3)          ← complete real snippet c_e
x.apply_(lambda a: a+1)
```

**Probability:** `M(c_zs-edit | p_edit, c_e)`.

### completion-NL (ablation baseline)

Only a natural-language description, **no code** given to complete. Used to prove
that the *partial code* is what matters: completion >> completion-NL on coverage
(25893 vs 22917), even though completion has the lower valid rate (the unusual
partial code is harder to complete validly). Editing has the lowest valid rate of
all (1.22%) — fully-automatic editing to a new fuzz target is hard — but still finds bugs.

**Why ZS at all:** it constrains the search space (must stay compatible with the
partial program), which lowers valid-rate but triggers more interesting fuzz-target
*interactions* and reuses already-valuable program paths. FuzzGPT-ZS achieved the
**highest coverage on PyTorch**. It underperforms on TensorFlow purely because
there are too few snippets (633) to cover its 3316 APIs — ZS needs a rich corpus.

---

## Picking a variant

| Want… | Use |
|-------|-----|
| Best all-round, highest fuzz-target + valid-program coverage | **FS (default)** |
| Reuse real edge-case code verbatim; rich bug corpus available | **ZS completion** |
| Highest single-library coverage, lots of snippets | **ZS** |
| Target-specialized generation, no GPU training, any generator | **RT** (retrieval-augmented FS default; RAG-ZS mode optional) — see `references/retrieval.md` |
| Combine for max bug yield | Run FS + ZS + RT and union the crashes |
