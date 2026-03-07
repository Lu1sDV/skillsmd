# ssrf-testing

Claude Code skill for SSRF (Server-Side Request Forgery) testing and prevention -- find, exploit, and fix SSRF vulnerabilities in web applications.

## What it covers

- Non-blind, blind, and semi-blind SSRF detection (DAST)
- Static analysis: dangerous sinks for PHP, Go, TypeScript/Node.js, Python (SAST)
- Semgrep rules, CodeQL, Bandit, gosec, Psalm integration
- Cloud metadata exploitation (AWS, GCP, Azure, DigitalOcean, Alibaba)
- Filter bypass techniques (IP encoding, DNS rebinding, URL parsing tricks)
- Protocol smuggling (gopher, file, dict)
- Impact escalation via internal services (Elasticsearch, Redis, Jenkins)
- Prevention patterns (URL validation, IMDSv2, network segmentation)
- Code review checklist and vulnerability reporting format

## Installation

### Claude Code Plugin

```
/plugin install ssrf-testing@Lu1sDV/skillsmd
```

### Manual

```bash
git clone --depth 1 https://github.com/Lu1sDV/skillsmd.git
cp -r skillsmd/ssrf-testing ~/.claude/skills/
```

### Verify

```
What skills are available?
```

## Structure

```
ssrf-testing/
├── SKILL.md                    # Main skill -- overview, workflow, quick ref, gotchas
├── README.md                   # This file
└── references/
    ├── payloads.md             # Complete payload lists, bypass techniques, scanning scripts
    ├── prevention.md           # URL validation code, cloud metadata protection, architecture defenses
    └── sast.md                 # Dangerous sinks (PHP/Go/Node/Python), Semgrep rules, code review checklist
```

## Usage examples

- "Test this webhook endpoint for SSRF vulnerabilities"
- "Check if this URL fetch feature can access cloud metadata"
- "Bypass the SSRF filter on this image import endpoint"
- "Implement SSRF prevention for our URL fetching service"
- "Generate an SSRF vulnerability report for this finding"
