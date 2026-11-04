# Changelog

## 2.0.0 — 2026-11-04

- Reconstructed complete dual-skill source/installer package from agreed specification and attached original skill; previous scratch tree not accessible in this session.
- Replaced nonmonotonic first-match allocation with a monotonic envelope and minimum two domain passes for changes of 2,000+ lines.
- Added one additional **targeted independent risk reviewer** for verified high-risk changes at every depth; DEEP/ULTRA holistic pass remains distinct.
- Introduced canonical `src/shared` policy with deterministic skill compiler and drift check.
- Added pinned published-version snapshot, CLI preflight, CI matrix generation, pinned package/path smoke workflow, and compatibility tests.
- Recreated install/upgrade adapters for Pi, OMP, Codex and Claude Code with dry-run, recorded ownership, conflict detection and backups.
