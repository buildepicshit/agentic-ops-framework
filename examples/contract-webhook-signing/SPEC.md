---
id: 2026-01-22-webhook-signing-protocol
status: approved
type: contract
owner: owner-A
repo: your-policy-repo
branch_policy: worktree-preferred
risk: medium
requires_network: false
requires_secrets: [WEBHOOK_SIGNING_TEST_KEY]
acceptance_commands:
  - go test ./services/webhooks/...
  - go test -run TestSigningProtocol ./services/webhooks/internal/signing/...
  - bash test/integration/webhook-roundtrip.sh
  - bash scripts/lint-spec.sh examples/contract-webhook-signing/SPEC.md
ideated_in: examples/contract-webhook-signing/IDEA.md
---

# SPEC: Webhook signing + verification protocol

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals. RFC 2119 keywords
in this Contract SPEC appear throughout the normative sections.

## 1. Problem Statement

Outbound webhooks at
`file://services/webhooks/dispatcher.go` and
`file://services/webhooks/queue/worker.go` ship unsigned. Three
empirical failure modes drive this work:

- Customer endpoints cannot distinguish our webhooks from
  attacker-forged HTTP POSTs to the same URL
  (`file://docs/support/recurring-questions.md` §"webhook
  auth" — 4 customer requests in 90 days).
- Replay attacks are indistinguishable from our own retry
  delivery (`file://services/webhooks/queue/worker.go` retries
  up to 5×).
- SOC2 audit (`file://docs/compliance/soc2-2025.md` §CC6.7)
  flagged lack of signing as a finding.

Owner directive
(`decision-authority://product-lead:2026-01-19`, captured in
`examples/contract-webhook-signing/IDEA.md` §7):

> "Webhook signing is a Q1 deliverable. Customers want it,
> compliance needs it, the engineering work is bounded."

## 2. Goals and Non-Goals

### 2.1 Goals

- REQUIRED: Sign every outbound webhook payload with HMAC-SHA256.
- REQUIRED: Defend against replay attacks via timestamp +
  tolerance window.
- REQUIRED: Support key rotation with a configurable grace
  window during which both old and new keys verify.
- REQUIRED: Publish a customer-facing verification doc with
  reference snippets in Go, Python, Node, Ruby.
- RECOMMENDED: Telemetry on signature-verification failures
  observed in customer-reported issues so we can track adoption.

### 2.2 Non-Goals

- NOT a transport-layer authentication scheme. mTLS is
  separate.
- NOT covering inbound webhook signing (where we are the
  receiver). Out of scope.
- NOT adopting the IETF HTTP Message Signatures draft. The
  Contract assumes HMAC-SHA256 per `decision-authority://
  product-lead:2026-01-19` and the §5 recommendation in
  `examples/contract-webhook-signing/IDEA.md`.

## 3. System Overview

### 3.1 Components

- **Signing key store** — per-endpoint key material with
  metadata (created_at, rotated_at, status, grace_until).
  Lives in `file://services/webhooks/internal/keystore/keystore.go`.
- **Signer** — given a payload + endpoint, produces the
  signature header. `file://services/webhooks/internal/signing/signer.go`.
- **Dispatcher** — composes the outbound HTTP request, attaches
  the signature header. `file://services/webhooks/dispatcher.go`
  (existing; modified).
- **Customer verifier** — out-of-tree (in customer code);
  documented reference impl in `file://docs/webhooks/verifying.md`
  + per-language snippets at
  `file://docs/webhooks/examples/<lang>/verify.<ext>`.

### 3.2 Components diagram (text)

```
[customer dashboard]
  │
  └─ GET /v1/webhook-endpoints/{id}/signing-keys
       │
       ▼
  ┌─────────────────┐         ┌──────────────────┐
  │  Key store      │ ◄────── │  Signing API     │
  │  (PostgreSQL)   │         └──────────────────┘
  └─────────────────┘                 ▲
       ▲                              │
       │ rotate                       │ sign
       │                              │
  ┌─────────────────┐         ┌──────────────────┐
  │  Rotator        │         │  Signer          │
  │  (cron)         │         └──────────────────┘
  └─────────────────┘                 ▲
                                      │ used by
                                      │
                              ┌──────────────────┐
                              │  Dispatcher      │
                              │  (existing)      │
                              └──────────────────┘
                                      │ HTTPS POST
                                      ▼
                              ┌──────────────────┐
                              │  Customer        │
                              │  endpoint        │
                              │  + verifier      │
                              └──────────────────┘
```

## 4. Authority Map

Active authority:

- `examples/contract-webhook-signing/IDEA.md` — producing IDEA
  at `ready-for-spec` with all §6 questions resolved.
- `decision-authority://product-lead:2026-01-19` — Q1
  deliverable directive.
- `decision-authority://tech-lead:2026-01-20` — key-rotation
  + replay-protection requirements.
- `url://stripe.com/docs/webhooks/signatures` — wire-format
  reference precedent.
- `url://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries`
  — second reference precedent for HMAC-SHA256 over payload.

Stale, superseded, or evidence-only sources:

- `url://datatracker.ietf.org/doc/html/draft-ietf-httpapi-signatures`
  — IETF draft; NOT adopted; cited for reader awareness only.

Owner decisions required before implementation:

- [x] Algorithm choice (HMAC vs Ed25519 vs HTTP MessageSig) —
  resolved HMAC per IDEA §5.
- [x] Tolerance window for replay protection — resolved 5
  minutes per IDEA §6 Q2.
- [x] Key rotation grace window — resolved 7 days default,
  configurable per endpoint, per IDEA §6 Q3.

## 5. Code/Docs Reality Check

| Surface | Current claim | Observed reality | Required action |
|---|---|---|---|
| `file://services/webhooks/dispatcher.go` | "POSTs payload to endpoint URL" | Correct; no signing | add signature header before send |
| `file://docs/webhooks/index.md` | "Webhooks are delivered over HTTPS" | Correct, but silent on auth | rewrite §Authentication |
| `file://docs/compliance/soc2-2025.md` §CC6.7 | "Outbound webhook signing: planned" | Planned, not implemented | mark resolved after this SPEC lands |
| `file://services/webhooks/queue/queue.go` §DeliveryAttempt | tracks attempt_n, dispatched_at | matches | extend with `signature_version`, `signing_key_id` |

## 6. Domain Model

### 6.1 SigningKey

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `id` | UUIDv7 | REQUIRED | UUIDv7 | the signing key identifier; exposed to customers |
| `endpoint_id` | UUIDv7 | REQUIRED | UUIDv7 | the webhook endpoint this key signs for |
| `secret` | bytes | REQUIRED | 32 bytes | random; HMAC-SHA256 key material |
| `version` | string | REQUIRED | `v1` | wire-format version; bumps require new SPEC |
| `created_at` | RFC3339 | REQUIRED | UTC timestamp | |
| `rotated_at` | RFC3339 \| null | REQUIRED | UTC or null | set when this key is superseded |
| `grace_until` | RFC3339 \| null | REQUIRED | UTC or null | until when this key still verifies (post-rotation) |
| `status` | enum | REQUIRED | `active` \| `grace` \| `revoked` | state machine; see §7 |

### 6.2 WebhookSignatureHeader

| Field | Type | Required | Notes |
|---|---|---|---|
| `t` | integer (unix seconds) | REQUIRED | request creation time; replay-rejected if too old |
| `v1` | hex string (64 chars) | REQUIRED | HMAC-SHA256(secret, `<t>.<raw-payload>`); lowercase hex |

Header wire format: `X-Webhook-Signature: t=<unix>,v1=<hex>`.
Multiple `v1=` values MAY be present if a key has been rotated
mid-flight (the dispatcher MAY include signatures from both
the active key and the grace-window key).

### 6.3 DeliveryAttempt (existing; extended)

Existing fields preserved. New fields added by this SPEC:

| New field | Type | Required | Notes |
|---|---|---|---|
| `signature_version` | string | REQUIRED | matches `SigningKey.version` (`v1`) |
| `signing_key_id` | UUIDv7 | REQUIRED | the active key id at send time |

## 7. Behavior / State Specification

### 7.1 SigningKey state machine

```
                  rotate-out
       ┌─────────────────────────┐
       ▼                         │
  ┌─────────┐    rotate-in   ┌────────┐
  │  active │ ◄────────────  │  grace │
  └─────────┘                └────────┘
       │                         │
       │ grace_until passes      │ grace_until passes
       │                         │
       ▼                         ▼
  ┌─────────┐                ┌─────────┐
  │  active │                │ revoked │
  └─────────┘                └─────────┘
```

- A newly created key starts at `active`.
- When a rotation is initiated, the existing `active` key
  transitions to `grace` with `grace_until = now + grace_window`.
  A new key is created and becomes the new `active`.
- A `grace` key transitions to `revoked` when `now > grace_until`.
- Signing: only the `active` key signs new payloads.
- Verifying: customers MAY accept both `active` and `grace`
  signatures during the grace window.

### 7.2 Signing flow

1. Dispatcher composes the payload bytes.
2. Dispatcher fetches the active SigningKey for the endpoint
   (cached for 60 seconds).
3. Dispatcher computes `t = current unix time` and
   `v1 = HMAC-SHA256(key.secret, "<t>.<raw-payload>")`.
4. Dispatcher attaches header
   `X-Webhook-Signature: t=<t>,v1=<hex(v1)>`.
5. Dispatcher attaches header
   `X-Webhook-Signing-Key-Id: <key.id>` for adopter convenience.
6. Dispatcher POSTs the request.
7. Dispatcher records the `DeliveryAttempt` with
   `signature_version = "v1"` and `signing_key_id = key.id`.

### 7.3 Verification flow (customer side; documented in
`file://docs/webhooks/verifying.md`)

