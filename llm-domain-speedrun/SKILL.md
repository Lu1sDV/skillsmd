---
name: llm-domain-speedrun
description: Use when someone needs to rapidly learn an unfamiliar technical domain under a tight deadline, when previous attempts through books, courses, or unstructured practice have failed, or when bridging a fundamental knowledge gap using an LLM as a private tutor
---

# LLM-Assisted Domain Speedrun Learning

## Overview

A structured protocol for using an LLM as a private conceptual tutor to rapidly bridge fundamental knowledge gaps in unfamiliar domains. The core principle: **the LLM teaches concepts through metaphors and hints, never code — you write all code yourself in your own style.**

This technique was battle-tested in a one-week Google interview preparation speedrun, taking someone from "unable to solve the simplest LeetCode problem" to completing 34 problems (18 Medium, 1 Hard) and advancing to on-site interviews.

## When to Use

- You have a **fundamental knowledge gap** in a domain (not just rustiness)
- Previous learning attempts (books, videos, courses) have failed
- You're under a **hard deadline** (days to weeks, not months)
- You have a day job and limited study time
- The domain has learnable patterns (algorithms, system design, new programming paradigm, etc.)

**When NOT to use:** When you have time for a proper course, when the domain requires hands-on lab work an LLM can't simulate, or when the gap is purely about memorizing facts (use flashcards instead).

## The Protocol

### Phase 1: Courage Building (Day 1)

**Goal:** Prove to yourself you CAN learn this domain. Start with problems that bridge to knowledge you already have.

Set up the LLM with these constraints:

```
Protocol:
- Act as a private tutor fully committed to teaching me new concepts
- Do NOT output any code
- Provide only conceptual hints and attack vectors
- Use real-world examples and metaphors from MY domain
- If a metaphor would help it click, use one
```

**Why no code:** Forcing yourself to write ALL code — even wrong code — maps concepts into muscle memory far deeper than reading solutions. The LLM's job is to reshape your mental model, not hand you implementations.

**Why your domain:** Ask the LLM to explain new concepts using analogies from your existing expertise. A hash map is like a routing table. A queue is like a packet buffer. A tree is like a network topology. Cross-domain metaphors create instant neural pathways that abstract explanations never will.

Start with problems that feel like "just for-loops and arrays" — but that secretly introduce key patterns (hash sets for O(1) lookup, frequency tables, etc.). The goal is to build **courage** that you can do this, plus discover that familiar structures have non-obvious properties.

### Phase 2: Maximum Throughput (Day 2)

Switch to a structured 6-step loop per problem with a strict timebox (10-30 min per problem):

```
1. LLM selects next concept (goal: cover as many patterns as possible)
2. You attempt the problem (strict timebox: 10-15 min)
3. If stuck → show your attempt → LLM gives conceptual restructuring (still no code)
4. You rewrite the LLM's conceptual solution IN YOUR STYLE
5. LLM judges your rewrite and provides alternative approach WITH code
6. You rewrite the best solution in YOUR style — your variable names, your logic flow
```

**The "your style" rule is critical.** Never blindly rewrite LLM code. Force every solution through your own mental model and naming conventions. This refactors your coding idiolect to incorporate new concepts without destroying existing fluency. You may write patterns that aren't textbook-optimal — that's fine and necessary at this stage.

**After each solution:** Show your full code to the LLM. Ask for a better approach, and the pros/cons of each implementation. This discussion cements understanding.

### Phase 3: Simulated Pressure (Day 3+)

Once basic patterns are learned, add interview-realistic constraints:

- **Don't compile before showing to LLM.** Simulate not having a compiler. This reveals how much you depend on error messages vs. understanding.
- **Write solutions on paper or plain text** — no IDE, no autocomplete, no LSP.
- **Narrate your thinking out loud** as you code. This builds the verbalization skill that reconstructs knowledge under stress (see Stress Recovery below).

Key insight from the source material: **"Easy" problems are often the hardest** because they introduce entirely new concepts. "Medium" problems are typically variations of concepts from Easy problems. Don't treat difficulty as linear — treat Easy as "new pattern" and Medium as "apply learned pattern with a twist."

### Phase 4: Consolidation (Final Days)

- Practice only patterns similar to previously learned ones — no new concepts
- **Explain concepts to other people.** Teaching forces reconstruction from memory, not recognition. The source author reconstructed binary search under interview stress specifically because he had explained it to friends days earlier.
- Day before performance: **do not study.** Play games, rest. Only lightly review previous solutions by mentally recreating the writing process without focusing on any single problem.

## Context Management

LLM context degrades after approximately **5 problems** in a single conversation (not time-based — problem-based). Symptoms: coaching becomes inconsistent, LLM gets "softer," hints become less sharp.

**Strategy: Separate contexts by purpose.**

| Context | Purpose | Lifespan |
|---------|---------|----------|
| Curriculum context | Generate problem lists, track progress | Long-running |
| Solving context | Work through 2-3 problems from same domain | Short, fresh per domain batch |
| Discussion context | Deep-dive on a single tricky concept | Single-use |

When starting a fresh solving context, re-paste your tutor protocol constraints. Do NOT paste previous solutions — you want fresh coaching eyes.

## Stress Recovery Technique

Under stress, **procedural memory (code patterns) fails before conceptual understanding.** The source author knew binary search conceptually but couldn't write the iterative syntax under time pressure.

The fix: **verbalize the algorithm aloud as a reconstruction technique.** Explain to the interviewer (or rubber duck) exactly how you're slicing the problem space. This retrieves the conceptual understanding, which can then be translated back into code — even imperfect code.

This only works if you've practiced verbalization throughout your learning. Build it into every session from Day 1.

## Quick Reference

| Principle | Rule |
|-----------|------|
| LLM outputs code? | **Never in Phase 1.** Only in step 5 of Phase 2 loop, after your attempt. |
| Copy LLM code? | **Never.** Always rewrite in your own style. |
| Time per problem | 10-15 min attempt, 30 min total including discussion |
| Context rotation | Fresh conversation every 2-3 problems |
| Difficulty progression | Easy (new concept) -> Medium (variation) -> consolidation |
| Pre-performance | Rest day. No new material. Light review only. |
| Compile during practice? | Not in Phase 3+. Simulate interview conditions. |
| Stuck under pressure? | Verbalize the algorithm. Reconstruct from concepts, not syntax. |

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Watching YouTube explanations | This is procrastination dressed as learning. Solve problems instead. |
| Reading algorithm books | Too slow under deadline. Math-heavy descriptions hide the insight. Use LLM metaphors. |
| Grinding LeetCode without protocol | Burns time and energy without pattern recognition. Use the 6-step loop. |
| Copying LLM solutions verbatim | Zero retention. Force through your own style. |
| One long LLM conversation | Context degrades. Rotate every 2-3 problems. |
| Skipping Easy, jumping to Medium | Easy problems teach new concepts. Medium applies them. Don't skip the foundation. |
| Studying night before | Sleep deprivation kills working memory. Rest and lightly review instead. |
| Ignoring verbalization practice | When stress hits, you'll freeze. Narrate from Day 1. |

## Real-World Impact

Source: A telecom developer with zero algorithmic background used this exact protocol over one week:
- Went from unable to solve the simplest LeetCode problem to completing 34 problems
- Learned patterns that had eluded them for over 10 years of sporadic attempts
- Advanced past Google's online technical interview to on-site rounds
- Key quote: "I am still amazed at how an LLM helped me understand a problem space I had been trying to grasp for over 10 years."
