# Intelligence Brief: AI Agent Architecture for CTF Cybersecurity Competitions
## Unconventional & Creative Approaches — Agent 3 of 6 (RETRY)

---

## 1. Executive Summary

This brief synthesizes intelligence from **12+ open-source projects**, **15+ academic papers**, **Skills Marketplace** inventories, and multi-source web intelligence to architect a research strategy for AI agents competing in Capture The Flag (CTF) competitions. The analysis emphasizes **unconventional paradigms**: neuro-symbolic hybrids, genetic/evolutionary algorithms for exploit generation, adversarial self-play training, formal verification tool integration, and LLM-as-a-judge frameworks. Current state-of-the-art agents achieve **22–44% solve rates** on professional benchmarks, with the highest-performing systems using multi-agent orchestration rather than monolithic LLM loops.

---

## 2. Research Query Taxonomy

The following 10 distinct search vectors were executed across SkillsMP, Tavily, Exa, GitHub grep.app, Context7, and direct API calls:

| # | Query Vector | Target Tool | Purpose |
|---|-------------|-------------|---------|
| 1 | `CTF` keyword + `cybersecurity agent exploit generation` semantic | SkillsMP | Discover available CTF skills in marketplace |
| 2 | `AI agent autonomous CTF capture the flag competition cybersecurity` | Tavily (advanced) | Surface mainstream agent frameworks |
| 3 | `neuro-symbolic AI vulnerability discovery exploitation CTF SAT SMT solver` | Tavily (advanced) | Find hybrid symbolic-neural approaches |
| 4 | `genetic algorithm automatic exploit generation fuzzing CTF challenge` | Tavily (advanced) | Locate evolutionary computation methods |
| 5 | `adversarial self-play reinforcement learning CTF cybersecurity agent training` | Tavily (advanced) | Find MARL and adversarial training papers |
| 6 | `open source AI CTF agent framework LLM autonomous hacking capture the flag` | Exa web search | Map open-source repository landscape |
| 7 | `academic paper LLM agent CTF cybersecurity benchmark NYU CTFBench PentestGPT` | Exa web search | Identify top-tier academic publications |
| 8 | `neuro-symbolic vulnerability discovery SMT SAT formal verification automatic exploit generation paper` | Exa web search | Deep-dive into formal methods integration |
| 9 | `class Agent` / `def solve(` + `ctf` path | GitHub grep.app | Find agent class implementations in CTF repos |
| 10 | `angr` library query + automatic exploit generation | Context7 | Retrieve canonical tool documentation |

---

## 3. Open-Source CTF AI Agent Landscape

### 3.1 Active Multi-Model Racing Swarms
**verialabs/ctf-agent** — Autonomous CTF solver that won **1st place at BSidesSF 2026** by solving all 52/52 challenges. Uses a **coordinator LLM** managing **solver swarms** that race multiple AI models (Claude Opus, GPT-5.4, GPT-5.4-mini) in parallel against individual challenges. Cross-solver insights shared via message bus. Each solver runs in isolated Docker containers.
- **URL**: https://github.com/verialabs/ctf-agent

### 3.2 Planner-Executor Multi-Agent Frameworks
**NYU-LLM-CTF/nyuctf_agents (D-CIPHER)** — Implements the **Planner-Executor-AutoPrompter** architecture. Planner agent generates overall strategy; heterogeneous Executor agents complete delegated sub-tasks; Auto-prompter explores the environment to seed initial prompts. Achieves **SOTA 22.0% on NYU CTF Bench, 22.5% on Cybench, 44.0% on HackTheBox**.
- **URL**: https://github.com/NYU-LLM-CTF/nyuctf_agents

**aielte-research/HackSynth** — Dual-module architecture: **Planner** generates commands, **Summarizer** processes feedback iteratively. Benchmarked on PicoCTF and OverTheWire (200 challenges). Best performance with GPT-4o. Includes dedicated HackSynth-GRPO reinforcement learning variant for cryptographic CTFs.
- **URL**: https://github.com/aielte-research/HackSynth

