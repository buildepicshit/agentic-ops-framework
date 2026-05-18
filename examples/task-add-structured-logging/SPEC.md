---
id: 2026-01-15-add-structured-logging-auth-service
status: approved
type: task
owner: owner-A
repo: your-policy-repo
branch_policy: worktree-preferred
risk: low
requires_network: false
requires_secrets: []
acceptance_commands:
  - go test ./services/auth/...
  - go test -run TestStructuredLogger ./services/auth/internal/authlog/...
  - go vet ./services/auth/...
  - bash test/load/run-baseline.sh
ideated_in: examples/task-add-structured-logging/IDEA.md
---

# SPEC: Add structured logging to the auth service

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals. RFC 2119 keywords
in this Task SPEC appear in Desired Behavior, Acceptance Criteria,
Test Plan, and Safety / Scope Invariants sections.

## 1. Problem

The auth service emits ad-hoc string logs via `fmt.Println` and
`log.Printf` calls scattered through the request-handling path
(`file://services/auth/handlers/login.go` lines 47, 89, 134;
`file://services/auth/middleware/session.go` lines 22, 56;
plus 14 similar sites across the service). The on-call
playbook (`file://docs/oncall/auth-incidents.md` §"2025-Q4")
cites three incidents where missing structured context extended
MTTR by ~30 minutes each. The ingestion pipeline
(`file://infra/logging/pipeline.yaml`) silently drops non-JSON
lines, so the diagnostic value is being lost upstream.

## 2. North Star / Product Promise

Operators on call SHOULD be able to filter the logs by
`request_id` and reconstruct the auth trace for any single
request without `grep`-ing prose. The Grafana dashboard
(`url://grafana.internal/d/auth-overview`) SHOULD show p99
latency broken down by `route` and `outcome` within 24h of
this SPEC landing.

## 3. Goals

- Replace ad-hoc log calls in the auth service with structured
  `zap`-backed calls.
- Enforce the canonical five-field set
  (`request_id`, `user_id`, `route`, `latency_ms`, `outcome`)
  at compile time via a wrapper package.
- Stay within the ≤1% p99 latency budget under the existing
  load test.

## 4. Non-Goals

- Restructuring the ingestion pipeline. `file://infra/logging/pipeline.yaml`
  is unchanged.
- Adding new log destinations (Sentry, Datadog, OTel etc.).
- Restructuring services other than `services/auth/`. The
  pattern MAY be adopted by other services later; that's their
  own SPEC.
- Changing log level semantics (INFO / WARN / ERROR retain
  current usage).

## 5. Current System Facts

- `cmd://grep -rn "fmt.Println\|log.Printf" services/auth/`
  → 20 ad-hoc log statements across 6 files.
- `cmd://grep -n "zap.Logger" services/auth/internal/audit/audit.go`
  → 1 file already uses `zap`; the pattern is internally
  available.
- `cmd://go list -m go.uber.org/zap`
  → `go.uber.org/zap v1.27.0` — already a transitive dependency.
- `file://infra/logging/pipeline.yaml` §source_filters
  → drops `^[^{]` lines (silent), confirming non-JSON loss.
- `file://test/load/auth-baseline.k6.js`
  → exists; current p99 latency baseline is captured in
  `file://test/load/auth-baseline.results.json`.

## 6. Authority Map

Active authority:

- `examples/task-add-structured-logging/IDEA.md` — producing
  IDEA at `ready-for-spec` with §6 resolved.
- `decision-authority://product-lead:2026-01-12` — observability
  tightening directive.
- `decision-authority://tech-lead:2026-01-14` — compile-time
  enforcement directive.

Stale, superseded, or evidence-only sources:

- N/A.

Owner decisions required before implementation:

- [x] All resolved in IDEA §6.

## 7. Code/Docs Reality Check

| Surface | Current claim | Observed reality | Required action |
|---|---|---|---|
| `file://services/auth/README.md` §Logging | "Logs are written via Go stdlib `log`." | Mixed: stdlib `log`, `fmt.Println`, and `zap` co-exist | rewrite §Logging to describe the canonical `authlog` package |
| `file://docs/oncall/auth-incidents.md` §Playbook | "Search logs for the user's email" | Email is in unstructured prose today; will move into `user_id` field | update playbook to use `user_id` filter |
| `file://infra/logging/pipeline.yaml` | drops non-JSON silently | unchanged | none (intentional) |

