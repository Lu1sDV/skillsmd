---
name: search-first-development
description: >
  Use when existing code or engineering knowledge could change what gets built:
  understanding, debugging, extending, or migrating an existing system; finding reusable
  implementations, libraries, or small mechanisms in mature OSS; comparing or evaluating
  repositories; or before committing to a new subsystem, dependency, rewrite, or growing
  workaround. Not for conceptual explanations, syntax, or generic standalone code.
---

Use this tool when a task can benefit from discovering, understanding, reusing, or analyzing existing engineering knowledge and code. 

The agent should consider selecting this tool when it needs to, as examples:

Find insights: Investigate how a system works, identify architectural patterns, understand dependencies, or discover how a particular problem has been solved. Code logic reuse is a bug killer.

Find existing implementations: Search for reusable code, algorithms, utilities, components, libraries, or examples that address a common engineering task.

Solve engineering problems: Investigate bugs, troubleshoot unexpected behavior, understand root causes, or identify potential fixes based on existing implementations

Understand conventions: Discover coding standards, project structures, design patterns, testing strategies, and established engineering practices.

Understand invariants: Thinking at all invariants is difficult the first times, almost always there will bugs. Find in the mature repositories who already had them.

Avoid reinventing solutions: Determine whether an existing implementation can be reused, adapted, or extended before developing something from scratch.

Avoid bugs and suboptimal solutions: Thinking is hard and it takes time and error to do things well. Nobody codes a repository without CRITICAL bugs at first shot, neither you. Luckily in SWE people did things before us, it's a costly error not analyzing them.

# Repos — Engineering Discovery, Research & Intelligence

## 1. Purpose and core decision

Repos provides access to software repositories containing source code, documentation, tests, configuration, architecture definitions, implementation examples, and engineering decisions. Treat it as an engineering discovery, investigation, research, evaluation, and implementation-intelligence tool—not merely code search.

Use Repos when a task can benefit from discovering, understanding, reusing, comparing, validating, or analyzing existing engineering knowledge and code. Select it when repository evidence could materially reduce uncertainty, prevent incorrect assumptions, reveal existing functionality, avoid duplicated work, expose constraints or invariants, or improve a technical decision.

Think like a senior software architect. Before proposing or building a solution, consider whether the user's codebase, other projects, reference implementations, tests, configuration, documentation, or repository history can provide relevant evidence.

Do not select Repos merely because a request mentions programming, software, an algorithm, a framework, or code generation. The key question is whether inspecting real implementations would materially improve the answer.

**Earn the right to add complexity.** Research exists to change the implementation decision, not to list repositories. Goal: the requested outcome with the least unnecessary long-term responsibility—not maximum reuse, minimum code, or maximum research.

- **Premise first:** separate desired outcome, proposed solution, underlying problem, and the uncertain premise that makes the proposal seem necessary. Investigate the premise before searching for implementations of the proposal.
- **Search by structure, not vocabulary:** name the resource allocated, invariant preserved, state transition, repeated computation, failure mechanism, and workload; look in domains that share it (unfair job scheduling → OS/network schedulers; growing ad-hoc parser → compiler tooling; geometric edge cases → robust geometry; drifting sync → audio/control clocks; repeated computation → query engines, incremental computation). An analogy is a search hypothesis: verify the assumptions that make it transfer.
- **Reuse at the smallest complete level:** configuration/existing capability → existing API or package → module → small internal mechanism (a predicate, encoding, concurrency primitive can embed years of fixes) → borrowed design/algorithm → whole platform → new code. Avoid both rebuilding what exists and importing a platform for one mechanism.
- **Proportional:** if the change is clear and bounded by existing code and contract, just implement it. No candidate quotas, mandatory reports, or universal "best"; stop when further evidence is unlikely to change the decision.

## 2. Senior-architect decision process

Follow this mental sequence before selecting the tool:

