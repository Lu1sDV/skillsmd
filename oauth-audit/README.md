# OAuth Audit

Review OAuth 2.0 and OpenID Connect implementations with findings tied to code
locations and normative sources. Use it for authorized reviews of client,
authorization-server, or resource-server behavior, including redirects, PKCE,
token exchange, refresh flows, and token validation.

## Use

```text
Use $oauth-audit to review this authorization-code integration and report supported findings with code locations, RFC sections, and remediation.
```

Start with the [skill workflow](SKILL.md). Establish the client type, grant flows,
provider trust model, and token surfaces before applying the checklist. The
expected report identifies each finding's checklist item, severity, evidence,
and RFC/CWE/OWASP mapping; unresolved questions remain explicit.

## Contents

- [Audit checklist and report template](references/audit-checklist.md): detailed checks, rating guidance, code patterns, and reporting structure.
- [JWT security review](references/jwt-security.md): additional patterns for signatures, key selection, claims, token purpose, and cookies.
- [Primary references](SKILL.md#references): OAuth specifications and related security guidance.

## Install

Copy the complete `oauth-audit/` folder into the skill directory recognized by
your agent, including both references used by the entry point.