## 8. Desired Behavior

The implementation MUST create a new package at
`file://services/auth/internal/authlog/authlog.go` exporting:

- `type Logger struct` wrapping a `*zap.Logger`.
- `func New(level zapcore.Level) *Logger` constructor returning
  a configured logger writing JSON to stdout.
- `func (l *Logger) Info(ctx, event, ...Field)`,
  `func (l *Logger) Warn(ctx, event, ...Field)`,
  `func (l *Logger) Error(ctx, event, err, ...Field)`.
- `func WithRequestID(ctx, id) ctx` and matching `WithUserID`,
  `WithRoute`, `WithOutcome` helpers writing into the request
  context.
- `Field` type aliasing `zap.Field` so call sites import only
  `authlog`.

The implementation MUST require the five canonical fields at
the type system level: each public log method MUST take
`ctx context.Context` first; the package MUST refuse to emit
a log line whose context lacks `request_id`, `route`, or
`outcome` (returning a programmer-error via panic in test
builds, log-as-warning in release builds).

The implementation MUST replace all 20 ad-hoc log calls in
`services/auth/` with `authlog.*` equivalents, preserving the
current log level and semantic message.

The implementation MUST add a middleware
(`file://services/auth/middleware/logging.go`) that injects
`request_id` (from `X-Request-ID` header or generated UUIDv7
fallback), `route` (from the matched route), and `outcome`
(set in the response writer wrapper) into the request context.

The implementation SHOULD NOT introduce new dependencies
beyond what's transitively present.

## 9. Domain Model / Contract

### 9.1 Log line schema (JSON)

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `level` | string | REQUIRED | `info` \| `warn` \| `error` | lowercase per `zap` convention |
| `timestamp` | RFC3339 string | REQUIRED | ISO-8601 with milliseconds | UTC |
| `event` | string | REQUIRED | snake_case verb-noun | e.g. `login_attempted` |
| `request_id` | UUID string | REQUIRED | UUIDv7 | from header or generated |
| `user_id` | UUID string \| null | REQUIRED | UUIDv7 or `null` | `null` permitted only on pre-auth events (`login_attempted`, `signup_started`) |
| `route` | string | REQUIRED | matched route pattern | e.g. `/api/v1/login` |
| `latency_ms` | integer | REQUIRED | ≥0 | request-scoped; updated by middleware on response |
| `outcome` | string | REQUIRED | `success` \| `client_error` \| `server_error` | set by response-writer wrapper |
| `err` | string | REQUIRED on `level: error` | error string | use `err.Error()`; structured detail via additional fields |

Invariants:

- The schema MUST be backwards-compatible. Adding a field is
  permitted; removing or renaming an existing field requires a
  new SPEC.
- `request_id` MUST be unique per request across the auth
  service instance.

## 10. Interfaces and Files

Expected touch points:

- `file://services/auth/internal/authlog/authlog.go` (NEW).
- `file://services/auth/internal/authlog/authlog_test.go` (NEW).
- `file://services/auth/middleware/logging.go` (NEW).
- `file://services/auth/middleware/logging_test.go` (NEW).
- `file://services/auth/handlers/login.go` (MODIFIED — 6 sites).
- `file://services/auth/handlers/signup.go` (MODIFIED — 3 sites).
- `file://services/auth/handlers/logout.go` (MODIFIED — 2 sites).
- `file://services/auth/middleware/session.go` (MODIFIED — 4 sites).
- `file://services/auth/internal/audit/audit.go` (MODIFIED — 2 sites; align to `authlog` shape).
- `file://services/auth/internal/oauth/google.go` (MODIFIED — 3 sites).
- `file://services/auth/README.md` (MODIFIED — §Logging rewritten).
- `file://docs/oncall/auth-incidents.md` (MODIFIED — playbook updated to `user_id` filter).

Public interfaces affected:

- New `authlog` package — internal to `services/auth/`. Not
  exported.
- HTTP API surface: unchanged.

## 11. Execution Plan

1. Author `authlog` package + tests. Verify five-field
   enforcement via unit tests (programmer-error on missing
   fields in test mode).
