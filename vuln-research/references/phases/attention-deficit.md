# Attention Deficit Mapping

> **Load when**: Load after Crown Jewel mapping when you need to prioritize parallel-agent fan-out by bug-probability signal rather than impact. Use when deciding which modules deserve dedicated agents vs. a lighter pass.

After identifying crown jewels, identify the **least-examined** code — where bugs survive because nobody looked, not because the code is sound:

| Signal | High Attention (lower bug probability) | Low Attention (higher bug probability) |
|--------|---------------------------------------|---------------------------------------|
| **Security commits** | Has `fix: security`, CVE references, audit comments | No security-related commits in history |
| **Fuzzing/testing** | Fuzz targets exist, high test coverage | No fuzz corpus, low/no test coverage |
| **Code glamour** | Auth module, crypto, payment processing | Parser, format handler, protocol adapter, config loader, migration script |
| **External exposure** | Behind auth wall, internal-only | Processes attacker-controlled input (uploads, webhooks, public API) |
| **Code age** | Recently written/reviewed | Legacy code, "don't touch" modules, vendored-then-forgotten |

**Prioritize: high exposure + low attention.** These are the targets that have never seen a fuzzer. The crown jewels approach finds the highest-*impact* targets; attention deficit mapping finds the highest-*probability* targets. Use both.

Quick heuristics — run these against candidate modules when you need a fast Attention Deficit Score before deciding agent fan-out; skip when the target is small enough to audit exhaustively or when you already know the hot paths:

- `git log --format='%s' -- <path> | grep -ic 'secur\|vuln\|cve\|xss\|sqli\|inject'` — zero hits = never audited
- Check for adjacent `*_test.*`, `*_spec.*`, `fuzz_*` files — absence = untested
- `git log --diff-filter=M --since="2 years ago" -- <path>` — no recent changes = stale, possibly forgotten

## Feed-forward

This scoring feeds Agent Sweep S1 prioritization. See `../methodology/agent-sweep.md` § Prioritization by Attention Deficit for how the score maps to batch-size and agent-assignment strategy.