1. **Classify the request:** Is it knowledge, discovery, investigation, implementation, optimization, evaluation, validation, migration, or design?
2. **Identify the evidence needed:** Does the task require source inspection, implementation details, dependencies, execution flows, tests, configuration, documentation, history, or invariants? Could examples from other projects distinguish competing approaches or hypotheses?
3. **Choose repository scope:** Internal codebase; similar external projects; reference/open-source implementations; frameworks, libraries, or infrastructure repositories; or historical implementations and decisions. Consider both internal and external sources when both add value.
4. **Assess exploration value:** Would repository evidence reduce uncertainty, prevent duplication, reveal constraints, supply proven patterns, expose risks, or increase confidence?
5. **Decide:** Use Repos when repository inspection is a meaningful part of solving the task. Otherwise answer directly.

## 3. User-intent taxonomy and selection examples

The following taxonomy covers the main intents. “Usually” indicates that context matters: select Repos when the request depends on an existing system or real implementation evidence, not merely because the topic is technical.

| Intent | Select Repos when the user wants to… | Usually do not select when the user only wants… |
|---|---|---|
| **A. Understand existing implementations** | Explain how authentication, payments, database connections, request lifecycles, workers, notifications, caching, form submission, or dependency injection work *in a particular system*. | A general explanation of dependency injection, REST vs GraphQL, or another concept. |
| **B. Find existing solutions and reusable code** | Locate an existing retry mechanism, email validator, pagination utility, upload component, rate limiter, circuit breaker, authentication module, distributed lock, or reusable library. | Generic standalone code such as writing a retry mechanism or basic pagination from scratch. |
| **C. Debug and troubleshoot** | Trace failing middleware, connection leaks, API timeouts, duplicate jobs, memory leaks, inconsistent endpoint results, startup crashes, or race conditions in a codebase. | Definitions such as segmentation faults, HTTP 502, or general causes of memory leaks without a system-specific investigation. |
| **D. Discover and analyze architecture** | Analyze an application's architecture, service responsibilities, module dependencies, service boundaries, bottlenecks, or real event-driven, microservice, or hexagonal implementations. | A hypothetical architecture design or a conceptual explanation/comparison of architecture styles. |
| **E. Research implementation patterns** | Find and compare real implementations of retries, repository patterns, idempotent APIs, feature flags, transactional outboxes, distributed caching, WebSocket reconnection, or authentication. | General descriptions of design patterns such as Observer. |
| **F. Assess code quality and engineering standards** | Review code quality; find duplication, complexity, convention violations, inconsistent error handling, code smells, or deviations from design principles. | General definitions such as SOLID or maintainability principles. |
| **G. Investigate testing and QA** | Find tests, integration/E2E patterns, mocks, fixtures, regression tests, flaky tests, coverage gaps, and project-specific testing practices. | Generic explanations of test types or standalone sample tests. |
| **H. Investigate performance and scalability** | Find bottlenecks, slow queries, inefficient algorithms, unnecessary network calls, caching behavior, connection pooling, batch-processing patterns, or memory-allocation issues. | General Big-O explanations or generic optimization advice not tied to implementation evidence. |
| **I. Examine security and reliability** | Audit authentication/authorization, secrets, input validation, sensitive logging, access control, token rotation, timeouts, retries, and failure handling in code or reference projects. | General security definitions or vulnerability overviews without repository-specific evidence. |
| **J. Understand dependencies and integrations** | Trace Stripe, Redis, Kafka, OAuth, SDK, or library integrations; identify modules using a dependency; or study how other projects integrate a service. | General explanations of Redis or OAuth. |
| **K. Inspect configuration, infrastructure, and deployment** | Find Docker/Kubernetes/Terraform configuration, CI/CD pipelines, environment differences, infrastructure dependencies, deployment failures, or real blue-green deployment implementations. | General explanations of Docker or Kubernetes. |
| **L. Plan migration and modernization** | Find deprecated API use, legacy-system consumers, dependency-upgrade impact, database migration touchpoints, runtime compatibility, or real migration implementations. | General explanations of migration patterns or their benefits. |
| **M. Extend an existing system** | Add an endpoint, notification, authentication provider, payment workflow, or module in line with existing architecture and conventions. | Create a standalone script, generic REST example, or independent UI component with no project constraints. |
| **N. Extract documented engineering knowledge** | Find architecture docs, API specs, ADRs, design rationale, undocumented modules, or a system overview. | Explain what an ADR is or write generic function documentation. |
| **O. Investigate history and engineering decisions** | Find prior implementations, when behavior was introduced, the commit behind a regression, previous attempts, or documented reasons for architectural/dependency choices. | General Git or semantic-versioning explanations. |
| **P. Evaluate technologies through real projects** | Compare caching, queues, database-access patterns, authentication architectures, API designs, or framework implementations across repositories. | A general technology-choice question or feature comparison that does not require implementation evidence. |
| **Q. Solve problems and validate proposals** | Check whether a solution already exists; validate an approach against mature implementations; discover edge cases; assess architectural consistency/refactoring risks; or find an existing library. | Pure mathematical correctness or a generic explanation of trade-offs without implementation evidence. |
| **R. Find the best and avoid the bad** | Discover candidates, filter weak ones, assess repository maturity and quality, compare trade-offs, identify best-fit implementations, and find anti-patterns or engineering mistakes. | A request for a single example where no evaluation or repository evidence is needed. |

