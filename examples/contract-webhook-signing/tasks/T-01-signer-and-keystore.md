---
id: T-01-signer-and-keystore
parent_spec: 2026-01-22-webhook-signing-protocol
status: todo
owner: unassigned
model_route: gpt-5
cross_validation_lane: claude-opus-4-7
verification_lane: gpt-5
mode: HITL
deps: []
write_scope: disjoint
parallelism_evaluated: true
acceptance_commands:
  - go test ./services/webhooks/internal/signing/...
  - go test ./services/webhooks/internal/keystore/...
  - go vet ./services/webhooks/internal/...
tracker_issue: null
---

# TASK: Signer package + key store

## 1. Goal

Land the cryptographic core of the webhook signing protocol:
the `signing` package that produces `X-Webhook-Signature`
headers and the `keystore` package that persists per-endpoint
keys with rotation + grace window state.

## 2. Parent SPEC anchor

This task implements §6.1 (SigningKey domain model), §6.2
(WebhookSignatureHeader format), §7.1 (state machine), §7.2
(signing flow steps 1-4 and 7), §8.1 (header schema), and
§9.1 (Signer reference algorithm) of
`file://examples/contract-webhook-signing/SPEC.md`. The parent
SPEC remains the authority for what is in scope. This file is
the executable contract for THIS slice only.

## 3. Scope

### 3.1 Owned files

Files this worker MAY edit:

- `path/to/services/webhooks/internal/signing/signer.go` — NEW;
  exports `Sign(secret, payload) string` per parent §9.1.
- `path/to/services/webhooks/internal/signing/signer_test.go`
  — NEW; fixture vectors per parent §13 T01.
- `path/to/services/webhooks/internal/keystore/keystore.go` —
  NEW; per-endpoint key persistence per parent §6.1.
- `path/to/services/webhooks/internal/keystore/keystore_test.go`
  — NEW; covers rotation state machine per parent §7.1.
- `path/to/services/webhooks/internal/keystore/migrations/0001_signing_keys.sql`
  — NEW; PostgreSQL schema per parent §6.1 field set.

### 3.2 Read context

Files this worker MUST read before editing:

- `file://examples/contract-webhook-signing/SPEC.md` (the
  parent SPEC; §§6.1, 6.2, 7.1, 7.2, 8.1, 9.1).
- `file://examples/contract-webhook-signing/IDEA.md` §3
  Constraints (for the "no custom verification library"
  constraint that informs API choice).
- `file://OPERATING_MODEL.md` "Cross-family review" (for the
  blocking review gate this task must pass).

### 3.3 Out of scope

Out of scope for this slice (covered by sibling tasks):

- Dispatcher integration with the signer (handled by
  `T-02-dispatcher-integration`).
- Customer-facing REST API surface (handled by
  `T-03-customer-api`).
- Reference verifier snippets in customer languages (handled
  by `T-04-verifier-docs`).

Surface as backlog tracker issues if discovered during
execution per `file://workflow/UNIVERSAL.md` "Universal
guardrails".

## 4. Model dispatch

| Lane | Model | Role |
|---|---|---|
| Primary | `gpt-5` | Implementation + workpad management. |
| Cross-validation | `claude-opus-4-7` | Independent diff review before Human Review. Different family from primary. |
| Verification | `gpt-5` | Run acceptance_commands; capture fresh evidence. |

**Subagent dispatch rules:**

- The primary agent MUST evaluate whether independent sub-work
  in this slice can fan out (e.g., test authoring in parallel
  with implementation for the two packages).
- Subagents MUST receive bounded scope, allowed files,
  expected output, and write/read posture.
- Subagents MUST NOT modify the parent SPEC.md or this TASK.md
  (read-only).

## 5. Acceptance

### 5.1 Acceptance commands

Each entry in front-matter `acceptance_commands` MUST exit 0
before this task flips `in-progress → in-review`:

- `cmd://go test ./services/webhooks/internal/signing/...` —
  proves the signer produces correct HMAC-SHA256 over
  `<t>.<payload>` matching parent §13 T01 fixture vectors.
- `cmd://go test ./services/webhooks/internal/keystore/...` —
  proves the keystore handles rotation + grace + revoked state
  transitions per parent §13 T03, T04.
- `cmd://go vet ./services/webhooks/internal/...` — no lint
  errors.

### 5.2 Acceptance criteria

- [ ] AC-1: `signing.Sign(secret, payload)` produces the
  `t=<unix>,v1=<hex>` header format per parent §6.2 + §9.1.
- [ ] AC-2: Keystore exposes `GetActive(endpoint_id)`,
  `Rotate(endpoint_id, grace_days)`, `ListActiveAndGrace(endpoint_id)`
  per parent §6.1.
- [ ] AC-3: State transitions (`active → grace → revoked`)
  fire under the schedule defined in parent §7.1.
- [ ] AC-4: No secrets logged at any level (parent §11 trust
  boundary).

## 6. Evidence

Filled by the executor before `in-review`:

- Files changed: [list].
- Commands run + exit codes: [list].
- Cross-validation findings: [summary; full report linked from PR].
- Residual risk: [if any].

## 7. Stop conditions

Reasons to halt and route back to the owner or root manager:

- Owner judgment required mid-slice (e.g., key-encryption-at-
  rest mechanism not yet decided).
- Discovered scope expansion (e.g., the existing DB migrator
  framework needs an upgrade to handle the new migration).
- Cross-validation surfaced a blocker.
- Acceptance commands cannot pass under the bounded scope.

## 8. Tracker binding

Once dispatched:

- Tracker issue: `{{tracker_issue}}`
- PR (when opened): [URL]
- Workpad comment ID: [tracker comment id]

The tracker issue's workpad comment is the live execution
journal per `file://workflow/UNIVERSAL.md` Step 1.
