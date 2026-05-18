# Cross-validation lane assignment

Extracted from
`file://agents/skills/approved-spec-decomposition/SKILL.md` per
the references/ progressive-disclosure convention (SE1 capture
in
`file://specs/2026-05-15-inbox-channel-and-skill-references-pattern/SPEC_EVIDENCE.md`).

## When to read this

Fires only when:
- you are emitting TASK.md slices during decomposition AND
- you are choosing the per-slice `cross_validation_lane` model
  family (BLOCKING rule per the parent skill).

For routine decomposition orchestration, read the spine of
`file://agents/skills/approved-spec-decomposition/SKILL.md`;
this reference covers only the cross-validation lane mechanics.

## Pattern

Every TASK.md MUST name a `cross_validation_lane` of a different
model family from `model_route`. The cross-validation review
runs between `in-progress` and `in-review`:

1. Primary agent finishes implementation; opens PR.
2. Cross-validation agent (different family) is dispatched as a
   subagent or as a separate tracker-issue review run, scoped
   to:
   - Read-only access to the diff and the parent SPEC.md.
   - Output: findings list ordered by severity, file/line
     citations, no edits.
3. Findings are recorded in the workpad `Validation` section.
4. Primary agent addresses findings (code/test/docs) or posts
   explicit pushback per the PR feedback sweep protocol in
   `file://agents/templates/WORKFLOW.body.md` "PR feedback
   sweep protocol".
5. Only after cross-validation findings are resolved does the
   task flip `in-progress → in-review`.

## Skill responsibilities

The `code-review` skill at
`file://agents/skills/code-review/SKILL.md` and the
`spec-review` skill at
`file://agents/skills/spec-review/SKILL.md` are the executors
of cross-validation; this skill (`approved-spec-decomposition`)
names the lane.

## Fallback when cross-family dispatch is impossible

Per SE2 (capture in
`file://specs/2026-05-17-contract-corpus-retrospective-audit/SPEC_EVIDENCE.md`),
when the execution context cannot dispatch cross-family (e.g.
Claude Code only spawns Claude-family subagents), the honest
path is same-family proxy + clearly-labelled deferral. This
fallback applies to TASK.md execution too; strict cross-family
pass deferred to owner-triggered external runner.