### Cross-cutting selection signals

Strong signals for Repos include references to **our code/application/system**, “find,” “locate,” “trace,” or “inspect” code, “how is this implemented?”, “why is this failing?”, “existing,” “reusable,” “already implemented,” “similar projects,” “real-world examples,” “best implementation patterns,” “architecture analysis,” “root cause,” or modifying/refactoring an existing system.

Weak or negative signals include “from scratch,” “standalone,” definitions, language syntax, generic snippets, standard-library explanations, pure mathematics/algorithm questions, or purely hypothetical designs. These are not absolute rules: use Repos if the task still depends on real implementation evidence.

### Internal vs external repository research

- **Internal repository discovery** is for questions dependent on the user's engineering environment: understanding functionality, debugging, reusing internal components, discovering dependencies, preserving architecture, implementing features, finding regressions, or recovering historical decisions.
- **External repository discovery** is for learning from other projects: reference implementations, mature solutions, open-source practices, production-grade strategies, library/framework evaluation, and complex engineering techniques.
- Use both when internal context defines the constraints and external projects offer useful alternatives or benchmarks.

## 4. When not to select Repos

Avoid unnecessary exploration when the user requests a straightforward conceptual explanation; asks for generic standalone code; asks about language syntax or standard-library usage; poses a purely mathematical or algorithmic question; requests a hypothetical design with no need for real-world evidence; or when repository inspection would not materially improve the answer.

Examples: “Explain async/await,” “Write a Python function to reverse a string,” “What is dependency injection?”, “Explain the CAP theorem,” “Implement binary search in Java,” and “Design a hypothetical URL shortener” generally do not need Repos. “Find how URL shorteners handle distributed ID generation” and “Investigate why our URL shortener generates duplicate IDs” do.

### Ordered selection rules

1. **Existing-system dependency:** If the task requires understanding, modifying, debugging, or extending an existing system, select Repos.
2. **Existing-solution discovery:** If the user wants to find, reuse, compare, or learn from existing implementations, select Repos.
3. **Engineering investigation:** For root-cause, architecture, dependency, performance, or code-quality investigations, select Repos.
4. **Implementation research:** Select it when real-world examples, mature implementations, or proven patterns materially help.
5. **Generic knowledge:** Do not select it when general engineering knowledge is sufficient.
6. **Generic implementation:** Generate standalone code directly unless existing patterns, dependencies, or constraints matter.
7. **Uncertainty:** Ask whether repository evidence could materially change the answer. If yes, use Repos; if not, answer directly.

## 5. Repository research workflow: premise, evidence, intervention

When repository research is relevant, do not stop after finding an implementation:

