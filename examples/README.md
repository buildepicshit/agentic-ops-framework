# Worked examples

Each subdirectory contains a complete IDEA → SPEC pair for a
realistic (non-real-product) scenario. The examples are designed
to:

- Pass `scripts/lint-spec.sh` clean (zero errors).
- Exercise every section of the matching template.
- Demonstrate the citation grammar across all prefixes.
- Show RFC 2119 normative language used correctly per
  type-specific rules (RFC keywords appear ONLY in §7 of
  Decision SPECs; everywhere normative in Contract / Task).

Adopt by:

1. Picking the closest type-match example to your work shape.
2. Copying the IDEA.md / SPEC.md into your own `specs/<id>/`
   directory.
3. Editing every placeholder. Replace the scenario; keep the
   structure.

## Available examples

| Path | Type | Scenario |
|---|---|---|
| `task-add-structured-logging/` | task | Replace ad-hoc log calls in a backend service with structured `zap` logging via a compile-time-enforced wrapper package |
| `contract-webhook-signing/` | contract | HMAC-SHA256 outbound-webhook signing + verification protocol with key rotation, grace window, and per-language reference verifier snippets |
| `decision-conventional-commits/` | decision | Adopt Conventional Commits 1.0.0 as the binding commit-message convention — 4-candidate trade-off, RFC 2119 keywords scoped to §7 Decision Statement only, full Locks + Reversal Plan |
| `fastpath-fix-readme-typo/` | fastpath | Owner-authorised one-character typo fix; single-file capture-after SPEC at `status: closed` in the same commit as the work; demonstrates the lightweight-ceremony exit valve |
| `contract-webhook-signing/tasks/` | TASK.md | Decomposition of the webhook-signing Contract into two dependent slices (T-01 signer+keystore, T-02 dispatcher integration); demonstrates per-slice model lane assignment, dependency graph, write-scope discipline |

## TASK.md decomposition

After a Contract or Task SPEC reaches `approved` and is owner-
flipped to `decomposed`, per-slice TASK.md artefacts are
emitted into the SPEC's `tasks/` directory. Each TASK.md is a
1:1 contract for one tracker issue and one isolated workspace
run. The parent SPEC remains the immutable execution authority.

The TASKs under `contract-webhook-signing/tasks/` show:

- **Different model families per slice** — T-01 routes to
  `gpt-5` primary + `claude-opus-4-7` cross-validation; T-02
  reverses the lanes. Cross-family discipline is enforced
  per-slice, not per-SPEC.
- **Explicit dependencies** — T-02 declares
  `deps: [T-01-signer-and-keystore]` so the dispatcher can
  rely on the signer's exported API.
- **Disjoint write scope** — T-01 owns `internal/signing/` +
  `internal/keystore/`; T-02 owns `dispatcher.go` +
  `queue/queue.go`. Parallel writers cannot collide.
- **Bounded scope** — each TASK.md names exactly which files
  the worker MAY edit and which are read-only context.

## Verifying an example lints clean

From the framework root:

```bash
bash scripts/lint-spec.sh examples/<example-name>/IDEA.md
bash scripts/lint-spec.sh examples/<example-name>/SPEC.md
```

Both should exit 0 with zero errors. Lowercase RFC 2119 hits in
non-normative sections are advisory only and may appear without
indicating a failure.
