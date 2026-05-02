# Jinja2 Long-Horizon Research Plan

## Goal

Expand the Python sink catalog with Jinja2-specific sinks, techniques, and detection guidance.

## Scope

- Direct template compilation/rendering sinks
- Flask/Jinja integration sinks
- Sandbox escapes and misconfiguration
- Attribute traversal / object graph access
- Safe-marking / autoescape / MarkupSafe issues
- Loader/include/extends/template-name injection
- Dangerous globals, filters, tests, extensions
- NativeEnvironment and non-HTML code/config generation
- Real-world CVEs, advisories, and writeups
- Static-analysis rule coverage

## Research lanes

1. Official Jinja2 docs and security model
2. Direct rendering/compilation sinks
3. Flask integration sinks
4. Sandbox escapes
5. Attribute traversal and object graph access
6. Autoescape, MarkupSafe, and XSS sinks
7. Loader/include/template-name injection
8. Custom filters, tests, globals, extensions
9. NativeEnvironment and code/config generation sinks
10. Real-world CVEs and writeups
11. Static-analysis rules
12. Obscure/edge-case Jinja2 techniques

## Deliverables

- Ranked sink candidates with examples
- JSON metadata blocks for new entries
- Archived source corpus
- Detection signatures for Semgrep/CodeQL-style rules
- Confidence and mitigation notes

## Validation

- Every sink has a vulnerable Python example
- Every sink has at least one source citation
- Every sink has a detection signature and mitigation
- Every source is archived with a stable path
