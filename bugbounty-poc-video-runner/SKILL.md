---
name: bugbounty-poc-video-runner
description: "Designs a one-command, triager-friendly live security PoC video runner with staged evidence, expected-versus-actual output, a negative control, optional UI pause, and cleanup proof."
---

# Security PoC Video Runner

Use this procedure when a vulnerability has already been reproduced on an authorized live target and needs a concise video for security triage.

## Goal

Turn the verified reproduction into one command that tells a complete evidence story. The operator should only start recording, run the command, optionally open one printed UI URL, and stop recording.

The video is evidence, not a setup tutorial.

## Non-negotiable evidence

The runner must use the genuine target, production code paths, real identities, and real HTTP requests. Never mock, simulate, patch target behavior, or print invented success messages.

Show these facts explicitly:

1. Authorized target identity and live health.
2. Expected security invariant and expected observable result.
3. Isolated fixture creation through genuine application paths.
4. Security-relevant precondition state immediately before the request.
5. Exact request method and path, without secrets.
6. HTTP status, request/correlation ID, decisive response fields, and persisted effect.
7. A negative control that changes only the suspected authorization source where possible.
8. Expected-versus-actual comparison.
9. Cleanup result and remaining-object audit.

## Preflight plan

Before implementation, identify:

- the authorized target and operator-confirmed scope;
- fixture creation paths and a unique ownership prefix;
- the affected public request;
- an independent persistence check;
- the single variable changed by the negative control;
- cleanup operations for every created object.

If authorization, cleanup ownership, or control isolation cannot be established from the target and repository, stop and ask the operator. Never infer them.

## Operator experience

Expose one command, for example:

```bash
./poc-<finding>-video
```

The command must:

- refuse an unhealthy or wrong target;
- create uniquely prefixed test data;
- stop on failed setup rather than continuing with partial fixtures;
- print short numbered stages as each real action completes;
- run the exploit through the affected public interface;
- verify persistence independently of the response;
- run the negative control;
- clean only objects created by the run;
- exit nonzero unless the complete evidence chain and cleanup pass.

Use an `ensure`/`finally` cleanup path so interruption does not normally leave fixtures behind.

If cleanup fails, print only the IDs of remaining objects created by the run, exit nonzero, and request operator-directed cleanup. Never broaden a cleanup selector or delete an object whose ownership is unverified.

## On-screen structure

Keep output readable at a large terminal font:

```text
<Finding title>
===============

Target: <owned target URL>
Target health: HTTP 200
Test type: live HTTP request
Mocks or target patches: none

EXPECTED SECURITY INVARIANT
---------------------------
<plain-language invariant>
Expected response: HTTP <denial status>
Expected persisted effect: false

[1/N] Creating isolated fixtures ................ OK
[2/N] Establishing vulnerable precondition ....... OK
[3/N] Verifying pre-request authorization state
      <decisive state field>: <value>
[4/N] Sending real request
      <METHOD> <PATH>
      HTTP status: <actual>
      Request ID: <id>
      Persisted effect: <true/false>
[5/N] Running negative control
      Changed only: <suspected source>
      HTTP status: <control status>
      Persisted effect: <true/false>
[6/N] Cleaning isolated fixtures ................. OK

FINAL RESULT
============
                         EXPECTED       ACTUAL
<state>                  <value>        <value>
HTTP status              <denial>       <success>
Persisted effect         false          true
Negative control         <denial>       <denial>

VERDICT: <CONFIRMED/NOT CONFIRMED>
Cleanup: <PASS/FAIL>
```

Progress lines must correspond to completed real actions. Do not use fake activity logs or verbosity as decoration.

## Optional UI confirmation

If persisted state has a useful UI representation, pause after the successful request:

```text
Optional UI confirmation:
<exact resource URL>

Press Enter to continue with the negative control...
```

The operator opens the printed URL, shows the persisted result, returns to the terminal, and continues. The UI is corroboration; the live request and persistence check remain the primary proof.

Never require the operator to create users, roles, tokens, or resources through menus during the recording.

## Negative-control design

Prefer, in order:

1. Same identity, token, endpoint, resource class, and state; remove only the suspected stale authorization source and use a second equivalent resource.
2. Same identity and endpoint with the smallest legitimate state change that restores denial.
3. A matched control identity differing only in the relevant authorization history.

State every changed variable. Never describe a broad cleanup or membership deletion as proof that only one internal row caused the result.

## Secrets and privacy

Never print passwords, access tokens, cookies, authorization headers, private keys, or unrelated user data. Use disposable credentials and masked input. Print resource IDs, safe test usernames, request IDs, and response excerpts only when needed for verification.

## Recording guidance

Aim for two to four minutes:

1. Five to ten seconds: target and expected invariant.
2. Run the one-command PoC.
3. Pause on the decisive exploit result.
4. Optional ten-to-fifteen-second UI confirmation.
5. Run and show the negative control.
6. Pause on the final comparison and cleanup result.

Do not show token creation, lengthy setup commands, raw database browsing, unrelated findings, giant JSON documents, or noisy application logs.

## Delivery check

Before recording, run the exact video runner once against the authorized target and confirm:

- every stage reflects observed behavior;
- request and persistence evidence agree;
- the control isolates the claimed cause as closely as stated;
- interruption and normal completion clean fixtures;
- output contains no secrets;
- the final claim is no broader than the demonstrated impact.
