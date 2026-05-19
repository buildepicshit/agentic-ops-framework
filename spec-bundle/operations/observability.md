# Operations — Observability

Three-tier observability per the Symphony §13 pattern
(`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/symphony-spec.md`
§3 — transferable building block 9).

## Tier 1: REQUIRED logging

The framework's tooling MUST log (stdout / stderr) for
every gate invocation:

| Gate | Required output |
|---|---|
| `scripts/lint-spec.sh <target>` | One-line summary block on stdout (target, type, citation count, errors, warnings) + per-error file:line on stderr |
| `scripts/validate-skill-frontmatter.sh` | One-line PASS/FAIL summary on stdout + per-failure detail on stderr |
| `scripts/validate-manifest.sh` | One-line PASS summary OR enumerated issue list on stderr |
| `tests/hooks/run-tests.sh` | Per-test PASS/FAIL line + final summary |
| Each hook | Block reason on stderr when rejecting; silence when allowing |

This logging is what CI captures and what local agents /
users see directly. No structured-log format is mandated
at v2.0 (text/plain stdout/stderr is sufficient).

## Tier 2: RECOMMENDED snapshot

For long-running session-style work (an agent operating
across many turns), the framework's
`hooks/session-start-context.sh` emits a session-init
context block on session start. This snapshot includes:

- Repo identifier + current branch.
- Active SPEC slug + status.
- Recent commits (last 5).
- Pointers to STATUS.md and AGENTS.md.

The snapshot pattern is per the Symphony §13 pattern
"recommended snapshot" tier; adopters MAY add their own
snapshot hooks for additional context.

## Tier 3: OPTIONAL HTTP / external

The framework does NOT ship an HTTP observability
endpoint. Adopters who run the framework's discipline
inside a hosted CI/CD or workflow runner MAY wire CI
artifact uploads + run metadata to their tracker /
dashboard / alerting infrastructure. This is adopter-
specific tooling; the framework provides no contract.

## Observability for agent runs

When an agent is dispatched against a TASK.md slice
(via `autonomous-issue-dispatch` patterns or owner-led
direct invocation), the observability surface is:

- The agent's session log (per Claude Code / Codex /
  Gemini's runner conventions).
- The TASK.md's §6 Evidence section (filled by the
  executor).
- The parent SPEC's §17 Completion Report (filled at
  verification).
- Commit message bodies (each non-trivial commit
  documents what changed and why).

Adopters who want structured cross-session observability
should consider the `autonomous-issue-dispatch` skill's
WORKFLOW.md contract pattern + tracker integration (K-5
in `../customization/contract.md`).
