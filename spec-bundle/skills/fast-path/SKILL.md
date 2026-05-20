---
name: fast-path
description: "Use when the owner has explicitly authorised a small, single-component, reversible change that does not warrant full IDEA→SPEC→review→approve ceremony. Skips the 13-phase lifecycle in favour of a single capture-after SPEC at status: closed in the same commit as the work. ONLY valid when ALL thresholds in this skill's 'Thresholds' section are met; otherwise escalate to task/contract/decision."
---

# Fast-Path SPEC

The fast-path is the recognised lightweight ceremony for **small,
single-component, reversible work under explicit owner directive**.
It exists to keep the spec-first discipline applicable to tiny
non-trivial work without forcing a 13-phase song-and-dance for a
one-file fix.

Authority: `judgment://agent-synthesis` (the
framework-refresh-lightweight-ceremony Decision);
`file://spec-bundle/templates/SPEC.fastpath.template.md`.

## Thresholds (ALL must be true)

Fast-path is VALID only when EVERY condition below holds. If any
one fails, escalate to task / contract / decision SPEC via the
standard `/idea-capture` → `/author-spec` flow.

| Threshold | Limit |
|---|---|
| Files changed | ≤ 1 |
| Lines changed (insert + delete) | ≤ 50 |
| Components touched | 1 (single skill / script / hook / template) |
| Public-contract impact | None |
| Persisted-state impact | None |
| Reversibility | One revert commit fully restores prior state |
| Owner directive | Explicit, current-session, `owner://transcript-<date>` |
| Cross-session compounding risk | None (work completes in this session) |

These thresholds are **objective**. Lint enforces the line count
and file count by inspecting the commit diff at SPEC-creation
time. The agent does not get to vibe-check.

## Procedure

1. Owner directs the change explicitly. Capture the verbatim
   directive — you'll cite it.
2. Perform the work.
3. Run scope-relevant verification (the gates `acceptance_commands`
   would otherwise have been; lint-spec on any SPEC files, hook
   tests if hooks touched, etc.).
4. Author `specs/<id>/SPEC.md` from
   `file://spec-bundle/templates/SPEC.fastpath.template.md`. Status:
   `closed` from the start.
5. Commit work + SPEC + SPEC_EVIDENCE.md (optional for fast-path —
   only if §5.2 surfaces a genuine residual or evidence candidate)
   in a single commit. Message references the SPEC id.
6. Push.

There is **no IDEA**, **no blocking review gate**, **no
decomposition**, **no cross-validation lane**. Owner approval is
the directive captured in §3 of the SPEC.

## When NOT to use fast-path

If you find yourself doing any of these, you are no longer on the
fast-path — back out and run the full v1 procedure:

- Editing > 1 file.
- Touching code that other code or another agent depends on.
- Adding a new public surface (CLI command, slash-command, hook,
  skill, SPEC type, audit script, template).
- Changing the shape of a persisted artefact (SPEC.md, TASK.md,
  config, manifest).
- Crossing repo boundaries.
- The change requires owner judgment mid-execution (not just up
  front).

The fast-path is for typo fixes, single-line policy clarifications,
trivial unblock work, and similar. It is not a procedural escape
hatch for laziness.

## Hard rules

- Fast-path SPEC files MUST lint-pass under
  `file://scripts/lint-spec.sh` fastpath mode.
- Fast-path SPECs MUST cite the authorising owner directive
  verbatim. Memory does not satisfy the citation.
- Fast-path SPECs MUST NOT carry residual risks that warrant
  spec-evidence governance. If they do, the work wasn't fast-path
  material — promote to a task SPEC retroactively.
- A fast-path SPEC MUST NOT be reused as a precedent to skip
  ceremony on larger work. Each fast-path is its own authorisation.
- The same agent MUST NOT chain fast-path SPECs to circumvent the
  ≤50-lines threshold across commits. The threshold applies per
  fast-path, and the cross-session-compounding-risk threshold
  rules out chained micro-changes that should have been one
  larger SPEC.
