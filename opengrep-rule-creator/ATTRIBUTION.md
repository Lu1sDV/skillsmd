# Attribution and licensing

## Adapted authoring workflow

This skill adapts Trail of Bits' **Semgrep Rule Creator**, by Trail of Bits and contributors, licensed under **Creative Commons Attribution-ShareAlike 4.0 International**. The adapted skill and original material added in this directory are distributed under the same license; see [LICENSE](LICENSE). Upstream snapshots retain their own notices and terms below. No endorsement by Trail of Bits, Semgrep, or OpenGrep is implied.

Upstream revision: `82fe8226252622fa807643bdca1710901198553a`, retrieved 2026-10-03.

- [Marketplace entry requested by the user](https://www.skills.sh/trailofbits/skills/semgrep-rule-creator)
- [Original skill](https://github.com/trailofbits/skills/blob/82fe8226252622fa807643bdca1710901198553a/plugins/semgrep-rule-creator/skills/semgrep-rule-creator/SKILL.md)
- [Original workflow](https://github.com/trailofbits/skills/blob/82fe8226252622fa807643bdca1710901198553a/plugins/semgrep-rule-creator/skills/semgrep-rule-creator/references/workflow.md)
- [Original quick reference](https://github.com/trailofbits/skills/blob/82fe8226252622fa807643bdca1710901198553a/plugins/semgrep-rule-creator/skills/semgrep-rule-creator/references/quick-reference.md)
- [Upstream license](https://github.com/trailofbits/skills/blob/82fe8226252622fa807643bdca1710901198553a/LICENSE)

Changes: OpenGrep-first commands and version-specific compatibility guidance; local documentation instead of mandatory web fetching; topic-based progressive disclosure instead of loading seven documents unconditionally; four complex commented examples with one rule per YAML; generic token matching allowed for unsupported text formats; explicit engine-mode verification; no assumption that a modelled sanitizer is safe for every sink. The upstream test-first, AST inspection, positive/negative cases, simplify-after-correctness, and final-real-scan workflow is retained. Added publication gates (2 TP + 2 TN, syntax validation, calibrated confidence, WHAT/WHY/HOW messages, structural primary matching), performance/precision guidance, and an explicit record of policy refinements.

## Vendored references

- Semgrep documentation: [local inventory and provenance](references/semgrep/INDEX.md). These are upstream Semgrep documents, not OpenGrep documentation or promises of OpenGrep feature support. Consult [compatibility](references/compatibility.md) before adopting a feature.
- OpenGrep wiki and repository documentation: [local inventory and provenance](references/opengrep/INDEX.md). Source-specific notices accompany these snapshots; do not infer that a repository license automatically covers a separately published wiki.

The root CC BY-SA license does not relicense third-party reference snapshots. Preserve their source URLs, authorship, provenance manifests, and license notices when redistributing.