1. **Outcome and premise:** separate what is needed from what is proposed; name the assumption to test.
2. **Current system:** trace the real execution path, installed capabilities, configuration, and history before adding a layer.
3. **Abstract the problem:** invariants (interruption, concurrency, boundaries, partial failure), resources, failure classes, workload.
4. **Discover** internal code, mature OSS, adjacent domains, specs, and research as relevant.
5. **Disqualify fast:** reject candidates with a fundamental mismatch (unknown vs assumed costs, overlapping vs disjoint categories, wrong edition, hidden global state, missing recovery/export guarantees) before full review.
6. **Inspect the mechanism:** exact version, source path, callers, helpers, initialization, tests, regression fixes, build flags, platform/concurrency/arithmetic assumptions, published artifact vs inspected source. Depth scales with how much you import; studying an idea needs less provenance/licensing work than copying code.
7. **Test transferability** with evidence that could change the decision: compare against an exact reference, follow one real consumer, run a representative integration case, include inputs that violate the candidate's assumptions. Seek counterevidence: what would show this is wrong for us?
8. **Compare ownership:** responsibilities removed, introduced, transferred, retained (dependencies, services, state, deployment, monitoring, recovery, migration, upstream/fork, exit cost).
9. **Choose the intervention:** configure, delete, reuse, adopt, extract, port, borrow a design, or build.
10. **Implement and validate** the actual outcome; retire code, workarounds, state, or services the choice made obsolete.

Evidence levels: search result/README = candidate exists; source + tests + regression history = implements the mechanism; experiment under the user's conditions = it transfers. Never present the first as the last.

For a substantial subsystem, keep a short prior-art ledger in the project's existing doc conventions: *inspected (source@revision) · borrowed · rejected and why · residual risk*. For small fixes, a line of notes suffices.

### Evaluation criteria

Prioritize criteria according to the problem, constraints, and risk profile; not every criterion has equal importance in every task.

- **Relevance:** Same or sufficiently similar problem, requirements, language, framework, platform, and deployment environment?
- **Correctness:** Sound logic; edge cases handled; invariants preserved; tests and code support claimed behavior; limitations understood?
- **Architecture:** Clear boundaries, responsibilities, dependencies, interfaces, and module design; controlled coupling; justified abstractions?
- **Maintainability:** Understandable, modular, consistent code; proportionate complexity; safe evolution without widespread unintended effects?
- **Reliability:** Appropriate failure handling, retries, timeouts, concurrency controls, resource cleanup, and tests for failure modes?
- **Security:** Sound trust boundaries, input validation, secrets handling, authentication, authorization, dependencies, and exposed interfaces?
- **Performance:** Suitable computational/resource characteristics, no avoidable bottlenecks, expected workload scalability, and evidence for performance claims?
- **Testing:** Meaningful, deterministic, maintainable tests for key behavior, edge cases, and failure paths?
- **Documentation:** Decisions, constraints, actual behavior, setup, configuration, and operational requirements explained accurately?
- **Maturity:** Evidence of maintenance, real usage, releases, issue resolution, and compatibility work; distinguish experimental, abandoned, and rapidly changing projects?
- **Complexity:** Is the solution appropriately simple, or does it add unjustified abstractions, dependencies, or infrastructure?
- **Ownership burden:** What responsibility does choosing it remove, introduce, transfer, or retain? A technically excellent platform can lose to a small library on this alone.
- **Transferability:** Do its assumptions (workload, costs, data model, edition, platform) hold under the user's real conditions?
- **Extensibility:** Are extension points intentional and useful, without imposing unjustified complexity?
- **Compatibility:** Does it fit target language/runtime/framework/dependencies/environment, and can useful ideas be adapted without importing incompatible assumptions?

### Evaluation discipline

- Do not treat stars, popularity, downloads, or activity alone as proof of quality; a large codebase is not inherently mature or reliable.
- Do not assume production readiness because a repository claims it.
- Distinguish verified findings from assumptions and inferences.
- Treat missing tests or documentation as an observed limitation only after checking relevant contents.
- Consider implementation date and context; a once-strong solution may no longer be appropriate.
- Evaluate candidates against the user's actual requirements, not an abstract universal ranking.
- Do not label code bad based on style preference alone. Distinguish objective defects, contextual trade-offs, and subjective preferences.

## 6. Actively find bad engineering

The agent must investigate weaknesses, not merely collect positive examples. Look for:

