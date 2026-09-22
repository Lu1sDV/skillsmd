# Evaluation Protocol & Reproduction Targets (FuzzGPT §5, §6)

Use this to reproduce the study or validate that a re-implementation lands near the
paper's numbers.

> **On "API" in this file:** the numbers below are the paper's *actual*
> PyTorch/TensorFlow measurements, where the fuzz target is a library API. Read
> "API coverage", "valid APIs", "N APIs" etc. as the **DL-library instance** of
> the generic *per-fuzz-target* metrics — on a different target the same metric
> counts distinct syscalls, SQL features, opcodes, … covered. Values are left
> verbatim so this stays a faithful reproduction target.

## Research questions

- **RQ1** — How do the generation variants (FS / ZS) compare to each other? (FT removed; RT validation protocol below)
- **RQ2** — How does FuzzGPT compare to existing fuzzers?
- **RQ3** — How do FuzzGPT's key components contribute? (ablations)
- **RQ4** — Can FuzzGPT detect new bugs?

## Subjects & setup

- Libraries: **PyTorch** and **TensorFlow** (most popular open-source DL libs).
- Versions for the head-to-head: **PyTorch v1.12, TensorFlow v2.10** (== TitanFuzz),
  same set of public Python APIs as TitanFuzz. New-bug hunting on **nightly** builds.
- RQ3 ablations: **50 randomly sampled PyTorch APIs**, **avg of 5 runs** (cost).
- Variants: **FuzzGPT-FS** (default), **FuzzGPT-ZS**. (FT replaced by RT — see RT validation protocol below.)

## Baselines

API-level: **FreeFuzz**, **DeepREL**, **∇Fuzz (NablaFuzz)**.
Model-level: **Muffin** (TensorFlow only — no PyTorch support).
LLM-based SOTA: **TitanFuzz** (and **TitanFuzz-seed-only**).
All run under default configs.

## Metrics

| Metric | Definition |
|--------|------------|
| **Code coverage** | Python **line** coverage via `coverage.py`; **exclude** coverage added by the oracle checking (for fair comparison) |
| **API coverage** | # distinct DL APIs covered |
| **Unique valid programs** | executes w/o exception AND invokes target API ≥1, deduplicated |
| **Valid(%)** | valid unique programs / all generated unique programs |
| **Detected bugs** | # unique real bugs |
| **Unique crashes** | # distinct crashes (proxy for bug-finding; used in FS/ZS/FT vs TitanFuzz Venn) |

## Reproduction targets — RQ2 (Table 2: coverage)

Codebase-under-test totals: PyTorch **113538** lines / 1593 APIs; TensorFlow
**269448** / 3316.

| Technique | PyTorch Code Cov | PyTorch API | TF Code Cov | TF API |
|-----------|------------------|-------------|-------------|--------|
| FreeFuzz | 15688 (13.82%) | 468 | 78548 (29.15%) | 581 |
| DeepREL | 15794 (13.91%) | 1071 | 82592 (30.65%) | 1159 |
| ∇Fuzz | 15860 (13.97%) | 1071 | 89722 (33.30%) | 1159 |
| Muffin | NA | NA | 79283 (29.42%) | 79 |
| TitanFuzz-seed-only | 22584 (19.89%) | 1329 | 103054 (38.35%) | 2215 |
| TitanFuzz | 23823 (20.98%) | 1329 | 107685 (39.97%) | 2215 |
| **FuzzGPT-FS-25** | 32305 (28.45%) | 1296 | 130312 (48.36%) | 1937 |
| **FuzzGPT-FS** | **35426 (31.20%)** | 1377 | **146487 (54.37%)** | 2309 |
| **FuzzGPT-ZS** | **38284 (33.72%)** | 1237 | 126193 (46.83%) | 1460 |

