# Paper Writing, Plotting & Conference Talks

Distilled from `ml-paper-writing`, `systems-paper-writing`, `academic-plotting`, and `presenting-conference-talks`.

---

## 1. Citation Verification (Zero-Hallucination Rule)

AI-generated citations have a ~40% error rate. **Never write BibTeX from memory.**

1. Search via Exa MCP (`claude mcp add exa -- npx -y mcp-remote "https://mcp.exa.ai/mcp"`) or Semantic Scholar API.
2. Verify existence in **2+ sources** (Semantic Scholar + CrossRef/arXiv).
3. Fetch BibTeX programmatically via DOI; verify the attributed claim actually appears in the paper.
4. If unverified, insert an explicit placeholder and notify the author:
   `\cite{PLACEHOLDER_author2024_verify}` + `% TODO: Verify`.

```python
from semanticscholar import SemanticScholar
import requests

sch = SemanticScholar()
for p in sch.search_paper("attention mechanism transformers", limit=5):
    print(p.title, p.paperId, p.externalIds.get("DOI", "N/A"))

def doi_to_bibtex(doi: str) -> str:
    r = requests.get(f"https://doi.org/{doi}", headers={"Accept": "application/x-bibtex"})
    r.raise_for_status()
    return r.text
```

---

## 2. ML/AI Paper Writing (`ml-paper-writing`)

Target venues: NeurIPS (9p), ICML (8p), ICLR (9p), ACL (8p), AAAI (7p), COLM (9p). All require double-blind anonymization, LaTeX, and unlimited references/appendices.

### Narrative & Time Allocation

- **Narrative Principle (Nanda)**: every paper needs **The What** (1-3 cohesive claims), **The Why** (rigorous empirical evidence), and **The So What** (why readers care). If you cannot state the contribution in one sentence, you do not yet have a paper.
- **Equal time allocation**: (1) Abstract, (2) Introduction, (3) Figures, (4) Everything else combined. Reviewers read: Title → Abstract → Intro → Figures → maybe Methods.

### Section Formulas

- **Figure 1**: convey core idea or strongest result; vector PDF/EPS; standalone caption; grayscale/colorblind-safe.
- **Abstract (5-sentence Farquhar formula)** — delete generic openings ("LLMs have achieved remarkable success..."):
  1. What you achieved ("We introduce / prove / demonstrate...")
  2. Why this is hard and important
  3. How you do it (with specialist keywords)
  4. What evidence you have
  5. Your most remarkable number/result
- **Introduction (1-1.5 pages max)**: problem statement, brief approach, 2-4 bullet contribution list (1-2 lines each); Methods must start by page 2-3.
- **Methods**: conceptual outline/pseudocode, all hyperparameters, architectural details for reproduction; save ablations for Experiments.
- **Experiments**: state the claim tested before each experiment, what to observe ("the blue line shows X"), error bars (specify SD vs SE), hyperparameter search ranges, compute (GPU type/hours), and seed methodology.
- **Related Work**: organize **methodologically** ("One line uses X [refs] whereas we use Y because..."), never paper-by-paper.
- **Limitations & Checklists**: mandatory at major venues (ICML: Broader Impact; ICLR: LLM disclosure + reciprocal reviewing; ACL: Limitations + Ethics; NeurIPS: Paper checklist + lay summary).

### Prose Craft

- **Gopen & Swan**: keep subject and verb close; put emphasis at sentence end (stress position); put context/old info before new info; one point per paragraph; put action in verbs ("We analyzed", not "We performed an analysis").
- **Lipton / Perez**: replace vague "performance" with "accuracy"/"latency"; drop hedging ("may", "can") unless genuinely uncertain; delete filler ("actually", "very", "basically", "essentially"); minimize bare pronouns ("This shows" → "This result shows"); keep terminology strictly consistent (Steinhardt).

### LaTeX Template & Format Conversion Rules

- Copy the **entire** template directory (`.sty`, `.bst`, `Makefile`), never just `main.tex`. Compile unmodified template first (`latexmk -pdf main.tex` or `pdflatex` + `bibtex`). Never edit `.sty` files.
- **Tables**: use `booktabs`, bold best value per metric, include `↑`/`↓` direction symbols, right-align numbers, consistent precision.
- **Resubmission / venue conversion**: start fresh with target template, copy only section content (never copy `\usepackage` preambles), adjust for page limits (move proofs to appendix, condense related work), update blind-review self-citations, and address prior reviews without mentioning the prior submission.

---

## 3. Systems Paper Writing (`systems-paper-writing`)

Target venues: OSDI (12p USENIX), NSDI (12p USENIX), SOSP (12p ACM SIGOPS), ASPLOS (11p ACM SIGPLAN), EuroSys (12p ACM). *Verify current-year CFP limits before submission.*

### 12-Page Structural Blueprint