- Anti-patterns and architectural smells; excessive abstraction and overengineering.
- Tight coupling, poor separation of concerns, duplicated or unnecessarily complex logic.
- Incorrect or inconsistent error handling; missing edge cases; mishandled invariants.
- Race conditions, concurrency defects, partial-failure and recovery gaps.
- Inadequate or misleading tests; security vulnerabilities and unsafe defaults.
- Performance bottlenecks, resource leaks, and unnecessary dependencies.
- Poor API/interface design and inconsistent coding conventions.
- Abandoned, incompatible, or unmaintained implementations.
- Solutions that work only under unrealistic assumptions.
- Hidden assumptions not enforced by code or tests.
- Complexity that delivers no meaningful value.

For each weakness, determine: **what** is wrong; **what evidence** demonstrates it; **when** it matters; **what consequences** it may cause; whether it is a project-specific trade-off or generally harmful; what alternative is better; and what lesson applies to the target problem.

The goal is not merely to find examples to copy. It is to understand what makes an implementation good, what makes it bad, and why.

## 7. Expected research output

For a substantial comparative evaluation, cover:

1. **Best candidates:** strongest relevant repositories/implementations and why they fit.
2. **Evaluation:** strengths, weaknesses, evidence, maturity, compatibility, and suitability limitations.
3. **Comparative insights:** differences, trade-offs, and which decisions work best under which conditions.
4. **Best practices:** reusable patterns, sound engineering decisions, invariants, edge cases, and testing/reliability/security/operational practices.
5. **Anti-patterns:** mistakes and weaknesses to avoid, why they are problematic, and when they become harmful.
6. **Recommendation:** the best-fit approach for the actual problem, why it beats alternatives, and remaining constraints/trade-offs.
7. **Adaptation strategy:** what to reuse, redesign, or avoid, and how to validate the result.

Scale output to the task: simple question → answer + source; investigation → findings, evidence, recommendation; significant subsystem → ledger, comparison, ownership, risks, validation; external code adoption → add provenance, license, integration, verification. Compare when it materially affects the decision; if evidence cannot separate candidates, say so. Always distinguish verified findings from assumptions.

## 8. Consolidated agent instruction

**Repos — Engineering Discovery, Research & Intelligence**

Use Repos when a user request would benefit from discovering, understanding, investigating, comparing, evaluating, validating, or reusing existing software implementations and engineering knowledge.

Think and operate like a senior software architect. Before developing a solution, determine whether existing repositories contain relevant implementations, architectural decisions, proven patterns, engineering insights, or lessons from previous attempts. Identify whether internal code, external projects, or both are needed.

Do not stop at finding implementations. Discover relevant candidates; filter unsuitable ones; evaluate correctness, architecture, security, reliability, performance, maintainability, testing, maturity, compatibility, and complexity; compare alternatives and trade-offs; identify the strongest approaches and the mistakes to avoid; extract reusable engineering principles rather than blindly copying project-specific code; recommend the best fit for the actual constraints; and validate the resulting approach.

Use Repos for existing-system understanding, reusable-code discovery, debugging, architecture and dependency analysis, implementation research, code-quality and testing reviews, performance/security/reliability investigations, integrations and infrastructure, migration, feature extension, documentation/history discovery, comparative research, solution validation, and finding the best implementations while avoiding bad ones.

Do not use Repos by default for straightforward conceptual explanations, generic standalone code, syntax questions, pure mathematical problems, or hypothetical tasks where repository evidence would not materially improve the answer.

**Critical principle:** Do not search merely to find an implementation to copy. Search to discover, evaluate, compare, and understand engineering solutions. Prefer evidence of correctness, reliability, maintainability, security, and suitability over popularity or superficial similarity. Actively look for both what should be adopted and what should be avoided.

**Ultimate objective:** Deliver the requested outcome with the least unnecessary complexity and long-term responsibility, by learning from existing software rather than reinventing solutions or repeating known mistakes.

---

# Verbatim preservation of the research and evaluation additions

The following original sections are retained verbatim to preserve their distinctive variants, formulations, criteria, and examples. The consolidated sections above provide the shorter operational structure; where they differ, §§1–8 govern.

9. Repository research, evaluation & selection

