---
name: vast-experiment-ops
description: Use when running or reporting ML experiments on rented Vast.ai GPU instances — diagnosing strict FP32 equivalence checks that pass on CPU but fail on CUDA (cuDNN TF32), parsing JSON metrics collected over SSH, and keeping held-out/test-scope reporting accurate.
---

# vast-experiment-ops

Error-informed operational playbook for renting, running, and reporting ML
experiments on Vast.ai. It supplements the platform docs and the instance's own
guide; it replaces neither.

## Quick reference

| Situation | Action |
|---|---|
| Strict FP32 equivalence passes on CPU, fails on CUDA | Re-run the unchanged check in a fresh process with `NVIDIA_TF32_OVERRIDE=0` set before Python starts |
| `JSONDecodeError` parsing remote metrics | Capture stdout/stderr separately, parse stdout only; collector emits exactly one JSON document on stdout |
| Asked whether the test split was used | Answer from this run's queue config and result metadata plus prior artifacts — never open test data to answer |
| Reporting progress | Include UTC time, snapshot age, active trial/epoch, and complete/pruned/failed/running counts |
| Sizing a job | Check cgroup CPU/RAM limits, free GPU memory, free disk, and storage persistence — host totals mislead |

## Ground rules

- Get the instance address and experiment paths from the user or project
  config. Never reuse an address remembered from this skill.
- Read the instance's own guide (e.g. `/etc/vast-agents-guide.md`) before
  operating on it; use its Python environment and service manager.
- Treat a status request as read-only: do not restart services, change
  numerical settings, or read held-out data just to report progress.

## Case 1 — CPU passes, CUDA fails strict recurrent equivalence

**Observed:** step-versus-full-replay GRU/LSTM checks passed on CPU but failed
on an RTX 4000 Ada (PyTorch 2.11.0+cu128, cuDNN 91900). Default cuDNN TF32 was
implicated. Setting `NVIDIA_TF32_OVERRIDE=0` before Python started restored
equivalence: all 56 CUDA tests passed with no source or tolerance change.

Procedure:

1. Preserve the failing assertion, tolerances, source revision, and the CPU vs
   CUDA comparison; record GPU, PyTorch, CUDA, cuDNN, and precision settings.
   If the failure is already reported, work from it — do not re-run to confirm.
2. For a strict FP32 equivalence failure, run the unchanged failing check in a
   fresh Python process with `NVIDIA_TF32_OVERRIDE=0` in its environment.
3. If that resolves the mismatch, apply the override in the experiment's
   launcher before Python starts and record it in the run manifest. Do not
   silently change a running training job or relax tolerances.
4. Re-verify the original invariant on CUDA. A successful import or
   `cuda.is_available()` is not proof.

Boundary: this is a conditional diagnostic, not a universal GPU setting — do
not disable TF32 for unrelated workloads that have no correctness requirement.
The NVIDIA override can win even while `torch.backends.cudnn.allow_tf32` still
reads `True`; record the actual environment alongside the observed result.

## Case 2 — SSH output cannot be parsed as JSON

**Observed:** parsing a combined tool-output artifact raised `JSONDecodeError`
because the Vast SSH welcome banner preceded the JSON payload. Capturing
subprocess stdout and stderr separately allowed the JSON to decode.

Procedure:

1. Keep remote stdout, stderr, and exit status separate: with Python
   subprocesses use `capture_output=True, text=True` and a finite timeout;
   parse `result.stdout`, not a rendered tool transcript or concatenated output.
2. Check exit status first; preserve stderr for diagnostics instead of hiding
   authentication or remote-command failures.
3. Make the remote collector emit exactly one JSON document on stdout and send
   diagnostics to stderr; validate the decoded shape before using any metric.
4. If banner text still reaches stdout, fix its source or use an explicit,
   validated framing protocol. Do not grab the first `{`, the last line, or
   suppress decode errors.

Verification: exercise the real SSH collection path — it must return a
successful exit status, parseable JSON, and the expected fields (timestamp,
current run, trial states, metrics, collection errors). Parsing a hand-cleaned
local sample is insufficient.

## Case 3 — "test data has not been read" overstates scope

**Observed:** claiming test data had not been read overstated the scope: the
current tuning queue skipped test evaluation, but an earlier pilot had already
evaluated that split. Dev-only seed confirmation was not an independent
held-out evaluation.

Procedure:

1. Establish this run's metric split and evaluation policy from the queue
   configuration and result metadata; check earlier artifacts for prior test
   inspection — without opening test data to answer the question.
2. Report the narrow truth: "this tuning queue skips test evaluation." If prior
   inspection happened, disclose it; if history is unknown, say so rather than
   implying the split is untouched.
3. Keep distinct: best single-trial dev score, selected-checkpoint metrics,
   multi-seed dev confirmation, held-out evaluation. One does not establish
   another.
4. Label best-epoch and latest-epoch metrics separately; never present
   latest-epoch precision/recall/Hit@1/MRR as metrics of an earlier best-F1
   checkpoint.
5. Describe score differences with their selection scope — a dev-search lead is
   not a demonstrated generalization gain or a significance result.

Verification: trace every reported score to its architecture, trial/seed, split,
and epoch or selected checkpoint, and check that test-scope wording matches both
the current queue and known earlier evaluations.

## Reporting and instance hygiene

- Follow the instance guide's managed-service pattern for durable jobs. Check
  supervisor state plus recent progress timestamps or updates; `RUNNING` alone
  does not establish healthy training, and a single low GPU-utilization sample
  does not establish a stall.
- Report a UTC observation time, snapshot age, active trial and epoch, and
  counts of complete/pruned/failed/running trials. Pruning is not a failure;
  distinguish pending runs from totals that include the active run.
- Read remaining-run counts and seed-confirmation stages from the actual queue
  configuration, not a remembered budget.
- Record source/data/model revisions, seeds, environment overrides, and the
  selected-checkpoint identity in the run manifest. Back up important results
  before destructive instance operations, and obtain authorization before
  stopping or destroying an instance.

Keep addresses, credentials, dataset choices, trial budgets, and current
benchmark scores out of this reusable skill; store them in the experiment's own
configuration and artifacts.
