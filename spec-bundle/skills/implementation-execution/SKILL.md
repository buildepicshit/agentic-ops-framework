---
name: implementation-execution
description: "Use when implementing an approved SPEC.md or a TASK.md slice (after decomposition). Keeps edits scoped to approved scope, preserves user work, updates directly coupled tests/docs, surfaces (does not silently swallow) scope drift. Requires SPEC at status: approved (owner-set) or later. Do not implement against draft / needs-revision / approved-pending-owner specs."
---

# Implementation Execution

Use only after a spec is approved by the owner or controlling workflow.

## Steps

1. Re-read the approved `SPEC.md`.
2. Re-read the repo `AGENTS.md` and relevant docs.
3. Confirm branch/worktree state with `git status --short --branch`.
4. Edit only files named by the spec or directly required by the change.
5. Use `diagnosis` before fixing unclear failures, flaky behavior,
   regressions, broken commands, or unknown root causes.
6. Use `tdd` for behavior changes when a focused automated or scripted
   check can express the desired behavior without exceeding spec scope.
7. For substantial approved specs, use `approved-spec-decomposition` to
   split vertical HITL/AFK slices before dispatching workers. Slices
   remain subordinate to SPEC.md.
8. Add or update tests before or with production changes when behavior
   changes and the approved spec's verification method supports it.
9. Keep unrelated refactors out of scope.
10. Run the spec acceptance commands.
11. Prepare the completion report requested by the spec.

## Stop Conditions

- New facts materially change scope.
- Required files contain unrelated local changes that make safe editing
  ambiguous.
- Verification requires unavailable secrets or infrastructure.
- The spec's acceptance criteria are not testable.
- The spec requires the agent to invent product, design, quality, release, or
  acceptance criteria.
- Diagnosis shows the root cause requires behavior outside approved scope.
- Decomposition cannot produce bounded ownership or clear acceptance
  evidence for a worker slice.

## Hard Rules

- Preserve unrelated user changes.
- Do not silently expand scope.
- Do not convert agent opinions into implementation authority.
- Do not bypass hooks, CI, or verification gates.
- Do not claim completion without fresh verification evidence.
