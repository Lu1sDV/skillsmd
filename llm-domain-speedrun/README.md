# llm-domain-speedrun

A Claude Code skill for rapidly learning unfamiliar technical domains using an LLM as a structured private tutor.

## What It Does

Provides a 4-phase protocol for bridging fundamental knowledge gaps under tight deadlines:

1. **Courage Building** — Bridge new concepts to your existing domain knowledge via LLM metaphors
2. **Maximum Throughput** — Structured 6-step learning loop with strict timeboxing
3. **Simulated Pressure** — Practice without compiler, IDE, or safety nets
4. **Consolidation** — Teach others, light review, rest before performance

Key principles: LLM never outputs code first (only conceptual hints), you always rewrite in your own style, rotate LLM contexts every 2-3 problems, and verbalize algorithms to build stress-resilient recall.

## Origin

Extracted from [My Google Recruitment Journey (Part 1)](http://blog.dominikrudnik.pl/my-google-recruitment-journey-part-1) by Dominik Rudnik — a telecom developer who went from zero algorithmic knowledge to passing Google's online technical interview in one week using this protocol.

## Installation

### Via Claude Code Plugin

```
/plugin install llm-domain-speedrun@Lu1sDV/skillsmd
```

### Manual

```bash
cp -r llm-domain-speedrun ~/.claude/skills/
```

## When to Use

- Rapid interview preparation (algorithms, system design)
- Learning a new programming paradigm under deadline
- Onboarding to an unfamiliar technical domain quickly
- Any situation where traditional learning methods have previously failed
