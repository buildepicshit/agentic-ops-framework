---
name: autonomous-issue-dispatch
description: "Use to prepare a TASK.md slice for autonomous dispatch by an issue-tracker-driven runner (OpenAI Symphony, equivalent CLI runners, or your in-house dispatcher). Checks WORKFLOW.md fleet-body shape, issue eligibility, per-issue workspace isolation, runner settings, and observability expectations. Do not use for interactive sessions — interactive agents do not require dispatcher binding."
---

# Autonomous Issue Dispatch

Use this skill to prepare and audit a TASK.md slice for
dispatch by an autonomous runner that picks up tracker issues
and executes against them in isolated per-issue workspaces.
The pattern is runner-agnostic; OpenAI Symphony is the
canonical reference implementation, and there are equivalent
CLI runners and in-house dispatchers.

## When to use

- An approved SPEC has been decomposed into TASK.md slices
  and one or more slices should run autonomously (without an
  owner in the loop).
- You're standing up a new fleet repo for autonomous dispatch
  and need to validate its `WORKFLOW.md` against the runner's
  expected schema.
- You're auditing whether an in-flight dispatch run is
  configured correctly (per-issue workspace isolation, hook
  bindings, observability surface).

Do not use this skill for:

- Owner-led interactive work — interactive agents read
  `WORKFLOW.md` Section 1 (Universal) only; they don't need
  the dispatch surface.
- Cross-family review dispatch — that's owner-led-parallel-
  worktrees territory, not autonomous-issue-dispatch.
- Configuring the runner itself — the runner's own docs are
  authority for its CLI flags and config schema; this skill
  bridges the framework's TASK.md contract to whichever
  runner you use.

## Pattern

```
[tracker]                          [autonomous runner]
   │                                       │
   │ issue created (or marked ready)        │
   │                                       │
   │ ────────── poll / webhook ──────────► │
   │                                       │
   │                                       │ resolve issue → TASK.md anchor
   │                                       │ create per-issue workspace
   │                                       │ checkout branch
   │                                       │ run agent with bounded scope
   │                                       │ commit + push + open PR
   │                                       │
   │ ◄────── PR + workpad comment ───────  │
   │                                       │
```

The runner's three load-bearing primitives:

- **Per-issue workspace isolation** — each tracker issue
  spawns a fresh git worktree or container. State from one
  issue cannot leak into another.
- **Workpad comment** — the runner appends an execution
  journal to the tracker issue (or an external sink) as it
  proceeds. Owner can read the journal without joining the
  session.
- **PR-as-handoff** — when the runner finishes, the PR is the
  human review surface. The runner does not merge.

## Eligibility

A TASK.md slice MUST satisfy these to be dispatch-eligible:

- `parent_spec` is at `status: decomposed` (parent owner has
  flipped from `approved`).
- `mode: AFK` in front-matter (the slice has been judged
  safe for unattended execution).
- `acceptance_commands` is non-empty and each command is
  runnable in the dispatcher's environment.
- `cross_validation_lane` is set to a different family from
  `model_route`. The runner respects this.
- `tracker_issue` is set OR the runner is configured to
  create the issue on first dispatch.
- The dependency graph (`deps`) is satisfied — all upstream
  TASK.md slices are at `done`.

If any condition fails, mark `mode: HITL` and escalate to
owner-led execution.

## WORKFLOW.md fleet-body shape

The dispatcher reads `WORKFLOW.md` at each repo root. The
canonical shape:

```yaml
---
tracker:
  type: <linear | github-issues | jira | ...>
  poll_interval_s: <integer>
polling:
  state_filter: <enum>  # e.g., "ready-for-dispatch"
workspace:
  base: <path>          # where per-issue worktrees live
  cleanup_on_done: <bool>
hooks:
  pre-start: <path>     # framework's preflight
  pre-commit: <path>    # framework's lint-spec gate
  post-merge: <path>    # framework's spec-evidence reminder
agent:
  primary: <model-id>
  fallback: <model-id>
codex: ...              # or whichever runner's config block
---

# <repo name> dispatch

<per-repo intro>

<!-- canonical body from your framework template -->
```

The runner consumes the YAML; the markdown body is the
universal-mode WORKFLOW shared across all agents in the
repo (interactive + dispatched).

## Procedure

1. **Verify the TASK.md is eligible** per the criteria above.
2. **Verify WORKFLOW.md** has the dispatcher YAML and a
   per-repo intro. If absent, the runner cannot pick up the
   issue.
3. **Verify hooks are bound** at the runner's expected
   lifecycle points. The framework's lint-spec gate MUST fire
   on each commit; the spec-evidence reminder MUST fire on
   `done`.
4. **Verify observability**: the runner's workpad comment
   format matches the framework's session-journal entry shape
   so post-hoc auditors can compare.
5. **Verify the dispatch lane** matches the TASK.md's
   `model_route`; the runner's fallback lane is set; the
   cross-validation lane is configured to fire pre-merge.
6. **Hand off**: mark the tracker issue ready (per the
   `polling.state_filter`); the runner picks it up on the
   next poll tick.

## Safety invariants

- The runner MUST run in a per-issue isolated workspace.
  Shared workspaces leak state.
- The runner MUST NOT push to the protected branch.
  Always opens a PR.
- The runner MUST emit a workpad comment on each significant
  step (resolve, start, commit, PR-open, error). Silent
  runners are unauditable.
- The cross-validation lane MUST run before the runner
  declares the slice ready for human review.
- The runner MUST NOT modify the parent SPEC.md or this
  TASK.md (except for the TASK.md's Evidence section per
  the framework's per-slice contract).

## Hard rules

- Do not dispatch a TASK.md while its parent SPEC is at
  `status: approved` — wait for `decomposed`.
- Do not dispatch a TASK.md with `mode: HITL`. Mode flip is
  owner-only.
- Do not dispatch a TASK.md whose `deps` aren't satisfied.
- Do not run multiple write-capable runners against the same
  TASK.md concurrently.

## Tooling notes

- **OpenAI Symphony** (`url://github.com/openai/symphony`) —
  the canonical reference. Apache-2.0; framework-agnostic
  spec at the repo root.
- Equivalent in-house dispatchers exist; the contract is the
  WORKFLOW.md shape + the per-issue workspace isolation +
  the workpad observability surface, not any specific
  runner's CLI.
