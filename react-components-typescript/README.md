# react-components-typescript

React component design and TypeScript guidance built only from community-backed
sources: composition, props patterns, keys and identity, conditional rendering,
purity, error boundaries, controlled vs uncontrolled components, exports, and
TypeScript with React. Baseline: React 19.3, `@types/react` 19, TypeScript 5.x.
Self-contained: no sibling skill is required.

## Install

From the skillsmd checkout (preserve local changes before replacing an existing
installation):

```sh
mkdir -p ~/.claude/skills
cp -r react-components-typescript ~/.claude/skills/
```

## Usage

- “This list loses input focus and state when I add items. Review its keys.”
- “`{items.length && <List/>}` prints 0. What is the documented fix?”
- “Is it OK to define this render helper component inside the parent?”
- “Type this generic `Select` component and its `onChange` handler; should it use `React.FC`?”
- “Model a Button that is either a link or an action without invalid prop combinations.”

## Reference index

| File | Scope |
|---|---|
| [SKILL.md](SKILL.md) | Trigger, routing, workflow, high-risk rules, skill myths, handoffs |
| [Composition and props](references/composition-props.md) | Prop drilling, `children`, splitting, variants/booleans, controlled vs uncontrolled, prop-to-state, hooks extraction, exports, classes |
| [Identity and rendering](references/identity-rendering.md) | Keys, state reset, nested definitions, `&&`, purity, error boundaries |
| [TypeScript with React](references/typescript-react.md) | Props typing, `interface`/`type`, children, `React.FC`, events, hooks, React 19 type changes, `any` |

## Sources and decisions

Evidence basis: a claim-by-claim audit of agent-skill guidance against
community sources (cluster ids V3-1 to V3-38), followed by an independent
verification of every supported cluster, both on 2026-11-07. Official docs, the
React team, library maintainers, respected engineers and company engineering
blogs count as community sources; a claim found only in other AI skills does
not. Every normative rule in `references/` has a source URL taken from that
evidence. Quotes are verbatim from the evidence files.

### Correction decisions (verifier corrections override the audit)

- **Mutation in render (V3-38):** "no mutation" is too broad; only changing
  pre-existing values is forbidden, local mutation is fine.
- **`interface` vs `type` (V3-29):** Pocock's props article says "In general, you
  should use `interface`" and to use interfaces when extending types; his
  later article defaults to `type`; react.dev is neutral. Presented as
  contested, not as a rule.
- **Boolean props (V3-23):** Shevlin explicitly argues several booleans for one
  concern are a smell, as opinion; remedy is an enumerated `variant`.
  Single booleans are idiomatic; no numeric threshold has a source.
- **Single responsibility (V3-24):** hedged ("ideally"); premature extraction is a
  documented opposite trap (Makarevich).
- **Render props (V3-22):** sourced only from archived pre-Hooks docs.
- **Custom hooks (V3-26):** scoped to Effect/external-system logic and real
  duplication; async Server Components await data directly.
- **Discriminated props (V3-32):** sourced by the React TypeScript Cheatsheet;
  applies to genuinely exclusive shapes.
- **Error boundaries (V3-21):** added boundary-itself, SSR, `startTransition`
  and `use()` cases from the verified Component page.

### Skill myths (listed in SKILL.md)

Prop drilling max 2 levels (V3-1), functional components only (V3-2), ternary
instead of `&&` (V3-3), boundaries required per route (V3-4), inline props only
(V3-5), named exports only (V3-6), never `import React` (V3-7),
container/presentational dogma (V3-8). The Abramov retraction was independently
read in full on the fetched Medium page (Mar 2015 article, 2019 update).

### Excluded claims (no community source; not presented as consensus)

Barrel exports in component folders (V3-9), 200-line component limit (V3-10),
compound components with a `{state, actions, meta}` provider (V3-11), mandatory
loading/empty/error states (V3-12), early returns (V3-13; react.dev documents
them as a style choice, see the identity reference), React Hook Form
specifics beyond `field.id`/`key` as key (V3-14), shadcn/ui composition rules (V3-15),
framework- or codegen-specific project conventions (V3-16), strict mode / banned
`!` as React guidance (V3-17), avoid enums (V3-18), wrapper components preserving
native behavior (V3-19). Where an agent would otherwise guess, a single line is
labeled "project policy, not consensus" (root-level plus route-level error
boundaries; `strict: true`; named-import enforcement). File-layout guidance is
limited to the lightly supported items cited in the reference.

### Fact-check log

- 2026-11-07 source-support fact-check: 16 issues fixed (9 miscited, 5
  overstated, 2 unconfirmed): dead/misattached URLs, React Hook Form v8 key
  gate, `startTransition` boundary scope, one-sided `interface` advice, an
  unkeyed list example, and two unsourced rules marked as inference/reworded.

### Evidence gaps

- The `FunctionComponent` type definition was fetched from DefinitelyTyped
  `master`; recheck when `@types/react` changes.
- Next.js `error.tsx` conventions and RHF `useWatch`/`useController` details were
  not verified.
- The audit read react.dev pages partially (the TypeScript page only to the
  first sections); anchors for hook typing come from the verified evidence
  entries, not a full re-read.