1. Customer reads `X-Webhook-Signature` header. Parses `t` and
   `v1` values.
2. Customer rejects if `|now - t| > 5 minutes` (replay
   protection).
3. Customer computes `expected = HMAC-SHA256(secret, "<t>.<raw-payload>")`.
4. Customer constant-time-compares `expected` to `v1` (hex
   decode).
5. On match, customer accepts the payload. On mismatch, rejects
   with 401 (recommended; product also retries on 5xx).

## 8. Schema Specification

### 8.1 Header schema (informal)

```
X-Webhook-Signature: t=<unix-seconds>,v1=<hex-64>[,v1=<hex-64>]*
X-Webhook-Signing-Key-Id: <UUIDv7>
```

- Multiple `v1=` values permitted (rotation in flight); the
  customer's verifier MUST accept if ANY `v1` matches.
- The header MUST be ASCII; no whitespace inside values.

### 8.2 Signing key API (REST)

`GET /v1/webhook-endpoints/{id}/signing-keys`

Response (200 OK):

```json
{
  "active": {
    "id": "<uuidv7>",
    "secret": "<base64url>",
    "version": "v1",
    "created_at": "<rfc3339>"
  },
  "grace": null | {
    "id": "<uuidv7>",
    "secret": "<base64url>",
    "version": "v1",
    "rotated_at": "<rfc3339>",
    "grace_until": "<rfc3339>"
  }
}
```

