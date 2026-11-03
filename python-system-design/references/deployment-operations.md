# Deployment and operations

## Contents

- [Build the runtime artifact](#build-the-runtime-artifact)
- [Separate release and process lifecycles](#separate-release-and-process-lifecycles)
- [Make health and shutdown meaningful](#make-health-and-shutdown-meaningful)
- [Instrument bounded operational signals](#instrument-bounded-operational-signals)
- [Verify the deployment boundary](#verify-the-deployment-boundary)

## Build the runtime artifact

Reuse the project's supported packaging/deployment workflow. For a new Python
service, start from stable Python 3.15 and verify its dependencies, native wheels,
server and deployment platform support that interpreter. A free-threaded build
is a separate compatibility choice, not implied by the Python version number.
Pin and record build/runtime identities; a version tag can still move. Digest
pinning makes the selected base image reproducible but requires a deliberate
security-update process. See [Docker build guidance](https://docs.docker.com/build/building/best-practices/).

For containers:

- Install dependencies before frequently changing application source to preserve
  cache reuse. Keep build tools/compiler libraries out of the final stage when
  practical; retain required runtime shared libraries.
- Install the application non-editably. Copying a virtual environment requires
  compatible interpreter/ABI, platform, runtime libraries and paths in both stages;
  a venv is not a portable artifact between arbitrary base images.
- Run as a non-root user with intentional file permissions and writable state
  directories. Keep source/build context bounded with `.dockerignore`; exclude
  local venvs, caches and real secrets. Use build secret mounts when needed,
  not persisted `ARG`/`ENV` values or copied credentials.
- Use exec-form `CMD`/`ENTRYPOINT`; shell wrappers must `exec` the server. Select
  and test the actual stop signal and grace period. A custom Python worker needs
  a shutdown policy; JSON syntax alone does not implement one.

For an existing uv-managed, installable application, a common two-stage install
sequence is dependency-only sync followed by a final sync with source present:

```sh
uv sync --locked --no-default-groups --no-install-project
uv sync --locked --no-default-groups --no-editable
```

These commands require the appropriate metadata/lockfile in each stage. Select
runtime extras/groups deliberately: `--no-dev` excludes only the `dev` group,
whereas other default groups may also contain tooling. A BuildKit cache mount for
uv works with `UV_LINK_MODE=copy`; bytecode compilation is an optional startup
optimization. If the base supplies the interpreter, disabling uv's Python
downloads avoids accidentally introducing a second runtime.

Workspaces need their member metadata and local dependency sources. Copy the root
metadata and lockfile first; when member metadata is not yet present, use the
current uv Docker pattern
`uv sync --frozen --no-install-workspace`. The final sync, with all metadata/source
present, must use `--locked` to validate freshness and `--no-editable` for the
deployed environment. `--frozen` alone skips the freshness check. Set the intended
`--package`, extras and groups consistently; do not accidentally ship all tools
or unrelated members. See [uv Docker integration](https://docs.astral.sh/uv/guides/integration/docker/)
and [default dependency groups](https://docs.astral.sh/uv/concepts/projects/dependencies/#default-groups).

## Separate release and process lifecycles

Web, worker and migration commands can use the same built image when they share
a release. They still have distinct concurrency, credentials, signals and health
contracts. One image is a useful option, not a reason to bundle unrelated services.

Run migrations in an explicit, coordinated release step. Every replica's startup
hook is not a once-only mechanism. Use the compatible rollout/backfill sequence
in [persistence and configuration](persistence-config.md); control which release
owns schema changes and verify recovery before destructive contraction.

Create clients/pools and telemetry in the process that owns them; do not inherit
open database connections or background exporter threads across a worker fork.
Keep import-time registration required by a framework explicit and eager even
when the application uses optional lazy imports. For worker telemetry, use the
framework's documented process initialization hooks.

Define trusted proxy peers/networks and the actual forwarding topology. Ignore
forwarding headers from untrusted direct peers; use server/framework support
where possible. Fixed `X-Forwarded-For` positions are valid only under the proven
proxy topology, not a universal client-IP rule. Test the production path for host,
scheme, client-IP and redirect handling; also configure TLS termination, body
limits and request deadlines. See [FastAPI proxy deployment](https://fastapi.tiangolo.com/advanced/behind-a-proxy/).

## Make health and shutdown meaningful

Distinguish **liveness** (a restart can repair this process), **readiness** (this
instance should receive work) and **startup** (initialization is complete).
An upstream/database outage should not automatically cause every healthy process
to restart. Include dependencies in readiness only when their failure makes that
instance unable to serve its contract; use bounded, inexpensive checks. Avoid
returning credentials, topology or detailed exceptions from public probes.
See [Kubernetes probe semantics](https://kubernetes.io/docs/concepts/workloads/pods/probes/)
for one platform's implementation; adapt to the deployed platform.

For shutdown: stop accepting new work, update readiness/drain routing, wait for
owned operations within a deadline, then cancel and close remaining resources.
Align the server/worker grace period with the platform's termination deadline;
budget time for telemetry flush and connection cleanup. Forced kill cannot run
cleanup, so required jobs still need recovery and duplicate handling. Test the
configured stop signal rather than assuming all Python commands handle SIGTERM
or that `STOPSIGNAL SIGINT` suits every process.

For Celery, TERM normally initiates warm shutdown; cold/forced termination changes
requeue behavior. `app.control.ping()` shows broker/control-plane responsiveness,
not successful job execution: a busy `solo` pool may delay replies. Combine
appropriate process checks with queue age, worker heartbeats and observed job
progress. See [Celery worker shutdown/control](https://docs.celeryq.dev/en/stable/userguide/workers.html).

## Instrument bounded operational signals

Record request/job rates, latency, error categories and saturation at consequential
boundaries. For workers, include queue age, attempts, terminal failures and stalled
progress; a running process and a short queue do not prove timely completion.
Logs, metrics and traces answer different questions and should share useful
nonsecret correlation fields without making a unique ID a metric label.

Use route templates such as `/orders/{order_id}` for HTTP metric dimensions.
Never substitute raw paths, user/job IDs, query strings or exception messages;
when no template is available, omit the attribute or use a bounded unmatched
category. Account for mounted applications without adding per-request values.
Normalize method/error labels to a bounded set too. Prefer supported framework
instrumentation to custom decorators that miss routing, streaming or cancellation.
See [OpenTelemetry HTTP metrics](https://opentelemetry.io/docs/specs/semconv/http/http-metrics/).

Configure resource identity such as `service.name`, exporter destinations and
sampling deliberately. Verify stdlib/server logs join the intended structured
pipeline; configuring only an application logger does not configure every logger.
Bound and sanitize incoming correlation IDs and clear per-operation context before
reuse. Preserve cancellation and the original failure: telemetry cleanup must not
read uninitialized status or replace an exception with its own error.

Trace context must cross HTTP/broker boundaries through the supported propagator
or configured instrumentation on both sides. Test a producer-to-worker trace;
do not assume an in-process context variable crosses the broker or hand-roll
serialization when the instrumentation already supplies it. With prefork Celery,
initialize tracing/exporters after worker-process initialization. Flush/shut down
owned providers within the graceful-shutdown budget; neither an exit hook nor an
explicit shutdown can guarantee export after SIGKILL. See [Python instrumentation](https://opentelemetry.io/docs/languages/python/instrumentation/)
and [Celery instrumentation](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/celery/celery.html).

## Verify the deployment boundary

Run the built image as its production user with only declared configuration and
resources. Exercise the actual entrypoint, import/packaged-resource access,
readiness transitions and configured shutdown signal. Check partial startup
failure, dependency outage and cancellation cleanup. For required jobs, kill a
real worker and observe recovery/duplicate behavior; for observability, inspect
route labels, propagated context and final exports. Report which boundaries were
executed and which require the consuming application's infrastructure.
