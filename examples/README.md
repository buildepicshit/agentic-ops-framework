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

More examples (Decision SPEC, Fastpath SPEC, TASK.md
decomposition) will land in v1.0.

## Verifying an example lints clean

From the framework root:

```bash
bash scripts/lint-spec.sh examples/<example-name>/IDEA.md
bash scripts/lint-spec.sh examples/<example-name>/SPEC.md
```

Both should exit 0 with zero errors. Lowercase RFC 2119 hits in
non-normative sections are advisory only and may appear without
indicating a failure.