### 3.3 Autonomous Penetration Testing Agents
**GreyDGL/PentestGPT** — Three self-interacting modules (reasoning, generation, parsing) for end-to-end autonomous pentesting. Published at **USENIX Security 2024** with Distinguished Artifact Award. Achieves **228.6% task-completion increase** over GPT-3.5 baseline. Docker-first with 20+ security tools pre-installed.
- **URL**: https://github.com/GreyDGL/PentestGPT

**0ca/BoxPwnr** — Modular benchmarking framework supporting **7 solver strategies** (single_loop_xmltag, claude_code, codex, hacksynth, external) across **11 platforms** (HTB, PortSwigger, Cybench, picoCTF, TryHackMe). Contains **6,000+ published traces** and achieves **97.1% on XBOW, 88.4% on picoCTF**.
- **URL**: https://github.com/0ca/BoxPwnr

### 3.4 AI/ML-Specific Red Teaming
**dreadnode/AIRTBench-Code** — Rigging-based agent for AI/ML CTF challenges. Evaluated 12 models across 70 Crucible challenges. Claude-3.7-Sonnet solved 43/70 (61%). Uses Python SDK + Strikes cyber evaluation API.
- **URL**: https://github.com/dreadnode/AIRTBench-Code

### 3.5 Agent-Focused CTF Competitions
**agentbeats/agentctf** — Framework for **AgentCTF x AgentXploit** competition. Participants build AI agents that autonomously exploit vulnerabilities across 20+ frameworks including LangChain and AutoGPT. Uses **AAA (Agentified Agent Assessment)** paradigm.
- **URL**: https://github.com/agentbeats/agentctf

### 3.6 Modular CTF Agent with MCP
**Coff0xc/CTF-MCP** — ReAct-based agent with explicit `AgentState` enum (IDLE, THINKING, ACTING, OBSERVING, FINISHED, ERROR), `AgentStep` dataclass, and `AgentMemory` system tracking solved patterns, conversation history, and notes.
- **URL**: https://github.com/Coff0xc/CTF-MCP

### 3.7 Attack Graph & Plan Tree Agents
**cortexc0de/argus-lite** — LLM builds **branching attack strategies** (plan trees), not linear lists. Supports 3-agent teams (Recon + Vuln Scanner + Exploit) with attack graph visualization. 11 built-in security skills (subfinder, nuclei, dalfox, sqlmap, ffuf, etc.).
- **URL**: https://github.com/cortexc0de/argus-lite

### 3.8 RAG-Based CTF Experimentation
**fyxme/flagseeker** — Modular AI Plain Agent with **RAG integration**, containerised Docker environments, multi-threading benchmarking, and OpenRouter model switching. Designed for rapid prototyping of prompts and RAG configurations.
- **URL**: https://github.com/fyxme/flagseeker

---

## 4. Academic Literature Review

### 4.1 Benchmark & Evaluation Papers
**NYU CTF Bench** (Shao et al., NeurIPS 2024) — 200 CTF challenges from NYU CSAW competitions across 6 categories. Introduces automated framework with function-calling LLMs.
- **Paper**: https://proceedings.neurips.cc/paper_files/paper/2024/file/69d97a6493fbf016fff0a751f253ad18-Paper-Datasets_and_Benchmarks_Track.pdf
- **Repo**: https://github.com/NYU-LLM-CTF/NYU_CTF_Bench

**Cybench** (Zhang et al., ICLR 2025) — 40 professional-level CTF tasks from 4 competitions with subtask breakdown. Evaluated 8 models across 4 scaffolds (structured bash, action-only, pseudoterminal, web search).
- **Paper**: https://arxiv.org/abs/2408.08926
- **Repo**: https://github.com/andyzorigin/cyber-bench

**InterCode-CTF** (Yang et al., NeurIPS 2023) — 100 picoCTF tasks framed as interactive coding RL environment. Uses Docker containers with Bash as action space.
- **Paper**: https://arxiv.org/abs/2306.14898
- **Repo**: https://github.com/princeton-nlp/intercode

### 4.2 Agent Architecture Papers
**PentestGPT** (Deng et al., USENIX Security 2024) — Three self-interacting modules addressing context loss. Won Distinguished Artifact Award.
- **Paper**: https://www.usenix.org/system/files/usenixsecurity24-deng.pdf
- **Repo**: https://github.com/GreyDGL/PentestGPT