`POST /v1/webhook-endpoints/{id}/signing-keys/rotate`

Request body: optional `grace_window_days` (integer, default
7, max 30).

Response (200 OK): same shape as GET, with the new key as
`active` and the prior key as `grace`.

## 9. Reference Algorithms

### 9.1 Signer (Go pseudocode)

```go
func Sign(secret []byte, payload []byte) string {
    t := time.Now().Unix()
    mac := hmac.New(sha256.New, secret)
    fmt.Fprintf(mac, "%d.", t)
    mac.Write(payload)
    sig := hex.EncodeToString(mac.Sum(nil))
    return fmt.Sprintf("t=%d,v1=%s", t, sig)
}
```

### 9.2 Verifier (Go pseudocode, for the customer)

```go
func Verify(header string, payload []byte, secret []byte,
            tolerance time.Duration) bool {
    t, sigs := parseHeader(header)
    if abs(time.Now().Unix()-t) > int64(tolerance.Seconds()) {
        return false  // replay-rejected
    }
    expected := hmac.New(sha256.New, secret)
    fmt.Fprintf(expected, "%d.", t)
    expected.Write(payload)
    want := hex.EncodeToString(expected.Sum(nil))
    for _, sig := range sigs {
        if hmac.Equal([]byte(want), []byte(sig)) {
            return true
        }
    }
    return false
}
```