Headline: **+60.70% / +36.03%** code coverage over TitanFuzz on PyTorch / TensorFlow
(best variant: ZS on PyTorch 33.72%, FS on TF 54.37%). FuzzGPT has *similar API
coverage* to TitanFuzz but *much higher code coverage* → it hits more interesting
code paths per API. Even **FuzzGPT-FS-25** (only 25 Codex programs, matching
TitanFuzz's seed count, no mutation) beats full TitanFuzz — and coverage **doesn't
saturate** at 100 generations (Figure 5), unlike TitanFuzz's mutation phase.

## Reproduction targets — RQ1 (Table 1: paradigm comparison)

| Lib | Variant | Valid APIs | All APIs | Valid Prog | All Prog | Valid% | Cov |
|-----|---------|-----------|----------|-----------|----------|--------|-----|
| PyTorch | FS | 1377 | 1588 | 42496 | 154904 | 27.43% | 35426 |
| PyTorch | ZS | 1237 | 1553 | 7809 | 132111 | 5.91% | 38284 |
| TF | FS | 2309 | 3314 | 54058 | 310483 | 17.41% | 146487 |
| TF | ZS | 1460 | 3157 | 4650 | 233887 | 1.99% | 126193 |

Reading it: **FS** = most APIs + valid programs (rich 6-example context).
**ZS** = lowest valid-rate (must complete unusual partial code) but highest PyTorch
coverage; weak on TF (too few snippets). These FS/ZS rows are also the **RT
acceptance bar** — RT targets parity with FS on single-source corpora.

## Reproduction targets — RQ3 ablations

- **FS CoT** (Table 3): w/ CoT 23945 cov / 190 valid APIs vs w/o 22922 / 181.
  CoT ↑coverage & API diversity, ↓valid-rate. **Keep CoT.**
- **FS K-sweep** (Figure 8): K=0 worst; coverage peaks then declines for large K.
- **ZS prompting** (Table 4): editing 19440 cov / 1.22% valid; completion-NL 22917 /
  10.17%; **completion 25893 / 6.86%** → partial *code* >> NL-only.
- **Example selection** (§7): MMR-based similar/diverse selection ≈ **random**
  selection on a single-library corpus. Random is competitive — don't over-engineer
  example selection. This finding motivates RT's fallback-to-random guard.

## RT validation protocol (FuzzGPT-derived)

RT is not in the paper. Its acceptance bar is the retained FS coverage above. Run on
DL libraries as the concrete reproduction example; the protocol generalises to any
target domain.

1. **Parity (single-source corpus):** on a sample of target units, run random-FS vs
   RAG-FS; assert `coverage(RAG-FS) ≥ coverage(random-FS) − ε`. Expectation:
   approximately equal (consistent with the §7 MMR≈random finding).
2. **Scale win (enlarged / multi-source corpus):** assert
   `coverage(RAG-FS) > coverage(random-FS)`. Expectation: RT wins when random
   sampling goes off-target across a heterogeneous corpus.
3. **Fallback correctness:** for a target unit with no neighbours above τ≈0.2,
   verify RT's selection distribution matches random (KS test or visual inspection).

See `references/retrieval.md` for the full RT methodology and component details.

## Reproduction targets — RQ4 (Table 7: bugs)

Default = **FuzzGPT-FS with all oracles**.

| Lib | Total | Confirmed Unknown (Fixed) | Confirmed Known | Pending | Won't Fix | High Prio |
|-----|-------|---------------------------|-----------------|---------|-----------|-----------|
| PyTorch | 43 | 33 (6) | 5 (1) | 1 | 4 | 3 |
| TensorFlow | 33 | 16 (0) | 7 (0) | 5 | 5 | 8 |
| **Total** | **76** | **49 (6)** | **12 (1)** | 6 | 9 | **11** |

49 confirmed new bugs = **25 crashes + 24 inconsistencies**, of which **30 are
AD-related**. Only **11** were findable by TitanFuzz (+ our oracles); only **2** by
just rerunning historical programs. **Unique-crash Venn (PyTorch, paper):** FS/ZS/FT
combined = 19 distinct crashes, **14** not found by TitanFuzz, only **1** unique to
TitanFuzz; FS alone = 2.5× TitanFuzz's unique crashes. (Paper's FT column is
historical data only — FT is replaced by RT in this skill.)

### Two canonical example bugs (Figure 9) — good sanity-check repros

```python
# (a) PyTorch crash — 0-dim tensor → floating point exception. High priority.
x = torch.ones((1,1,1,1,0))
def func(x):
    layer = torch.nn.PixelShuffle(1)
    return layer(x)
jacrev(func)(x)   # FuzzGPT learned the 0-size-dim ingredient from a past bug
```
```python
# (b) TensorFlow — buffer-sharing / copy bug. Confirmed security vuln (Google).
# Bug description: Buffer sharing issue when copying array from NumPy to TensorFlow
x = np.arange(10)
x_copy = tf.experimental.numpy.copy(x)
x[3] = 42   # x_copy[3] becomes 42 on CPU, stays 3 on GPU → CPU/GPU oracle catches it
```
(b) is the CoT payoff: the model first predicted the description "buffer sharing
issue…", which steered it to the unusual copy-then-mutate program TitanFuzz can't
produce.

## §7 discussion findings worth keeping

- **No-history ChatGPT variant** (Table 8): instruct prompts ("…in a way you have
  not seen in your training dataset", "…in a very creative way", etc.) all beat the
  typical-usage baseline on API coverage, at lower valid-rate. Weakest overall;
  fallback only.
- **Example selection:** MMR-based similar/diverse selection ≈ **random** selection.
  Random is competitive — modern LLMs learn even from dissimilar examples, and
  random gives diverse ingredients. Don't over-engineer example selection.

## Threats to validity (as stated)

Internal: implementation/experiment bugs → mitigated by code review. External:
subject choice → two most-popular libs + widely-used metrics (real-bug detection,
coverage).