**HackSynth** (Muzsai et al., arXiv 2024) — Planner + Summarizer dual-module for autonomous penetration testing. Benchmark on PicoCTF & OverTheWire.
- **Paper**: https://arxiv.org/abs/2412.01778
- **Repo**: https://github.com/aielte-research/HackSynth

**D-CIPHER** (NYU, arXiv 2025) — Planner-Executor with heterogeneous executors + Auto-prompter. MITRE ATT&CK mapping for offensive capability evaluation.
- **Paper**: https://arxiv.org/abs/2502.10931
- **Repo**: https://github.com/NYU-LLM-CTF/nyuctf_agents

**RapidPen** (Nakatani, arXiv 2025) — ReAct-style planning + dual RAG (command generation + success-case PTT). Achieves **60% success rate, 200–400s, $0.3–$0.6/run** on HTB.
- **Paper**: https://arxiv.org/abs/2502.16730

### 4.3 AI Red Teaming & Specialized Benchmarks
**AIRTBench** (Dawson et al., arXiv 2025) — 70 AI/ML black-box CTF challenges. Claude-3.7-Sonnet leads at 61%. Frontier models excel at prompt injection (49%) but struggle with system exploitation (<26%).
- **Paper**: https://arxiv.org/abs/2506.14682
- **Repo**: https://github.com/dreadnode/AIRTBench-Code

### 4.4 LLM-as-a-Judge for CTF
**CTFJudge** (NYU, AAAI 2026) — Three-agent evaluation system: (1) decomposes writeups into steps, (2) extracts trajectory actions, (3) performs qualitative comparison. Introduces **CTF Competency Index (CCI)** for partial correctness.
- **Paper**: https://arxiv.org/abs/2508.05674
- **Repo**: https://github.com/NYU-LLM-CTF/CTFJudge

---

## 5. Skills Marketplace Intelligence

### 5.1 CTF Domain Skills (ljagiello/ctf-skills suite)
A mature taxonomy of **9 category-specific skills**, each 1,645 stars:
- `ctf-web` — HTTP applications, APIs, template engines, identity flows, smart-contract frontends
- `ctf-reverse` — Compiled, obfuscated, packed, virtualized targets
- `ctf-pwn` — Binary exploitation, memory corruption, low-level primitives
- `ctf-crypto` — RSA, AES, ECC, lattice attacks, LWE, CVP
- `ctf-forensics` — Disk images, memory dumps, network captures, steganography
- `ctf-malware` — Obfuscated scripts, C2 traffic, PE/.NET binaries
- `ctf-ai-ml` — Adversarial examples, model extraction, prompt injection, membership inference
- `ctf-osint` — Social media, geolocation, DNS records, reverse image search
- `ctf-misc` — Pyjails, bash jails, RF/SDR, DNS oddities, unicode tricks
- **URL**: https://github.com/ljagiello/ctf-skills

### 5.2 Writeup & Evaluation Skills
- `ctf-writeup-generator` (openclaw, 4,230 stars) — Automatic professional CTF writeup generation with flag detection and challenge categorization
- `judge-ctf` (wgpsec, 1,170 stars) — Flag-capture evaluation checklist analyzing failure reasons and providing guidance

### 5.3 Agent Orchestration Skills
- `agentsmith-ctf` (babywyrm, 2 stars) — Agent Smith in CTF mode for vulnerability hunting
- `red-run-legacy` (blacklanternsecurity, 138 stars) — Subagent-based orchestrator (superseded by team-based red-run-ctf)
- `ai-llm-attacks` (1ikeadragon, 5 stars) — Prompt injection, jailbreaking, agent exploitation, RAG poisoning

---

## 6. Orchestration Paradigm Evaluation

