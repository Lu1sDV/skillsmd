# Jinja2 Sink Research

## Overview

This page tracks Jinja2-specific sink research for the Python sink catalog.

## What is already known

- Direct template rendering and compilation are high-risk when template source is attacker-controlled.
- Flask integration can widen the sink surface through `render_template_string`, environment mutation, and context exposure.
- Jinja sandbox protections have known limitations and historical bypasses.
- Template loaders and template-name resolution can become injection surfaces.

## Research directions

1. Direct rendering sinks
2. Flask-specific sinks
3. Sandbox escapes and bypasses
4. Loader/include/extends injection
5. Safe-marking and autoescape issues
6. Dangerous globals, filters, tests, and extensions
7. NativeEnvironment and non-HTML generation sinks
8. Edge-case techniques and historical vulnerabilities

## Planned outputs

- New sink candidates
- Source citations
- Detection signatures
- Mitigations
- Confidence levels