## 10. Failure Model

| Failure class | Cause | Detection | Recovery |
|---|---|---|---|
| `signing-key-missing` | Endpoint has no active key (programmer error) | Dispatcher returns 500 internally; alerts on-call | Auto-create on next rotation cycle; meanwhile dispatcher skips signing and emits a metric `webhook_signed_total{result="missing"}` |
| `replay-rejected` | Customer rejects payload as `t` is too old | Customer 401 / 4xx | Dispatcher records the rejection; on retry (with fresh `t`), customer accepts |
| `customer-secret-leak` | Customer-side leak | Out of band (customer reports) | Customer initiates rotation; product issues new key with 7-day grace |
| `grace-window-misuse` | Customer relied on grace beyond `grace_until` | Customer 401 starts on `grace_until` | Customer rotates their verifier to use the new key |
| `clock-skew` | Customer clock is wrong | Verifier rejects within tolerance | Product surfaces a `Date` header in the response for client-side correction |

## 11. Trust Boundary / Security

- The signing key secret is the **only** shared secret between
  product and customer. Compromise of any other surface (TLS
  cert, customer dashboard credentials) does not compromise
  signing integrity by itself.
- The key store MUST be encrypted at rest. The key MUST be
  delivered to the customer over TLS via an authenticated API
  call.
- The signing endpoint MUST be rate-limited per customer
  account.
- A leaked customer secret REQUIRES rotation. Customers MAY
  initiate rotation via the API (`POST .../rotate`).
- The product MUST NOT log signing key secrets at any level.

## 12. Observability

Metrics:

- `webhook_signed_total{result}` — counter; `result` ∈
  {`ok`, `missing-key`, `error`}.
- `webhook_rotation_total{trigger}` — counter; `trigger` ∈
  {`scheduled`, `customer-requested`, `incident`}.
- `webhook_signing_key_age_days` — gauge per active key.

Logs (structured per the lint-recommended schema, see
`examples/task-add-structured-logging/SPEC.md`):

- `webhook.sign.error` at level `error` includes
  `endpoint_id`, `key_id`, `attempt_n`.

## 13. Test and Validation Matrix

| Test ID | What is verified | Method | Severity |
|---|---|---|---|
| T01 | HMAC over `<t>.<payload>` matches the reference (Stripe-compat) | unit test against fixture vectors | Blocking |
| T02 | Replay rejection at `|now - t| > 5 min` | unit test on verifier | Blocking |
| T03 | Rotation produces a grace-period key; both verify until `grace_until` | integration test | Blocking |
| T04 | `grace` → `revoked` on cron after `grace_until` passes | integration test with simulated time | Blocking |
| T05 | Dispatcher records `signing_key_id` on each DeliveryAttempt | integration test | Blocking |
| T06 | Per-language verifier snippets match Go reference | conformance test fixture | Blocking |
| T07 | Key store rejects log emission of secrets | grep over emitted logs in test | Blocking |
| T08 | Header parse: multiple `v1=` values handled correctly | unit test on verifier | Advisory |

## 14. Implementation Checklist (Definition of Done)