The objective is not to find an implementation. It is to find the most relevant, reliable, maintainable, and appropriate implementation for the problem, while identifying approaches that should be avoided.

A senior architect does not look at repositories and blindly copy the first implementation. They investigate, compare, challenge assumptions, assess maturity, and extract the best engineering decisions.

Senior architect research workflow

1. Discover

Find repositories implementing the relevant functionality, solving similar problems, or using comparable architectural approaches.

2. Filter

Eliminate irrelevant, incomplete, outdated, abandoned, experimental, or unsuitable repositories.

3. Evaluate

Inspect architecture, implementation quality, correctness, maintainability, testing, performance, security, and reliability.

4. Compare

Compare alternative implementations, identify trade-offs, and understand why different projects made different decisions.

5. Identify the best

Select the strongest approaches based on the actual problem, not popularity or superficial similarity.

6. Identify the bad

Find anti-patterns, architectural weaknesses, implementation mistakes, hidden risks, and approaches that should not be replicated.

7. Extract insights

Separate reusable principles from project-specific implementation details.

8. Apply

Adapt the best findings to the target engineering problem, respecting its constraints and architecture.

9. Validate

Check that the proposed solution addresses the identified weaknesses and preserves the useful properties of the selected implementations.


10. Repository research, evaluation & selection — user-intent taxonomy

A. Finding the best implementations

Intent: Identify high-quality, mature, relevant implementations that can serve as references or starting points.

User intent | Use Repos?

"Find the best repositories implementing distributed caching." | Yes

"Identify the most mature implementations of event sourcing." | Yes

"Find the most reliable implementation of a retry mechanism." | Yes

"Find repositories with production-ready implementations." | Yes

"Which projects have the best testing strategies?" | Yes

"Find the strongest reference implementation of this protocol." | Yes

"Which implementation is most suitable for our requirements?" | Yes

"What makes a good software architecture?" | No, unless real implementations are requested


B. Comparing repository quality

Intent: Evaluate competing repositories or implementations and determine their relative strengths and weaknesses.

User intent | Use Repos?

"Compare the quality of these five repositories." | Yes

"Which implementation follows the best architectural practices?" | Yes

"Compare different approaches to database connection pooling." | Yes

"Compare implementation complexity across these projects." | Yes

"Which project has the best balance of simplicity and extensibility?" | Yes

"Compare how different projects handle errors and retries." | Yes

"Which repository is the best reference for our use case?" | Yes


C. Finding bad implementations and engineering mistakes

Intent: Identify poor engineering decisions, recurring mistakes, and approaches that should be avoided.

User intent | Use Repos?

"Identify poorly designed implementations of authentication." | Yes

"Find common mistakes in open-source payment integrations." | Yes

"Identify architectural anti-patterns across similar projects." | Yes

"Find examples of overengineered solutions." | Yes

"What mistakes should we avoid when implementing a message queue?" | Yes

"Find security weaknesses in reference implementations." | Yes

"Identify projects with unnecessary complexity." | Yes

"Explain common software anti-patterns." | No, unless real repository examples are requested


D. Repository maturity and maintenance assessment

Intent: Determine whether a repository is sufficiently mature, maintained, complete, and suitable to rely on.

User intent | Use Repos?

"Identify abandoned or poorly maintained projects." | Yes

"Evaluate whether this repository is mature enough for production use." | Yes

"Check whether this project is actively maintained." | Yes

"Find repositories with incomplete or experimental implementations." | Yes

"Assess whether this project is safe to use as an architectural reference." | Yes

"Determine whether this implementation is compatible with our stack." | Yes


E. Extracting best practices and anti-patterns

Intent: Learn from successful and unsuccessful engineering decisions across repositories.

User intent | Use Repos?

"Extract best practices from mature implementations." | Yes

"Identify patterns worth adopting from these projects." | Yes

"Find implementation approaches we should avoid." | Yes

"Identify common weaknesses across implementations of this feature." | Yes

"Find examples of robust edge-case handling." | Yes

"Determine how mature projects preserve important invariants." | Yes

"Identify recurring design mistakes in similar systems." | Yes


11. Repository evaluation criteria

