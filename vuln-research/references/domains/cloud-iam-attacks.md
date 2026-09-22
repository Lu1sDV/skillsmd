# Cloud IAM & Privilege Escalation — Attack Domain Reference

> Coverage current as of 2026-06

Load this file when the target involves cloud infrastructure (AWS, GCP, Azure), IAM policy audits, service-account credential handling, or inter-service trust chains. Pairs with `references/domains/cicd-supply-chain.md` (pipeline credential exposure) and `references/domains/infra-misconfig-attacks.md` (proxy/container misconfig). Scope: IAM privilege escalation, trust-policy abuse, cross-account chains, SSRF-to-metadata-to-credential, and resource-policy public exposure.

---

## AWS IAM Privilege Escalation

### Classic ~20 Primitive Families

The canonical AWS privesc primitives (drawn from Rhino Security Labs research) fall into these families — each requires only the listed permission(s) and no additional privileges:

| Family | Required Permission | Mechanism |
|--------|-------------------|-----------|
| `iam:CreatePolicyVersion` | `iam:CreatePolicyVersion` | Create a new version of an existing managed policy with `"Action":"*","Resource":"*"` and set it as default |
| `iam:SetDefaultPolicyVersion` | `iam:SetDefaultPolicyVersion` | Flip an existing non-default version of a managed policy to default; useful when a permissive version already exists |
| `iam:PassRole` + `ec2:RunInstances` | Both | Pass an admin role to a new EC2 instance; retrieve credentials via IMDS on the instance |
| `iam:PassRole` + `lambda:CreateFunction` + `lambda:InvokeFunction` | All three | Create a Lambda with an admin execution role; invoke it to exfiltrate `sts:GetCallerIdentity` + credentials |
| `iam:PassRole` + `lambda:UpdateFunctionCode` | Both | Update an existing Lambda's code (without changing the already-attached admin role) |
| `iam:PassRole` + `glue:CreateDevEndpoint` | Both | Glue dev endpoint attaches the passed role; SSH into the endpoint and curl IMDS |
| `iam:PassRole` + `cloudformation:CreateStack` | Both | CloudFormation stack creates resources under the passed role |
| `iam:CreateAccessKey` | `iam:CreateAccessKey` on another user | Create a new access key for a more-privileged user |
| `iam:CreateLoginProfile` / `iam:UpdateLoginProfile` | Either | Set or update console password for a more-privileged user with no MFA |
| `iam:AttachUserPolicy` / `iam:AttachGroupPolicy` / `iam:AttachRolePolicy` | Respective | Attach `AdministratorAccess` to self or a group the attacker is in |
| `iam:PutUserPolicy` / `iam:PutGroupPolicy` / `iam:PutRolePolicy` | Respective | Inline policy write — same effect as managed policy attach |
| `iam:AddUserToGroup` | `iam:AddUserToGroup` | Add self to a group that has admin-level policies |
| `sts:AssumeRole` (misconfigured trust) | None beyond credentials | Role trust policy missing condition constraints allows assume from any principal in the account or from the internet |
| `iam:UpdateAssumeRolePolicy` | `iam:UpdateAssumeRolePolicy` | Rewrite the trust policy of a role to include the attacker's principal |
| `ec2:RequestSpotInstances` + `iam:PassRole` | Both | Spot instance inherits passed role; same IMDS credential retrieval |
| `iam:PassRole` + `datapipeline:CreatePipeline` + `datapipeline:PutPipelineDefinition` | All | Data Pipeline activity runs under passed role |
| `iam:PassRole` + `sagemaker:CreateNotebookInstance` | Both | SageMaker notebook instance inherits role; exec via Jupyter |
| `codestar:CreateProject` + `iam:PassRole` | Both | CodeStar creates IAM resources using the passed role |

