---
id: add-structured-logging-auth-service
spec_id: 2026-01-15-add-structured-logging-auth-service
status: ready-for-spec
owner: owner-A
brainstormed_by: claude-opus-4-7
brainstormed_on: 2026-01-15
implies_spec_type: task
---

# Add structured logging to the auth service

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem Seed

The auth service emits ad-hoc string logs via `console.log` and
`fmt.Println` calls scattered through the request-handling path
(`file://services/auth/handlers/login.go`,
`file://services/auth/middleware/session.go`). The on-call
playbook (`file://docs/oncall/auth-incidents.md`) cites three
incidents in the past 90 days where missing structured context
(no `request_id`, no `user_id`, no `latency_ms`) extended MTTR
by ~30 minutes per incident.

Logs are ingested into a JSON-expecting pipeline
(`file://infra/logging/pipeline.yaml` — Fluent Bit → Vector →
Loki) which currently silently drops non-JSON lines. We are
losing observability on the most error-prone surface.

## 2. Substance Citations

- `file://services/auth/handlers/login.go` — primary login flow,
  6 ad-hoc log statements.
- `file://services/auth/middleware/session.go` — session
  validation, 4 ad-hoc log statements.
- `file://services/auth/internal/audit/audit.go` — already
  emits structured JSON; the pattern to extend.
- `file://infra/logging/pipeline.yaml` — Fluent Bit → Vector →
  Loki ingestion pipeline; expects newline-delimited JSON.
- `file://docs/oncall/auth-incidents.md` §"2025-Q4 incidents"
  — three incidents where MTTR was dominated by log triage,
  not fix time.
- `url://github.com/uber-go/zap` — chosen logging library
  (already a transitive dependency via `go.sum`).
- `decision-authority://product-lead:2026-01-12` — directed the
  observability tightening this quarter:
  > "Auth is the most fragile surface we operate. The on-call
  > pages too often; the diagnosis takes too long. Tighten the
  > logging this quarter."

## 3. Constraints & Non-Negotiables

- MUST NOT change log destinations or the ingestion pipeline.
  Drop-in JSON replacement only.
  (`file://infra/logging/pipeline.yaml` — the pipeline shape is
  fixed.)
- MUST preserve current log levels (INFO / WARN / ERROR) and
  semantic content; adopters see the same events at the same
  levels, just structured.
  (`decision-authority://tech-lead:2026-01-14`)
- MUST add five canonical fields to every log line:
  `request_id`, `user_id` (or `null` pre-auth), `route`,
  `latency_ms`, `outcome` (`success` | `client_error` |
  `server_error`).
  (`decision-authority://tech-lead:2026-01-14` — required-field
  set.)
- MUST NOT change the auth service's public API or behavior.
  (`decision-authority://product-lead:2026-01-12` —
  observability-only change.)
- Performance budget: ≤1% increase in p99 request latency under
  load test (`file://test/load/auth-baseline.k6.js`).

## 4. Approaches Considered

### 4.1 In-place rewrite each call site

- Sketch: walk every ad-hoc log call and rewrite to
  `zap.Logger.Info(...)` with the canonical field set.
- Fit: matches the constraint perfectly; no abstraction
  introduced.
- Cost: ~20 call sites across 6 files.
- Risk: tedious; easy to miss a site; no compile-time
  enforcement that future log calls use the structured pattern.

### 4.2 Logger wrapper with required fields

- Sketch: thin `auth-logger` package that wraps `zap` and
  requires the canonical fields as positional arguments. Each
  call site converts to `authlog.Info(ctx, "event-name", ...)`.
- Fit: high — compile-time enforcement of canonical fields via
  the wrapper signature.
- Cost: one new package + ~20 call site changes.
- Risk: introduces an abstraction layer that future devs must
  understand. Wrapper could be over-engineered.

### 4.3 Middleware-only structured wrapping

- Sketch: emit the canonical fields only at the middleware
  boundary (entry + exit per request). Leave per-call logs
  ad-hoc.
- Fit: low — misses the diagnostic context inside handlers
  where most of the on-call signal lives.
- Cost: low.
- Risk: doesn't solve the incident-MTTR problem.

## 5. Recommendation

**Approach 4.2 — logger wrapper with required fields**
(`judgment://agent-synthesis`, affirmed in §7).

Rationale: 4.1 leaves a long tail of future-regression risk
(any new log call can revert to ad-hoc). 4.2 makes the canonical
field set load-bearing in the type signature; future calls
either pass the fields or fail to compile. 4.3 misses the inside-
handler diagnostic context that drove the original MTTR
problem.

## 6. Open Questions for Owner

- [x] **Q1**: Use existing `zap` dependency or evaluate
  alternatives? — Resolved: use `zap` (already a transitive
  dep; consistent with the audit subsystem).
- [x] **Q2**: Sample rate on INFO-level logs in production? —
  Resolved: 100% INFO, 100% WARN/ERROR. Volume is acceptable
  per the ingestion pipeline budget
  (`file://infra/logging/pipeline.yaml` §capacity).
- [x] **Q3**: Backwards-compat window for any log-format
  consumers? — Resolved: none. Only consumers are the JSON
  pipeline (drops non-JSON today) and a Grafana dashboard
  (`url://grafana.internal/d/auth-overview`) which already
  expects JSON.

## 7. Owner Judgments

- `decision-authority://product-lead:2026-01-12`:
  > "Auth is the most fragile surface we operate. The on-call
  > pages too often; the diagnosis takes too long. Tighten the
  > logging this quarter."

  Binds: §1 problem framing — the quarterly directive
  authorising this work.

- `decision-authority://tech-lead:2026-01-14`:
  > "Don't ship anything that lets log calls drift back to
  > unstructured. Make the canonical fields a type-system
  > requirement."

  Binds: §5 recommendation — eliminates 4.1 as a candidate
  and forces 4.2's compile-time enforcement.
