# ui-taste

Anti-ui-slop workflow for web and iOS interfaces: research real products, fix a visual target
before coding, build it with semantic components, then prove the result with captures instead of
claims.

## Credits

This is an **unmodified vendored copy** of the `ui-taste` skill by **[Uizze](https://uizze.com)**
(`UIZZE <business@uizze.com>`), version `0.3.0`, manifest `uizze-design-v14`.

- Source: <https://www.skills.sh/site/uizze.sh/ui-taste> (files from `https://uizze.sh/.well-known/skills/ui-taste/`)
- Upstream install: `npx skills add https://uizze.sh/`
- All 26 files match the upstream `CHECKSUMS.sha256` (verified with `sha256sum -c`).
- Not an endorsement by Uizze or by the authors below.

Uizze's package is itself derived from other work. Their notices are kept in `LICENSE`, `NOTICE`
and `MODIFICATIONS.md`; do not remove them:

| Work | Author | License |
|------|--------|---------|
| [Impeccable](https://github.com/pbakaus/impeccable) v4.6.0 — creation, craft, polish, audit, Overdrive playbooks | Paul Bakaus | Apache-2.0 |
| [platform-design-skills](https://github.com/ehmo/platform-design-skills) — iOS / Apple HIG material | ehmo | MIT |
| [appllama-skills](https://github.com/Appllama/appllama-skills) — research, navigation/anti-slop/motion, mobile controls | Antmind Ventures (appllama.io) | MIT |

The image-first → 1:1 workflow, reference policy and visual-evidence receipt are Uizze-authored.

## Install locally

```bash
cp -r ui-taste ~/.claude/skills/
```

## How it works (one pass)

1. **Work from the product** — read brief, components, tokens, `PRODUCT.md`/`DESIGN.md`; classify
   authority as preserve / expand / replace / create.
2. **Research** (`reference/research.md`) — find and inspect real screens/flows, write a checkable spec.
3. **Pick the playbook** — new-work, operate, polish, distill, audit (web), audit.native, ios, overdrive.
4. **Image first** (`references/uizze-image-to-ui.md`) — supplied target > generated target > none (disclose).
5. **Build 1:1** — semantic text and real controls, never a screenshot background; craft checks
   (`reference/craft.md`, `reference/anti-slop-craft.md`).
6. **Render, compare, correct** — same-size capture, side-by-side, fix layout → type → spacing → color.
7. **Receipt** (`references/uizze-visual-verification.md`) — `visual-evidence.json` plus
   `node scripts/verify-visual-evidence.mjs <receipt>` for file-integrity checking.

## Optional paid MCP

`find_ui_references`, `get_ui_flow` and `find_ui_materials` need Uizze's paid MCP. The skill is
fully usable without it; missing access is disclosed, never blocking.

## License

Apache-2.0 (see `LICENSE`), with the MIT notices in `NOTICE`.