Evaluate candidate repositories across multiple dimensions. The criteria are not equally important for every task; prioritize them according to the problem, constraints, and risk profile.

Relevance
- Does the repository solve the same problem or a sufficiently similar one?
- Does it operate under comparable requirements and constraints?
- Is it relevant to the target language, framework, platform, and deployment environment?

Correctness
- Is the implementation logically and technically sound?
- Are important edge cases handled?
- Are invariants identified and preserved?
- Do tests and code support the claimed behavior?
- Are there known correctness limitations?

Architecture
- Are boundaries, responsibilities, and dependencies well designed?
- Is coupling controlled?
- Are abstractions justified?
- Are interfaces and module boundaries coherent?
- Does the architecture fit the actual problem rather than introduce unnecessary complexity?

Maintainability
- Is the code understandable, modular, and easy to evolve?
- Are naming, structure, and conventions consistent?
- Can changes be made without widespread unintended effects?
- Is complexity proportionate to the requirements?

Reliability
- Does the implementation handle failures, retries, timeouts, and unexpected inputs?
- Are concurrency and race conditions considered?
- Are resources cleaned up correctly?
- Are important failure modes tested?

Security
- Does the implementation follow appropriate security practices?
- Are trust boundaries and input validation handled?
- Are secrets and sensitive data protected?
- Are authentication and authorization applied correctly?
- Are dependencies and exposed interfaces considered?

Performance
- Does the implementation have appropriate computational and resource characteristics?
- Are there avoidable bottlenecks?
- Does it scale under the expected workload?
- Are performance claims supported by benchmarks or evidence where relevant?

Testing
- Are there meaningful tests covering important behaviors?
- Do tests cover edge cases and failure paths?
- Are tests deterministic and maintainable?
- Is the test strategy appropriate to the implementation?

Documentation
- Are implementation decisions and constraints understandable?
- Does documentation match actual behavior?
- Are setup, configuration, and operational requirements explained?

Maturity
- Is the project established, maintained, and sufficiently complete?
- Is there evidence of real usage, releases, issue resolution, and compatibility maintenance?
- Is it experimental, abandoned, or still changing rapidly?

Complexity
- Is the solution appropriately simple for the problem?
- Does it introduce unnecessary abstractions, dependencies, or infrastructure?
- Is the complexity justified by concrete requirements?

Extensibility
- Can it accommodate likely future requirements without excessive changes?
- Are extension points intentional and understandable?
- Does extensibility come at an unjustified cost to simplicity?

Compatibility
- Does it fit the target language, framework, runtime, dependencies, and environment?
- Are version constraints and platform assumptions clear?
- Can the useful ideas be adapted without importing incompatible design decisions?

Evaluation discipline

- Do not treat stars, popularity, downloads, or activity alone as proof of implementation quality.
- Do not treat a large codebase as inherently more mature or reliable.
- Do not assume that a repository is production-ready because it describes itself that way.
- Distinguish verified findings from assumptions and inferences.
- Treat missing tests or documentation as an observed limitation only after checking the relevant repository contents.
- Consider the date and context of the implementation; an otherwise strong solution may no longer be appropriate.
- Evaluate candidates against the user's actual requirements, not an abstract universal ranking.


12. Explicitly search for bad engineering

The agent should actively investigate weaknesses rather than only collecting positive examples.

Look for:

- Anti-patterns and architectural smells.
- Excessive abstraction and overengineering.
- Tight coupling and poor separation of concerns.
- Duplicated or unnecessarily complex logic.
- Incorrect or inconsistent error handling.
- Missing edge-case handling.
- Race conditions and concurrency problems.
- Inadequate or misleading tests.
- Security vulnerabilities and unsafe defaults.
- Performance bottlenecks and resource leaks.
- Unnecessary dependencies.
- Poor API and interface design.
- Inconsistent coding conventions.
- Abandoned, incompatible, or unmaintained implementations.
- Solutions that work only under unrealistic assumptions.
- Incorrect handling of invariants.
- Hidden assumptions that are not enforced by code or tests.
- Failure to handle partial failures and recovery.
- Complexity that does not deliver meaningful value.