- [ ] D01 (REQUIRED): Signer package emits canonical header per §8.1.
- [ ] D02 (REQUIRED): Key store + rotation worker land per §6.1, §7.1.
- [ ] D03 (REQUIRED): Dispatcher attaches signature on every outbound webhook.
- [ ] D04 (REQUIRED): Customer-facing API `GET/POST .../signing-keys[/rotate]` matches §8.2.
- [ ] D05 (REQUIRED): Reference verifier snippets land in `docs/webhooks/examples/{go,python,node,ruby}/verify.*`.
- [ ] D06 (REQUIRED): `docs/webhooks/verifying.md` rewritten with the §7.3 verification flow.
- [ ] D07 (REQUIRED): All T01-T07 tests pass.
- [ ] D08 (RECOMMENDED): T08 advisory test passes.
- [ ] D09 (RECOMMENDED): Telemetry per §12 emits in staging.
- [ ] D10 (REQUIRED): SOC2 evidence file updated marking CC6.7 resolved.

## 15. Acceptance Criteria

- [ ] AC-1: All §14 D01-D07 REQUIRED items complete — verified
  by `cmd://go test ./services/webhooks/...` exit 0 and manual
  inspection of D04-D06 surfaces.
- [ ] AC-2: T01 fixture vectors match Stripe-compat reference
  output — verified by `cmd://go test -run TestSigningProtocol`
  exit 0.
- [ ] AC-3: Integration roundtrip (signer → header → verifier
  in each documented language) succeeds — verified by
  `cmd://bash test/integration/webhook-roundtrip.sh` exit 0.
- [ ] AC-4: This SPEC passes lint — verified by `cmd://bash
  scripts/lint-spec.sh examples/contract-webhook-signing/SPEC.md`
  exit 0.
- [ ] AC-5: §19 Completion Report filled with verification
  output.

## 16. Rollback Plan

The signing path is opt-out at the dispatcher boundary. If a
post-deploy issue surfaces:

1. Set the global feature flag `webhooks.signing.enabled =
   false` (already gated via
   `file://services/webhooks/dispatcher.go` §FeatureGate).
2. Dispatcher resumes unsigned delivery within 60 seconds (the
   key-cache TTL).
3. Revert per-PR commits if the root cause is in the new code.
4. Customers who relied on signing in production receive an
   advance status-page notice before re-enable.

The key store itself is additive; rolling back signing does NOT
require dropping the `signing_keys` table.

## 17. Open Questions

- [x] All design questions resolved in IDEA §6.

## 18. Migration / Coexistence

### 18.1 Existing webhook consumers

Existing customers without signing capability MUST continue to
receive webhooks unchanged. The `X-Webhook-Signature` header
is informational from their perspective; they can ignore it.
(`decision-authority://product-lead:2026-01-19` — opt-in
constraint from IDEA §3.)

### 18.2 New customers (post-rollout)

The customer onboarding doc
(`file://docs/customer-onboarding.md` §Webhooks) is updated to
recommend verifier integration before going live. Verification
remains opt-in; the product never refuses to deliver based on
the customer's verification posture.

### 18.3 In-flight delivery during initial rollout

The dispatcher signs every payload from the moment the
feature flag flips to `true`
(`file://services/webhooks/dispatcher.go` §FeatureGate). There
is no mid-flight incompatibility — existing customers receive
an additional header they may ignore.

### 18.4 Future signature versions

Wire-format changes (adding a new `v2` algorithm, etc.) MUST
be authored as a new Contract SPEC superseding this one
(`judgment://agent-synthesis`, captured in IDEA §3 backwards-
compatibility constraint). The key-store `version` field on
`SigningKey` (per §6.1) exists to enable side-by-side operation
during a hypothetical future migration.

## 19. Completion Report

(to be filled by the executor — see template sections 19.1
through 19.5)

### 19.1 Files changed

(to be filled)

### 19.2 Commands run

(to be filled — paste relevant excerpts of `acceptance_commands` outputs)

### 19.3 Verification result

(to be filled)

### 19.4 Residual risk

(to be filled)

### 19.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
