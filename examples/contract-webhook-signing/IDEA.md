---
id: webhook-signing-protocol
spec_id: 2026-01-22-webhook-signing-protocol
status: ready-for-spec
owner: owner-A
brainstormed_by: claude-opus-4-7
brainstormed_on: 2026-01-22
implies_spec_type: contract
---

# Webhook signing + verification protocol

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem Seed

The product ships outbound webhooks to customer-controlled HTTP
endpoints
(`file://services/webhooks/dispatcher.go`,
`file://services/webhooks/queue/worker.go`). Today, payloads are
sent in plaintext over TLS with no signature. Customers have
requested cryptographic signing so they can verify a webhook
genuinely originated from the product before acting on it. The
support team reports four security-review requests in the past
quarter where customers asked "how do we verify the webhook
came from you" and we had no answer
(`file://docs/support/recurring-questions.md` §"webhook auth").

Three failure modes are surfacing in absence of signing:

- Customer endpoints are accepting forged webhooks from anyone
  who knows the URL (no auth gate).
- Customers cannot distinguish our retried delivery from a
  replay attack — both look identical.
- Compliance reviews flag the lack of signing as a SOC2 finding
  (`file://docs/compliance/soc2-2025.md` §CC6.7).

## 2. Substance Citations

- `file://services/webhooks/dispatcher.go` — current outbound
  dispatcher; signs nothing.
- `file://services/webhooks/queue/worker.go` — retry worker;
  attempts up to 5 times with exponential backoff.
- `file://services/webhooks/queue/queue.go` §DeliveryAttempt
  — the per-attempt domain model; existing fields:
  `payload_hash`, `attempt_n`, `dispatched_at`.
- `url://stripe.com/docs/webhooks/signatures` (fetched
  2026-01-20) — Stripe's signing scheme; HMAC-SHA256 over
  `<timestamp>.<payload>`; tolerance window 5 minutes.
- `url://github.com/svix/svix-webhooks` (fetched 2026-01-20)
  — reference open-source implementation; we are NOT adopting
  Svix but reading its protocol as one well-trodden design.
- `url://datatracker.ietf.org/doc/html/draft-ietf-httpapi-signatures`
  — HTTP Message Signatures draft; alternative to the
  Stripe-style scheme.
- `file://docs/compliance/soc2-2025.md` §CC6.7 — SOC2 finding.
- `file://docs/support/recurring-questions.md` §"webhook auth"
  — four customer requests for verifiable signing.
- `decision-authority://product-lead:2026-01-19`:
  > "Webhook signing is a Q1 deliverable. Customers want it,
  > compliance needs it, the engineering work is bounded."

## 3. Constraints & Non-Negotiables

- MUST be backwards-compatible. Existing webhook consumers
  without signing capability continue to work. Signing is an
  opt-in surface gated by per-endpoint config.
  (`decision-authority://product-lead:2026-01-19`)
- MUST support key rotation without downtime. Customers MUST
  be able to verify against the previous key for a configurable
  grace window (default 7 days).
  (`decision-authority://tech-lead:2026-01-20`)
- MUST defend against replay attacks. Timestamp in the
  signature; verifier rejects payloads older than a tolerance
  window. (`decision-authority://tech-lead:2026-01-20`)
- MUST use a widely-supported algorithm. HMAC-SHA256 (industry
  standard for webhook signing per
  `url://stripe.com/docs/webhooks/signatures`,
  `url://docs.github.com/en/webhooks/using-webhooks/validating-webhook-deliveries`).
- MUST NOT require customers to install a custom verification
  library. Plain HMAC-SHA256 with documented byte-level format
  works in any language.
  (`decision-authority://product-lead:2026-01-19`)
- SHOULD provide a reference verifier snippet in
  `docs/webhooks/verifying.md` covering at least Go, Python,
  Node, Ruby. (`decision-authority://product-lead:2026-01-19`)

## 4. Approaches Considered

### 4.1 Stripe-style HMAC-SHA256 over `<timestamp>.<payload>`

- Sketch: header `X-Webhook-Signature: t=<unix>,v1=<hex-hmac>`.
  HMAC computed over `<timestamp>.<raw-payload>`. Verifier
  recomputes and constant-time-compares.
- Fit: high — matches industry standard; trivial verifier
  snippet in any language.
- Cost: bounded; new signing code path + per-endpoint key
  storage.
- Risk: low.

### 4.2 HTTP Message Signatures (IETF draft)

- Sketch: `Signature` and `Signature-Input` headers per the
  IETF draft.
- Fit: medium — more general (covers headers + body, multiple
  algorithms) but verifier snippets need more setup; library
  support is thinner than 4.1.
- Cost: higher; more surface to test.
- Risk: medium; spec still in draft. Wire format may shift.

### 4.3 Asymmetric signing (Ed25519)

- Sketch: per-endpoint Ed25519 keypair; product signs with
  private key, customer verifies with public key.
- Fit: medium-high on security (no shared secret to leak);
  lower on backward-compat (customers need crypto libs).
- Cost: higher (keypair management + public key publication
  surface).
- Risk: medium; verifier snippets are more complex than HMAC.

### 4.4 Mutual-TLS only

- Sketch: skip payload signing; require customers to verify
  the TLS client cert.
- Fit: low — customers receiving webhooks (not sending) can't
  use mTLS as a verification primitive without us being the
  client.
- Cost: low.
- Risk: high — doesn't actually solve the problem at the layer
  customers can verify.

## 5. Recommendation

**Approach 4.1 — Stripe-style HMAC-SHA256**
(`judgment://agent-synthesis`, affirmed in §7).

Rationale: 4.1 has the broadest reference precedent (Stripe,
GitHub, Shopify, Twilio all use variants of it); verifier
snippets are trivial in every major language; replay protection
is built-in via the timestamp. 4.2 is the right long-term
direction but the draft status creates rewrite risk. 4.3 is
more secure in some dimensions but higher friction for
customers — violates "MUST NOT require a custom library"
constraint. 4.4 doesn't solve the customer-facing verification
problem.

## 6. Open Questions for Owner

- [x] **Q1**: HMAC, MessageSignatures, or asymmetric? —
  Resolved 4.1 HMAC per §5.
- [x] **Q2**: Tolerance window for timestamp replay? —
  Resolved: 5 minutes (matches Stripe convention).
- [x] **Q3**: Key rotation grace window? — Resolved: 7 days
  default, configurable per endpoint
  (`decision-authority://tech-lead:2026-01-20`).
- [x] **Q4**: Where do customers fetch their signing keys? —
  Resolved: dashboard UI + API surface
  `GET /v1/webhook-endpoints/{id}/signing-keys`
  (`decision-authority://product-lead:2026-01-19`).

## 7. Owner Judgments

- `decision-authority://product-lead:2026-01-19`:
  > "Webhook signing is a Q1 deliverable. Customers want it,
  > compliance needs it, the engineering work is bounded."

  Binds: §1 framing — the Q1 deliverable directive.

- `decision-authority://tech-lead:2026-01-20`:
  > "Make key rotation work. We've burned ourselves before by
  > rolling secrets and forgetting downstream consumers."

  Binds: §3 key-rotation constraint and §6 Q3.