2. Author `middleware/logging.go` + test. Verify it injects
   the request-scoped fields and times the request.
3. Wire middleware into the router
   (`file://services/auth/cmd/server/main.go`).
4. Rewrite the 20 ad-hoc log sites. Per file, run package tests
   after each change.
5. Update `services/auth/README.md` §Logging and
   `docs/oncall/auth-incidents.md` §Playbook.
6. Run `cmd://bash test/load/run-baseline.sh` and compare p99
   latency to `file://test/load/auth-baseline.results.json`.
   FAIL the SPEC if p99 increased >1%.
7. Verify Grafana dashboard renders the new fields by
   triggering a manual load run + screenshot inspection.

## 12. Safety / Scope Invariants

- The auth HTTP API surface MUST NOT change. No new routes; no
  removed routes; no changed response shapes.
- The ingestion pipeline (`file://infra/logging/pipeline.yaml`)
  MUST NOT be modified by this SPEC.
- Files outside `services/auth/`, `test/load/`, and the two
  docs explicitly listed in §10 MUST NOT be touched.
- The new `authlog` package MUST be `internal/`. Not exported
  to other services in this SPEC.
- Destructive actions REQUIRE explicit owner approval.

## 13. Test Plan

Commands (each pairs 1:1 with an Acceptance Criterion in §14): <!-- lint-ok: no-citation -->

```bash
go test ./services/auth/...
go test -run TestStructuredLogger ./services/auth/internal/authlog/...
go test -run TestLoggingMiddleware ./services/auth/middleware/...
go vet ./services/auth/...
bash test/load/run-baseline.sh
grep -rE 'fmt\.Println|log\.Printf' services/auth/ | wc -l  # expect 0
```

Manual checks: <!-- lint-ok: no-citation -->

- Grafana dashboard
  (`url://grafana.internal/d/auth-overview`) shows the new
  fields after a manual load run.
- Sample a `request_id` from the test load; `loki` query
  `{service="auth", request_id="<id>"}` returns the full trace.
  (`url://grafana.internal/explore?datasource=loki`)

## 14. Acceptance Criteria

- [ ] AC-1: `services/auth/internal/authlog/authlog.go` exists
  with the API shape in §8 — verified by §13 first command +
  manual inspection.
- [ ] AC-2: Five-field enforcement is compile-time on the
  public log methods (missing field → call site doesn't compile)
  — verified by §13 second command (which includes a
  negative-build test).
- [ ] AC-3: All 20 ad-hoc log sites in `services/auth/` replaced
  with `authlog.*` — verified by §13 `grep` returning 0.
- [ ] AC-4: Middleware injects `request_id`, `route`, `outcome`
  into context — verified by §13 third command.
- [ ] AC-5: `go vet` passes on the auth service — verified by
  §13 fourth command.
- [ ] AC-6: p99 latency under load is within 1% of baseline —
  verified by §13 fifth command + comparison to
  `file://test/load/auth-baseline.results.json`.
- [ ] AC-7: `services/auth/README.md` §Logging and
  `docs/oncall/auth-incidents.md` §Playbook updated — manual
  inspection.
- [ ] AC-8: Grafana dashboard renders new fields — manual
  check after a load run.
- [ ] AC-9: No unrelated working-tree changes at completion.
- [ ] AC-10: Completion Report §17 includes verification
  output.

## 15. Rollback Plan

Revert the commits in reverse order:

1. Revert middleware wiring in
   `file://services/auth/cmd/server/main.go`.
2. Revert per-file `authlog.*` → `fmt.Println` / `log.Printf`
   conversions (or use `git revert` on the affected commits).
3. Delete `file://services/auth/internal/authlog/` package.
4. Revert docs updates.

The ingestion pipeline drops non-JSON silently, so reverted
state restores prior behavior without further infra
intervention.

## 16. Open Questions

- [x] All design questions resolved in the IDEA (§6 Q1-Q3).

## 17. Completion Report

(to be filled by the executor — see template sections 17.1
through 17.5)

### 17.1 Files changed

(to be filled)

### 17.2 Commands run

(to be filled — paste relevant excerpts of `acceptance_commands` outputs)

### 17.3 Verification result

(to be filled)

### 17.4 Residual risk

(to be filled)

### 17.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