**Enumeration:** use `enumerate-iam` (https://github.com/andresriancho/enumerate-iam) or `aws-whoami` + `aws iam simulate-principal-policy` to brute-force what permissions the current identity holds.

### Trust Policy / Confused-Deputy Patterns

- **Missing `aws:SourceAccount` / `aws:SourceArn` condition:** service-linked roles or cross-service roles without a source condition allow any AWS service invocation to assume the role — classic confused deputy. Example: SNS → Lambda trust without `aws:SourceArn` pinning the SNS topic ARN.
- **Wildcard principal in trust policy:** `"Principal": "*"` makes the role publicly assumable from any AWS account (no credential required beyond `sts:AssumeRole`). Also: `"Principal": {"AWS": "*"}` is equivalent.
- **`sts:ExternalId` absent or static:** cross-account trust without ExternalId (or with a guessable static one) allows any account that knows the Role ARN to assume it.
- **`aws:PrincipalOrgID` missing:** role intended for internal cross-account use but trust policy lists `"Principal": {"AWS": "arn:aws:iam::*:root"}` — any account can assume.

### Cross-Account Assume-Role Chains

1. Compromise low-privilege identity in Account A.
2. Enumerate roles in Account A with trust policies allowing assume from Account A principals — escalate within Account A to a role with `sts:AssumeRole` into Account B.
3. Assume role in Account B; enumerate Account B for further chains.
4. Look for "hub" accounts (shared-services, logging, security) whose roles are widely trusted — single compromise reaches all spoke accounts.

**Detection signal:** `CloudTrail:AssumeRole` events crossing account boundaries; roles whose trust policy includes `arn:aws:iam::<external_account>:root` without ExternalId.

---

## AWS SSRF → IMDS Credential Theft

### IMDSv1 (no mitigation)

- `GET http://169.254.169.254/latest/meta-data/iam/security-credentials/` → lists attached role name.
- `GET http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>` → returns `AccessKeyId`, `SecretAccessKey`, `Token` (rotates every ~6 hours).
- One HTTP redirect from an SSRF-vulnerable endpoint is sufficient.

### IMDSv2 (hop-count hardened)

- Requires a `PUT` to obtain session token first: `PUT http://169.254.169.254/latest/api/token` with `X-aws-ec2-metadata-token-ttl-seconds: 21600`.
- SSRF via a redirect chain cannot obtain the token (redirect changes method GET; `PUT` is not redirect-followable by default in most HTTP clients).
- Bypass: if the SSRF-vulnerable client follows the `PUT` manually, or if the application itself caches the IMDSv2 token and returns it in a response, or if the EC2 instance still has `http-tokens=optional` (IMDSv1 fallback enabled).
- ECS task metadata: `http://169.254.170.2/v2/credentials/<uuid>` — exposed via `AWS_CONTAINER_CREDENTIALS_RELATIVE_URI` env var, no PUT required.

---

## GCP — Service Account & IAM Escalation

### Compute Metadata Server

- `http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token` with `Metadata-Flavor: Google` header returns the default service account's OAuth token.
- SSRF note: the required header (`Metadata-Flavor: Google`) is not set by default in most HTTP libraries; check if the vulnerable client sets custom headers or if the proxy strips/adds headers.

### Workload Identity Federation Abuse

- GCP Workload Identity Federation lets external identities (AWS IAM roles, GitHub Actions, K8s service accounts) impersonate GCP service accounts without a key file. Misconfigured attribute mappings (`attribute.sub = "*"`) or overly broad `principalSet` conditions allow any external identity matching the OIDC issuer to impersonate.

### Service Account Key Exfiltration

- Service account JSON keys checked into source control, stored in GCS without object-level ACL, or leaked via application config endpoints.
- `gcloud iam service-accounts keys list --iam-account <sa>` — enumerate keys; old/unused keys with owner-level permissions are high-signal targets.

### `iam.serviceAccountTokenCreator` Escalation

- Holding `iam.serviceAccountTokenCreator` on a service account allows `gcloud auth print-access-token --impersonate-service-account=<sa>` — impersonate any SA at or below the role hierarchy.

---

## Azure — RBAC & Managed Identity Escalation

### Managed Identity SSRF

- Azure IMDS: `http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com/` with `Metadata: true` header → returns managed identity token.
- No PUT/session-token requirement (unlike IMDSv2); a single SSRF GET with the `Metadata: true` header is sufficient.

### Over-Permissive Role Assignments

- `Owner` / `Contributor` at subscription scope assigned to a service principal whose credentials are reachable (managed identity, client secret in Key Vault with over-broad access policy).
- `User Access Administrator` at subscription scope allows the holder to grant themselves Owner — a single-step privesc if the identity holds this role.

### ARM Template / Deployment Script Escalation

- ARM deployments run under the deployment identity; if a deployment script resource is injectable (ARM template parameter injection), the script runs with the deployment identity's permissions.

### Azure AD Application (App Registration) Abuse

- Application with `RoleManagement.ReadWrite.Directory` can grant itself or another principal any Azure AD role including Global Administrator.
- `AppRoleAssignment.ReadWrite.All` allows assigning high-privilege app roles to any service principal.
- `Application.ReadWrite.All` allows adding credentials (client secrets/certificates) to any app registration — impersonate any app.

---

## Resource-Policy Public Exposure

### AWS

- **S3 bucket policy:** `"Principal": "*"` with `"Action": "s3:GetObject"` makes the bucket publicly readable (bypasses Block Public Access when BPA is off at the account or bucket level).
- **SQS / SNS resource policy:** `"Principal": "*"` allows any AWS identity (or unauthenticated) to send/receive messages.
- **Lambda resource-based policy:** `"Principal": "*"` with `"Action": "lambda:InvokeFunction"` — any unauthenticated HTTP caller can invoke the function via the Lambda URL (if enabled) or via API Gateway with the right URL.
- **Secrets Manager / KMS key policy:** `"Principal": "*"` in KMS key policy with no condition — any AWS principal can use the key for encrypt/decrypt.
- **ECR repository policy:** public read (`ecr:GetDownloadUrlForLayer`, `ecr:BatchGetImage`) exposes private container images including embedded secrets.

### GCP

- **GCS bucket IAM:** `allUsers` or `allAuthenticatedUsers` binding with `roles/storage.objectViewer` — world-readable bucket.
- **GCP Cloud Run / Cloud Functions invoker:** `allUsers` on `roles/run.invoker` makes the service publicly invokable without authentication.

---

## K8s Service Account Token Abuse

- Default service account tokens are mounted at `/var/run/secrets/kubernetes.io/serviceaccount/token` in every pod (pre-K8s 1.24 — projected tokens rotate; legacy static tokens do not).
- Token grants `system:serviceaccount:<ns>:<sa>` identity to the K8s API server.
- Common escalation: `ClusterRoleBinding` of `cluster-admin` to the `default` service account in namespace `default` (legacy misconfiguration still present in many clusters).
- SSRF → `http://kubernetes.default.svc/api/v1/namespaces/kube-system/secrets` with the token — enumerate cluster secrets including other service account tokens and TLS certs.
- `hostPath` volume mount with `/` path in a pod spec + `privileged: true` — read/write the node filesystem → escape to node.

---

## OIDC / Federation Token Chains

- GitHub Actions OIDC tokens (`sts.amazonaws.com` audience) can assume AWS roles if the role trust policy matches `token.actions.githubusercontent.com` as the OIDC provider and the subject (`sub`) claim. Misconfigured `sub` condition (`"StringLike": {"token.actions.githubusercontent.com:sub": "repo:*:*"}`) allows any GitHub repo to assume the role.
- See `references/domains/oidc-attacks.md` for full OIDC/OpenID Connect attack surface; this file covers the cloud-IAM-side trust policy misconfiguration pattern.

---

## Enumeration & Tooling

| Tool | Purpose |
|------|---------|
| `Pacu` | AWS attack/enumeration framework; modules for privesc, enum-iam, escalate-iam |
| `ScoutSuite` | Multi-cloud security auditing (AWS/GCP/Azure) — misconfiguration report |
| `enumerate-iam` | Brute-force available IAM permissions for a set of credentials |
| `Prowler` | AWS/GCP/Azure CIS benchmark checks; resource-policy public-exposure checks |
| `cloudsplaining` | AWS IAM policy analysis — unused permissions, privilege escalation paths |
| `PMapper` (Principal Mapper) | Graph-based AWS IAM privesc path analysis |
| `gcloud projects get-iam-policy` | GCP project-level IAM binding enumeration |
| `az role assignment list --all` | Azure subscription-scope role assignments |
| `kubectl auth can-i --list` | K8s permission enumeration for current service account |

---

## Phase Integration

- **Phase L0 (Recency):** flag commits touching IAM policy files (`*.json` trust policies, `*.tf` IAM resources, `cloudbuild.yaml`, `*.github/workflows/*.yml` with `id-token: write`).
- **Phase L1 (Recon):** identify cloud provider(s), service account / managed identity bindings, IMDS version, OIDC federation configuration, cross-account role ARNs.
- **Phase L2 (Crown Jewels):** identify admin roles, cross-account hub roles, service accounts with `iam:PassRole` / `iam.serviceAccountTokenCreator` / `Owner` — treat as highest-priority targets.
- **Phase L4 (Taint):** trace SSRF sinks (`http://169.254.169.254`, `http://metadata.google.internal`, `http://169.254.170.2`) from user-controlled input; trace IAM policy writes from user-controlled JSON.
- **Phase L5 (PoC):** demonstrate credential retrieval via IMDS SSRF using a live endpoint; demonstrate role assumption chain using `aws sts assume-role` with captured credentials. Do not use production admin accounts — PoC against a test environment or stop at credential retrieval.
