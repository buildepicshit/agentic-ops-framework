---
id: T-02-dispatcher-integration
parent_spec: 2026-01-22-webhook-signing-protocol
status: todo
owner: unassigned
model_route: claude-opus-4-7
cross_validation_lane: gpt-5
verification_lane: claude-opus-4-7
mode: HITL
deps: [T-01-signer-and-keystore]
write_scope: disjoint
parallelism_evaluated: true
acceptance_commands:
  - go test ./services/webhooks/...
  - bash test/integration/webhook-roundtrip.sh
  - go vet ./services/webhooks/...
tracker_issue: null
---

# TASK: Dispatcher integration

## 1. Goal

Wire the signer (landed in T-01) into the outbound webhook
dispatcher path. After this slice lands, every outbound
webhook payload MUST carry the `X-Webhook-Signature` header,
and every `DeliveryAttempt` MUST record `signature_version`
and `signing_key_id`.

## 2. Parent SPEC anchor

This task implements §3.1 (Dispatcher component), §6.3
(DeliveryAttempt extension fields), §7.2 (signing flow steps
5-6), and §10 (failure-class handling at the dispatch
boundary) of
`file://examples/contract-webhook-signing/SPEC.md`. The parent
SPEC remains the authority. This file is the executable
contract for THIS slice only.

## 3. Scope

### 3.1 Owned files

Files this worker MAY edit:

- `path/to/services/webhooks/dispatcher.go` — MODIFY; attach
  signature header before `httpClient.Do(req)`. Add the
  `webhooks.signing.enabled` feature flag gate per parent
  §16 Rollback Plan.
- `path/to/services/webhooks/queue/queue.go` — MODIFY;
  `DeliveryAttempt` gains `signature_version` (string) and
  `signing_key_id` (UUIDv7) fields per parent §6.3.
- `path/to/services/webhooks/queue/migrations/0002_delivery_attempt_signing.sql`
  — NEW; PostgreSQL ALTER TABLE for the new columns.
- `path/to/services/webhooks/dispatcher_test.go` — MODIFY;
  add tests covering the signing-enabled and signing-disabled
  flag paths.

### 3.2 Read context

Files this worker MUST read before editing:

- `file://examples/contract-webhook-signing/SPEC.md` (the
  parent SPEC; §§3.1, 6.3, 7.2, 10, 16).
- `file://examples/contract-webhook-signing/tasks/T-01-signer-and-keystore.md`
  (the upstream slice; its exported `Sign()` API is the
  integration point).
- `file://OPERATING_MODEL.md` "Cross-family review".

### 3.3 Out of scope

Out of scope for this slice (covered by sibling tasks):

- Signer + keystore implementation (already landed via T-01).
- Customer-facing REST API surface (handled by
  `T-03-customer-api`).
- Reference verifier snippets in customer languages (handled
  by `T-04-verifier-docs`).
- Observability metrics emission (parent §12; covered by a
  follow-on telemetry-only Task SPEC).

Surface as backlog tracker issues if discovered during
execution per `file://workflow/UNIVERSAL.md` "Universal
guardrails".

## 4. Model dispatch

| Lane | Model | Role |
|---|---|---|
| Primary | `claude-opus-4-7` | Implementation + workpad management. (Different family from T-01 primary to spread cross-family coverage across slices.) |
| Cross-validation | `gpt-5` | Independent diff review. Different family from primary. |
| Verification | `claude-opus-4-7` | Run acceptance_commands; capture fresh evidence. (Mechanical verification; same family as primary is acceptable per parent §17.) |

**Subagent dispatch rules:**

- This slice has tight write-scope (dispatcher.go is one
  file; queue.go is touched lightly). Fanout adds coordination
  cost without wall-clock benefit. Keep local.
- The integration test is a single shell script;
  parallelisation has no benefit.

## 5. Acceptance

### 5.1 Acceptance commands

- `cmd://go test ./services/webhooks/...` — full webhook
  service tests pass post-integration.
- `cmd://bash test/integration/webhook-roundtrip.sh` —
  end-to-end roundtrip: dispatcher signs → mock receiver
  verifies → result matches expected per parent §13 T05.
- `cmd://go vet ./services/webhooks/...` — no lint errors.

### 5.2 Acceptance criteria

- [ ] AC-1: Every outbound webhook carries
  `X-Webhook-Signature` when `webhooks.signing.enabled = true`
  (parent §7.2 steps 5-6).
- [ ] AC-2: When `webhooks.signing.enabled = false`, dispatcher
  resumes unsigned delivery (rollback path per parent §16).
- [ ] AC-3: Every `DeliveryAttempt` record carries
  `signature_version = "v1"` and `signing_key_id` from the
  active key at send time (parent §6.3).
- [ ] AC-4: The dispatcher does NOT log the signing key
  secret at any level (parent §11 trust boundary).

## 6. Evidence

Filled by the executor before `in-review`:

- Files changed: [list].
- Commands run + exit codes: [list].
- Cross-validation findings: [summary; full report linked from PR].
- Residual risk: [if any].

## 7. Stop conditions

Reasons to halt and route back to the owner or root manager:

- Discovered the keystore's `GetActive(endpoint_id)` API
  semantics from T-01 don't match what the dispatcher needs
  (cache invalidation timing, etc.).
- Cross-validation surfaced a blocker.
- Integration roundtrip fails for reasons that aren't local
  to this slice.

## 8. Tracker binding

Once dispatched:

- Tracker issue: `{{tracker_issue}}`
- PR (when opened): [URL]
- Workpad comment ID: [tracker comment id]

The tracker issue's workpad comment is the live execution
journal per `file://workflow/UNIVERSAL.md` Step 1.