| Paradigm | Representative Project | Strengths | Weaknesses | Best For |
|----------|----------------------|-----------|------------|----------|
| **Single-Agent ReAct Loop** | BoxPwnr (single_loop) | Simple, low token overhead, easy to debug | Context loss, no specialization, single point of failure | Rapid prototyping, simple challenges |
| **Planner-Executor Duo** | HackSynth, D-CIPHER | Separation of strategy vs. execution, parallelizable | Coordination overhead, planner may hallucinate sub-tasks | Complex multi-step challenges |
| **Coordinator + Solver Swarms** | verialabs/ctf-agent | Model diversity, fault tolerance, cross-pollination of insights | High API cost, contention for compute | Time-limited competitions with API budget |
| **Three-Module Self-Interaction** | PentestGPT | Mitigates context loss via specialized parsers | Tight coupling between modules, hard to extend | Long-running penetration tests |
| **Attack Graph / Plan Tree** | argus-lite | Explainable attack paths, backtracking, confidence scoring | Graph explosion on complex targets, state tracking cost | Web application testing, known vulnerability chains |
| **MCP-Based Tool Augmentation** | CTF-MCP | Standardized tool interfaces, modular skill injection | Dependency on MCP server availability | Rapid tool integration, enterprise environments |
| **Heterogeneous Multi-Agent** | D-CIPHER (full) | Role specialization, dynamic feedback loops | Complex prompt engineering, inter-agent communication failures | Professional CTF competitions |

### 6.1 Emerging Paradigm: Unconventional & Creative Approaches

#### Neuro-Symbolic Hybrid Exploitation
**QRS** (Query-Review-Sanitize) introduces a neuro-symbolic triad that **generates CodeQL queries from schema definitions** rather than filtering existing scanner outputs. Achieves **90.6% precision** on 20 historical Python CVEs. The Review agent performs semantic reachability verification and synthesizes minimal PoC exploits via constraint solving.
- **Paper**: https://arxiv.org/abs/2602.09774

**SAILOR** (Static Analysis Informed and LLM-Orchestrated Symbolic Execution) automates harness construction by combining static analysis with LLM-based synthesis. Discovers **379 previously unknown memory-safety vulnerabilities** in 6.8M LOC. Without symbolic execution, no approach detects more than 12 vulnerabilities.
- **Paper**: https://arxiv.org/abs/2604.06506

**MoCQ** (Model-Generated Code Queries) uses LLMs to extract vulnerability patterns and express them as queries to program representations from classic static analysis. Discovered **46 new vulnerability patterns** experts missed, with **10% recall and 17.6% precision improvement** over expert-crafted queries.
- **Paper**: https://arxiv.org/abs/2504.16057

**COBALT-TLA** pairs an LLM with the TLA+ model checker in an automated REPL. The LLM generates bounded specifications; TLC acts as semantic oracle. Autonomously discovered the **Optimistic Relay Attack** (an unprompted vulnerability class) within 2 iterations.
- **Paper**: https://arxiv.org/abs/2604.12172

#### Genetic & Evolutionary Algorithms for Exploit Generation
**BertRLFuzzer** combines BERT with PPO reinforcement learning to learn grammar-adhering, attack-provoking mutation operators. Compared against 13 fuzzers on 9 victim websites: **54% less time to first attack, 17 new vulnerabilities, 4.4% more attack vectors**.
- **Paper**: https://arxiv.org/abs/2305.12534

**Enigma** (trace37 labs) uses a **5-Rotor cascade evolutionary fuzzer** targeting DOMPurify XSS sanitization. Employs 20+ targeted null-byte mutation operators with adaptive rotor selection and reinforcement learning guidance. Treats vulnerability discovery as optimization rather than binary testing.
- **Source**: https://labs.trace37.com/blog/dompurify-evolutionary-fuzzer-part1/

**AEG** (Automatic Exploit Generation, NDSS) — The first end-to-end system using **preconditioned symbolic execution** to target likely-vulnerable paths. Analyzes source, generates symbolic constraints, solves them, and produces shell-spawning exploits.
- **Paper**: https://www.ndss-symposium.org/wp-content/uploads/2017/09/Avg.pdf

#### Adversarial Self-Play & Multi-Agent RL
**SELF-REDTEAM** (OpenReview) — Online self-play RL where a single model alternates between attacker and defender roles with hidden Chain-of-Thought. Grounded in zero-sum game theory: if self-play converges to Nash Equilibrium, the defender is safe against any adversarial input.
- **Paper**: https://openreview.net/pdf?id=VqQ1DXEeyo

