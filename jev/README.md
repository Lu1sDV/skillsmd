# jev

Write and improve **Jev** programs — TypeSafe's judgment model behind
`POST https://api.typesafe.ai/v1/systemone`. Jev reads one state, answers
every question in the request independently and in parallel, and returns
probability distributions over the answer spaces you define. Code owns the
control flow, the arithmetic, and the policy; Jev owns the snap judgments.

A good Jev question is one a knowledgeable person answers in a second, given
the right context. Break bigger calls into small questions and compose the
answers in code.

## What it covers

- **Primitive selection** — Choice vs Score vs Noul by how code consumes the
  answer, plus the `other`-option and crisp-condition rules.
- **Instruction craft** — one property per question, backticked state paths,
  structured `instructions` objects (`question`, `focus`, `inspect`, `note`,
  `compare`, `field`).
- **Criteria writing** — contrastive Choice options, standalone
  situation-based Score levels, Noul boundary pairs, concrete short examples.
- **State building** — send only what the questions need, compute arithmetic,
  dates, and counts in code, 64k shared / 32k longest-question token budgets,
  state-steering awareness.
- **Full HTTP API reference** — endpoint, request body, all three question
  types with limits (255 options, 2–10 Score levels), response body, all three
  answer shapes, and the 401/422/429/529 error table with backoff guidance.
- **Composition patterns** — speculative fan-out, the second-request rule,
  confidence-gated routing (act / confirm / hand off), composite scoring,
  intent routing, taxonomy walk, counting, dates, extraction — with a
  complete curl → JSON → stdlib Python example plus four short examples.
- **Revision loop** — symptom → cause → fix table, labeled-data judging,
  one-or-two-questions-per-revision discipline, and the final checklist.

## Install

```bash
cp -r jev ~/.claude/skills/
```

Or via the marketplace:

```
/plugin marketplace add Lu1sDV/skillsmd
/plugin install jev@Lu1sDV/skillsmd
```

## Sources

Official docs: [jev-1.13 jaggedness](https://docs.typesafe.ai/model-jaggedness/jev-1.13),
[primitives](https://docs.typesafe.ai/primitives),
[patterns](https://docs.typesafe.ai/patterns),
[confidence](https://docs.typesafe.ai/confidence),
[API reference](https://docs.typesafe.ai/api).
Full list in `SKILL.md` → Sources.