The goal is not merely to find examples to copy. It is to understand what makes an implementation good, what makes it bad, and why.

When a weakness is found, determine:
- What exactly is wrong?
- What evidence demonstrates the weakness?
- Under what conditions does it matter?
- What consequences could it cause?
- Is it a project-specific trade-off or a generally harmful practice?
- What alternative would be better?
- What lesson should be applied to the target problem?

Do not label an implementation as bad based on style preference alone. Distinguish objective defects, contextual trade-offs, and subjective preferences.


13. Expected output from repository research

When repository evaluation is relevant, aim to produce:

1. Best candidates
   - The strongest repositories or implementations discovered.
   - Why each is relevant to the problem.

2. Evaluation
   - Strengths and weaknesses of each candidate.
   - Evidence supporting important judgments.
   - Maturity, compatibility, and suitability limitations.

3. Comparative insights
   - How implementations differ.
   - What trade-offs they introduce.
   - Which decisions appear most effective and under what conditions.

4. Best practices
   - Patterns and engineering decisions worth reusing.
   - Invariants and edge cases handled well.
   - Testing, reliability, security, and operational practices worth adopting.

5. Anti-patterns
   - Mistakes, weaknesses, and approaches to avoid.
   - Why they are problematic.
   - The conditions in which they become harmful.

6. Recommendation
   - Which approach best addresses the actual problem.
   - Why it is preferable to the alternatives.
   - Which constraints or trade-offs remain.

7. Adaptation strategy
   - How to apply the findings to the target system.
   - What to reuse, what to redesign, and what not to copy.
   - How to validate the resulting implementation.

The agent must distinguish verified findings from assumptions. Do not claim that a repository is the best without comparing it against relevant alternatives and explaining the criteria used. If the available evidence is insufficient to identify a clear winner, say so.


14. Updated agent instruction — research, evaluate, find the best, avoid the bad

Repos — Engineering Discovery, Research & Intelligence

Use Repos when a user request would benefit from discovering, understanding, investigating, comparing, evaluating, validating, or reusing existing software implementations and engineering knowledge.

Think and operate like a senior software architect.

Before developing a solution, determine whether existing repositories contain relevant implementations, architectural decisions, proven patterns, engineering insights, or lessons from previous attempts.

Do not stop at finding implementations. When repository research is relevant, evaluate the quality and suitability of the available candidates.

Research objectives:

1. Discover relevant implementations and reference projects.
2. Filter out irrelevant, incomplete, outdated, abandoned, experimental, or unsuitable candidates.
3. Evaluate technical quality, correctness, architecture, security, reliability, performance, maintainability, testing, and complexity.
4. Compare alternative implementations and understand their trade-offs.
5. Identify the strongest approaches and engineering decisions worth adopting.
6. Identify anti-patterns, mistakes, weaknesses, and approaches that should be avoided.
7. Extract reusable engineering principles rather than blindly copying project-specific code.
8. Recommend the most appropriate approach for the actual problem and its constraints.
9. Validate that the proposed solution preserves useful properties and addresses identified weaknesses.

Use Repos when the user wants to:
- Understand how existing software works.
- Discover or reuse existing implementations.
- Investigate bugs, failures, or architectural problems.
- Research how other projects solve engineering challenges.
- Find the best implementations or reference projects.
- Compare technical approaches and architectural decisions.
- Evaluate repository quality, maturity, and suitability.
- Identify best practices, anti-patterns, and engineering mistakes.
- Improve, extend, refactor, or validate an existing system.
- Learn from successful and unsuccessful engineering approaches.

Do not use Repos by default when:
- The user requests a straightforward conceptual explanation.
- The user wants generic standalone code.
- The problem can be solved reliably using general engineering knowledge.
- Repository evidence would not materially improve the answer.

Critical principle:

Do not search merely to find an implementation to copy. Search to discover, evaluate, compare, and understand engineering solutions.

Prefer evidence of correctness, reliability, maintainability, security, and suitability over popularity or superficial similarity.

Actively look for both what should be adopted and what should be avoided.

The ultimate objective is to produce better engineering decisions by learning from existing software rather than reinventing solutions or repeating known mistakes.