**C-MADF** (Causal Multi-Agent Decision Framework) — Integrates causal modeling with adversarial dual-policy control. A threat-optimizing Blue-Team policy is counterbalanced by a conservative Red-Team policy. Inter-policy disagreement quantified via **Policy Divergence Score**.
- **Paper**: https://arxiv.org/abs/2604.04442

**Adversarial Policies in Self-Play** (Gleave et al., ICLR 2020) — Demonstrates that state-of-the-art policies trained via self-play harbor serious failure modes exploitable by adversaries trained for <3% of victim training time. Implications: CTF agents should train against adversarial opponents, not just static challenges.
- **Paper**: https://aima.eecs.berkeley.edu/~russell/papers/iclr20-adversarial.pdf

#### Formal Verification as Skills (SMT/SAT)
**Neuro-Symbolic Execution (NeuEx)** combines SMT solving with gradient-based neural optimization. Treats mixed constraint solving as a search problem. Successfully constructs exploits for **13/14 buffer overflow benchmarks**.
- **Paper**: https://arxiv.org/abs/1807.00575

**Stepwise** — Neuro-symbolic proof search for systems verification. Fine-tunes LLMs on proof state-step pairs; symbolic ITP tools repair rejected steps and discharge subgoals. Proves **77.6% of seL4 theorems**, surpassing previous LLM-based approaches.
- **Paper**: https://arxiv.org/abs/2603.19715

---

## 7. Proposed Skill Taxonomy for CTF AI Agents

Based on the intelligence gathered, the following **7-tier skill taxonomy** is proposed for a competitive CTF AI agent:

### Tier 1: Challenge Intake & Classification
- `challenge-classifier` — Categorize challenge into web/pwn/rev/crypto/forensics/misc/ai-ml
- `difficulty-estimator` — Estimate difficulty using metadata, file sizes, first-solve times
- `environment-bootstrapper` — Deploy Docker containers, install dependencies, verify connectivity

### Tier 2: Reconnaissance & Enumeration
- `web-recon` — Subdomain enumeration (subfinder), port scanning (naabu), tech fingerprinting (whatweb)
- `binary-recon` — Checksec analysis, string extraction, symbol table inspection
- `crypto-recon` — Identify cipher types, key lengths, entropy analysis
- `traffic-recon` — PCAP analysis, protocol identification, extraction of embedded files