| Section | Pages | Key Content |
|---|---|---|
| **Abstract** | ~0.25 | 150-250 words, 5 sentences: context → gap → thesis ("X is better for Y in env Z") → approach/results → impact |
| **S1 Introduction** | 1.5-2 | Problem (with concrete numbers) → Gaps G1-Gn → Thesis ("X better for Y in Z") → 3-5 numbered contributions mapped to sections |
| **S2 Background & Motivation** | 1-1.5 | Define-before-use terminology (Heiser) + Production observations (O1-O3) leading to design insights |
| **S3 Design** | 3-4 | Architecture diagram first → Module-by-module design → Alternatives considered & why rejected |
| **S4 Implementation** | 0.5-1 | Prototype language, LOC, integration, non-obvious engineering choices |
| **S5 Evaluation** | 3-4 | Setup → End-to-end vs baselines → Microbenchmarks/Ablations → Scalability |
| **S6 Related Work** | 1 | Grouped by methodology + comparison table for 4+ systems |
| **S7 Conclusion** | 0.5 | 3 sentences: hypothesis, approach, key result |

### Systems-Specific Patterns & Rules

- **Four structural patterns**: Gap Analysis (`G1-Gn` → `A1-An`), Observation-Driven (`O1-O3` → design insights), Contribution List (numbered claims mapped to sections), Thesis Formula ("X is better for applications Y running in environment Z").
- **Rule of three in Evaluation (Irene Zhang)**: state every experimental conclusion three times — section opening (hypothesis), section closing (result), and figure caption (evidence).
- **Never fabricate** production observations, traces, or deployment claims.

---

## 4. Academic Plotting (`academic-plotting`)

Rule of thumb: **boxes and arrows → Gemini (`gemini-3-pro-image-preview`)**; **numerical axes → `matplotlib`/`seaborn`**. Always save generation scripts at `figures/gen_fig_<name>.py`.

### Workflow 1: Architecture Diagrams (Gemini)

1. Extract visual entities (group if >8), relationships (data flow = solid, control = gray, error = dashed red), and layout (left-to-right, layered, hub-and-spoke, hierarchical).
2. Pick one consistent style per paper: **Sketch** (warm off-white `#FAFAF7`, watercolor washes), **Modern Minimal** (rounded 12px cards, subtle shadow, bold section fills), **Illustrated Technical** (2px line-art icons, left 4px color strip, bezier arrows), or **Classic Accent Bar** (pale gray bands, 8px left accent bar, flat).
3. Structure prompt in 6 sections: Framing → Visual Style block → Color Palette (exact hexes) → Layout (exact text) → Connections (every arrow) → Constraints (e.g., "SPELL EXACTLY", no clip art).
4. Read `GEMINI_API_KEY` from environment (never hardcode), run **3 attempts** with `response_modalities=["IMAGE", "TEXT"]`, pick best, save `figures/fig_<name>.png`.

### Workflow 2: Data Charts (`matplotlib` / `seaborn`)

- **Chart selection**: time/steps → line plot (with mean ± std `fill_between`); N methods × M benchmarks → grouped bar; single ranking → horizontal bar; correlation → scatter; matrix → heatmap; breakdown → stacked bar (avoid pie charts).
- **Colorblind-safe palettes**: Okabe-Ito (`#E69F00`, `#56B4E9`, `#009E73`, `#F0E442`, `#0072B2`, `#D55E00`, `#CC79A7`) or Ocean Dusk (`#264653`, `#2A9D8F`, `#E9C46A`, `#F4A261`, `#E76F51`; highlight "Ours" in `#E76F51` coral, baselines in `#B0BEC5`).
- **Venue column widths (inches)**: NeurIPS/ICLR `5.5` (single/full), ICML `3.25` single / `6.75` full, ACL `3.3` / `6.8`, AAAI `3.3` / `7.0`.
- **Export**: always export vector `.pdf` for LaTeX (plus 300 DPI `.png` if needed); omit in-figure titles (use LaTeX captions).

---

## 5. Conference Talks (`presenting-conference-talks`)

### Talk Types & Pacing

| Talk Type | Duration | Slides | Pacing / Focus |
|---|---|---|---|
| **Poster-talk** | 3-5 min | 5-8 | 30-60s/slide; Title, Problem, Insight, Overview, Main Result, Takeaway + QR |
| **Spotlight** | 5-8 min | 8-12 | 30-45s/slide; Problem, Motivation, Insight, Overview, 2 Design Highlights, Eval, Ablation, Summary |
| **Oral** | 15-20 min | 15-22 | 45-90s/slide; Full arc + design alternatives + implementation + breakdown/ablation/scalability + demo |
| **Invited** | 30-45 min | 25-40 | 60-120s/slide; Field context, multiple demos, deep analysis, hidden Q&A backup slides |

### Delivery & Generation

- **Mike Dahlin's 3-level rule**: "Say what you're going to say, say it, then say what you said" at talk, section, and slide levels.
- **Systems talks**: state the takeaway *before* showing an eval figure; use progressive reveal (`\only<N>`) for architecture walkthroughs with a concrete request; always have a pre-recorded backup for live demos; font size ≥ 24pt; ≤ 6 bullets per slide.
- **Speaker notes format**: `[Timing: X min]`, `[Key point]`, `[Transition to next slide]`.
- **Dual output**:
  - **Beamer PDF**: `\documentclass[aspectratio=169]{beamer}` with `\usetheme{metropolis}`, `\note{...}`, compile with `latexmk -pdf slides.tex`.
  - **Editable PPTX**: `python-pptx` (`13.333 × 7.5` in 16:9), populate `slide.notes_slide.notes_text_frame.text`.
