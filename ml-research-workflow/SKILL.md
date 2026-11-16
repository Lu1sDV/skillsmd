---
name: ml-research-workflow
description: >
  End-to-end ML and systems research workflow: autonomous two-loop experimentation
  (autoresearch), structured research ideation and creative thinking, publication-ready
  ML and systems paper writing (NeurIPS, ICML, ICLR, ACL, AAAI, COLM, OSDI, SOSP,
  ASPLOS, NSDI, EuroSys), academic plotting (Gemini architecture diagrams and
  matplotlib/seaborn charts), conference talk slides (Beamer and PPTX), and
  Agent-Native Research Artifacts (ARA compilation, session provenance, and Seal
  Level 2 epistemic rigor review). Triggers on 'autoresearch', 'brainstorm research',
  'ml paper', 'systems paper', 'academic plot', 'conference talk', 'Beamer slides',
  'research artifact', 'ARA', or 'rigor review'.
---

# ML Research Workflow

Three focused references covering the full research lifecycle. Open only the
reference the task needs; do not preload all.

| Task / Tool | Read |
|---|---|
| Autonomous experiment loops (`autoresearch`), `research-state.yaml`, structured research brainstorming, creative thinking frameworks | [Ideation & autoresearch](references/ideation-and-autoresearch.md) |
| ML/AI or systems paper writing, citation verification, LaTeX templates, academic plotting (Gemini / matplotlib), Beamer & PPTX conference talks | [Paper writing & talks](references/paper-writing-and-talks.md) |
| Compiling papers/repos into Agent-Native Research Artifacts (`ara/`), post-task provenance logging, Seal Level 1 & Level 2 rigor review | [Research artifacts (ARA)](references/research-artifacts.md) |

## What each covers

- **Ideation & autoresearch** — two-loop autonomous research orchestration
  (bootstrap → fast inner loop → reflective outer loop, git protocol, `findings.md`,
  20-minute continuity loops), 10 structured brainstorming lenses, and 8 cognitive-science
  creativity frameworks.
- **Paper writing & talks** — Narrative/What-Why-So-What framing, 5-sentence abstracts,
  12-page systems blueprints, programmatic Semantic Scholar + CrossRef DOI citation
  verification, Gemini diagram generation + colorblind-safe matplotlib charts, and
  poster/spotlight/oral/invited talk slides in Beamer and `python-pptx`.
- **Research artifacts (ARA)** — 4-stage epistemic compilation of papers/repos/logs into
  `ara/` (`PAPER.md`, `logic/`, `src/`, `trace/`, `evidence/`), post-task session
  provenance tagging (`user`, `ai-suggested`, `ai-executed`, `user-revised`), and
  6-dimension Seal Level 2 rigor review (`level2_report.json`).

## Universal rules

- **Never fabricate citations or results**: fetch every BibTeX entry programmatically
  via DOI/Semantic Scholar/arXiv (mark unverified ones as `[CITATION NEEDED]`); never
  invent experimental numbers, traces, or deployment claims.
- **Lock protocols before running**: in autonomous experimentation, commit `protocol.md`
  to git *before* executing experiments, and separate confirmatory from exploratory results.
- **Sanity-check before trusting metrics**: verify convergence, absence of NaN/Inf,
  baseline reproduction, and data loading before analyzing primary metrics.
- **Verify claims against evidence**: keep exact source numbers in `evidence/`, keep
  `experiments.md` directional, and verify file paths, LaTeX compilation (`latexmk -pdf`),
  and venue CFP limits before submission.
- **Use forward slashes**: never use backslash file paths in documentation or commands.