### Tier 3: Core Exploitation Engines
- `symbolic-exploiter` — **angr**-based symbolic execution for buffer overflow, format string, control-flow hijack (see Context7 canonical code: https://context7.com/angr/angr/llms.txt)
- `web-exploiter` — SQLi (sqlmap), XSS (dalfox), SSTI, command injection, LFI/RFI
- `crypto-exploiter` — RSA attacks (Wiener, Coppersmith, ROCA), AES oracle padding, lattice reduction
- `reverse-synthesizer` — Decompilation (Ghidra/Hex-Rays), pattern matching, deobfuscation

### Tier 4: Neuro-Symbolic & Formal Methods Skills
- `codeql-generator` — Generate CodeQL queries from vulnerability schemas (QRS-style)
- `smt-constraint-solver` — Convert exploit conditions to Z3/claripy constraints
- `harness-synthesizer` — Auto-generate symbolic execution harnesses (SAILOR-style)
- `tla-verifier` — Model-check protocol vulnerabilities with TLC (COBALT-TLA-style)

### Tier 5: Evolutionary & Adaptive Skills
- `genetic-fuzzer` — Evolve payloads via fitness-guided mutation (BERT-RL + genetic algorithm hybrid)
- `success-case-rag` — Retrieve and adapt prior successful exploit chains (RapidPen-style PTT)
- `adversarial-trainer` — Self-play red-team/blue-team training loop for robustness

### Tier 6: Multi-Agent Orchestration
- `planner-agent` — Decomposes challenge into sub-tasks, assigns to executors
- `executor-agent` — Specialized per-category executor (web executor, pwn executor, etc.)
- `summarizer-agent` — Compresses observation history to prevent context loss
- `coordinator-agent` — Manages solver swarms, allocates compute budget, handles racing
- `auto-prompter-agent` — Explores environment to generate high-relevance initial prompts

### Tier 7: Evaluation & Meta-Learning
- `llm-judge` — CTFJudge-style trajectory evaluation against gold-standard writeups
- `cci-scorer` — Compute CTF Competency Index for partial credit
- `hyperparameter-optimizer` — Tune temperature, top-p, max_tokens per challenge category
- `trace-miner` — Extract reusable patterns from BoxPwnr-style attempt traces

---

## 8. Tool Integration Matrix

| Tool | Role | Agent Integration Pattern | Source |
|------|------|--------------------------|--------|
| **angr** | Symbolic execution, AEG | Python API skill; SimulationManager explores paths to target addresses | https://github.com/angr/angr |
| **Claripy/Z3** | SMT constraint solving | Backend for symbolic-exploiter skill; checks satisfiability of exploit constraints | Part of angr ecosystem |
| **CodeQL** | Static analysis query engine | Target for neuro-symbolic codeql-generator skill | https://github.com/github/codeql |
| **sqlmap** | SQL injection automation | Tool skill invoked by web-exploiter executor | https://github.com/sqlmapproject/sqlmap |
| **dalfox** | XSS detection | Tool skill invoked by web-exploiter executor | https://github.com/hahwul/dalfox |
| **pwntools** | Binary exploitation scripting | Library skill for pwn executors; remote interaction and payload construction | https://github.com/Gallopsled/pwntools |
| **Ghidra** | Reverse engineering | Headless analysis skill for reverse-synthesizer | https://ghidra-sre.org/ |
| **Rigging** | LLM interaction framework | Used by AIRTBench for chat pipeline wrapping | https://github.com/dreadnode/rigging |
| **Docker** | Isolated sandbox execution | Executor backend for all agent environments; standard across all major frameworks | Universal |
| **OpenRouter/LiteLLM** | Model routing | Model-agnostic API layer for solver swarms | https://openrouter.ai/ |

---

## 9. Evaluation Metrics & Benchmarks

| Benchmark | Tasks | Categories | Difficulty Range | Best Agent Score | URL |
|-----------|-------|------------|------------------|------------------|-----|
| **NYU CTF Bench** | 200 | 6 (web, pwn, rev, crypto, forensics, misc) | CSAW CTF historical | 22.0% (D-CIPHER) | https://github.com/NYU-LLM-CTF/NYU_CTF_Bench |
| **Cybench** | 40 | 6 | 2 min – 24h 54m FST | 22.5% (D-CIPHER) | https://github.com/andyzorigin/cyber-bench |
| **InterCode-CTF** | 100 | 4 (picoCTF) | High school / undergrad | Varies by model | https://github.com/princeton-nlp/intercode |
| **AIRTBench** | 70 | AI/ML security | Easy – Hard | 61% (Claude-3.7-Sonnet) | https://github.com/dreadnode/AIRTBench-Code |
| **CTFTiny** | 50 | 5 lightweight | Rapid evaluation | Used for hyperparam tuning | https://github.com/NYU-LLM-CTF/CTFTiny |
| **BoxPwnr Traces** | 1,500+ | 11 platforms | Real-world HTB/PortSwigger | 54.9% HTB Labs, 97.1% XBOW | https://github.com/0ca/BoxPwnr-Traces |

### Key Metrics Beyond Binary Success
- **CTF Competency Index (CCI)** — Partial correctness score aligned with human writeups (from CTFJudge)
- **ATT&CK Technique Coverage** — Maps solved challenges to MITRE ATT&CK techniques (from D-CIPHER)
- **Time-to-Shell / Time-to-Flag** — End-to-end latency (RapidPen: 200–400s)
- **Cost-per-Solve** — API token economics (RapidPen: $0.3–$0.6/run)
- **Policy Divergence Score** — Adversarial robustness metric (from C-MADF)

---

## 10. Strategic Recommendations

1. **Adopt Multi-Model Racing for Competitions**: The BSidesSF 2026 winning architecture (verialabs/ctf-agent) demonstrates that **parallel solver swarms** with cross-solver insight sharing dramatically outperforms single-model approaches under time pressure.

2. **Invest in Neuro-Symbolic Tool Skills**: The SAILOR results (379 new vulnerabilities vs. 12 for agentic Claude Code) prove that **LLM + symbolic execution hybrids** massively outperform pure LLM agents on binary exploitation. Every CTF agent should have an `angr`/`claripy` skill tier.

3. **Deploy Genetic/Evolutionary Payload Generation**: For web and binary challenges with large input spaces, evolutionary fuzzers (BertRLFuzzer, Enigma) find vulnerabilities that deterministic search misses. Integrate as a **fallback skill** when standard exploitation fails.

4. **Use Adversarial Self-Play for Robustness**: Train agents against adversarial opponents (SELF-REDTEAM, C-MADF) rather than static challenges. This hardens the agent against unexpected challenge variants and reduces overfitting to known benchmarks.

5. **Implement LLM-as-a-Judge for Continuous Improvement**: CTFJudge-style evaluation provides **granular partial credit** that enables reinforcement learning from incomplete trajectories. Essential for training beyond binary success signals.

6. **Standardize on Docker + MCP**: The convergence across all major frameworks (PentestGPT, HackSynth, BoxPwnr, AIRTBench) on **containerized execution** and **modular tool interfaces** indicates these are non-negotiable infrastructure layers.

7. **Build a Success-Case RAG**: RapidPen's "success-case PTT" RAG achieving 60% success rates demonstrates that **retrieving and adapting prior exploit chains** is more efficient than reasoning from first principles every time.

---

## 11. Source Index

All URLs cited in this brief are reproduced below for verification:

- https://github.com/verialabs/ctf-agent
- https://github.com/agentbeats/agentctf
- https://github.com/fyxme/flagseeker
- https://github.com/aielte-research/HackSynth
- https://github.com/dreadnode/AIRTBench-Code
- https://github.com/cortexc0de/argus-lite
- https://github.com/c-goosen/ai-prompt-ctf
- https://github.com/NYU-LLM-CTF/nyuctf_agents
- https://github.com/GreyDGL/PentestGPT
- https://github.com/0ca/BoxPwnr
- https://github.com/0ca/BoxPwnr-Traces
- https://github.com/Coff0xc/CTF-MCP
- https://github.com/ljagiello/ctf-skills
- https://github.com/andyzorigin/cyber-bench
- https://github.com/princeton-nlp/intercode
- https://github.com/NYU-LLM-CTF/NYU_CTF_Bench
- https://github.com/NYU-LLM-CTF/CTFJudge
- https://github.com/NYU-LLM-CTF/CTFTiny
- https://github.com/angr/angr
- https://proceedings.neurips.cc/paper_files/paper/2024/file/69d97a6493fbf016fff0a751f253ad18-Paper-Datasets_and_Benchmarks_Track.pdf
- https://arxiv.org/abs/2408.08926
- https://arxiv.org/abs/2306.14898
- https://www.usenix.org/system/files/usenixsecurity24-deng.pdf
- https://arxiv.org/abs/2412.01778
- https://arxiv.org/abs/2502.10931
- https://arxiv.org/abs/2502.16730
- https://arxiv.org/abs/2506.14682
- https://arxiv.org/abs/2508.05674
- https://arxiv.org/abs/2602.09774
- https://arxiv.org/abs/2604.06506
- https://arxiv.org/abs/2504.16057
- https://arxiv.org/abs/2604.12172
- https://arxiv.org/abs/2305.12534
- https://labs.trace37.com/blog/dompurify-evolutionary-fuzzer-part1/
- https://www.ndss-symposium.org/wp-content/uploads/2017/09/Avg.pdf
- https://openreview.net/pdf?id=VqQ1DXEeyo
- https://arxiv.org/abs/2604.04442
- https://aima.eecs.berkeley.edu/~russell/papers/iclr20-adversarial.pdf
- https://arxiv.org/abs/1807.00575
- https://arxiv.org/abs/2603.19715
- https://context7.com/angr/angr/llms.txt

---

*End of Intelligence Brief*
