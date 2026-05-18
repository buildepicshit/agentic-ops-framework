---
name: approved-spec-decomposition
description: "BLOCKING. Use after a SPEC.md is approved and before in-execution to emit one TASK.md per executable slice into specs/<id>/tasks/. Each TASK.md binds a tracker issue 1:1, carries primary/cross-validation/verification model lanes, and gates the parent SPEC's transition approved -> decomposed -> in-execution. Tasks become the source-of-truth dispatchable units; agents and autonomous dispatch runners anchor on them."
---

# Approved Spec Decomposition

This skill is the **authoritative bridge artefact** between an
approved SPEC and dispatchable work. It runs after
`status: approved` and before `status: in-execution`.

It is no longer a planning aid. It produces durable TASK.md files
that dispatch runners + subagents execute against. The
parent SPEC remains the immutable authority (Completion Report
aside); the TASK.md files are the executable contracts for each
slice and the 1:1 binding to tracker issues.

## When to use

- A SPEC.md has front-matter `status: approved` and contains a §11
  Execution Plan (Task SPEC) or §11 / §14 / §15 Implementation
  Checklist (Contract SPEC) that names ≥ 2 distinct slices, OR
- The owner has directed decomposition for parallel execution per
  `file://agents/MODEL_ROUTING.md` "Routing Matrix" (multi-agent
  coding row).

Skip when:

- The SPEC is small enough to execute as one slice; in that case
  emit a single TASK.md and proceed.
- The SPEC is a Decision SPEC (Decision SPECs do not have
  implementation phases; their cascade is by id-citation per
  `file://specs/2026-05-02-studio-principle-ai/SPEC_EVIDENCE.md` §3).

## Preconditions

REFUSE to proceed unless:

1. `<spec_path>` exists with parseable front-matter.
2. `status: approved` (set by owner per
   `file://agents/specs/SPEC.schema.md` §1.3).
3. Acceptance commands present, OR explicit explanation of empty
   list in §12 Acceptance Criteria.
4. Open Questions resolved.
5. Write ownership can be bounded (each slice has disjoint
   `owned_files` per
   `file://specs/2026-05-04-agent-parallelism-and-model-routing-v2/SPEC.md`
   §6.1.1).

If any precondition fails, stop and surface the exact blocker with a
file/line citation. Do NOT emit TASK.md files.

## Procedure

1. Read the approved SPEC end-to-end.
2. Read `file://agents/MODEL_ROUTING.md` "Routing Matrix" to map task
   classes to model lanes.
3. Read the parent SPEC's §11 Execution Plan (Task) or §11/§14/§15
   (Contract). Each slice in the plan becomes one TASK.md.
4. For each slice, copy `file://agents/specs/TASK.template.md` to
   `specs/<parent_spec_id>/tasks/T-NN-<slug>.md` and fill in:
   - `id` — `T-NN-<slug>` matching the file name.
   - `parent_spec` — the SPEC's id.
   - `status` — `todo`.
   - `owner` — `unassigned`.
   - `model_route` — primary lane from your studio's model-
     routing policy for the slice's `task_class` (research,
     implementation, code-review, verification, docs, planning).
     Pick one frontier-grade model from the family best suited
     to the task class.
   - `cross_validation_lane` — DIFFERENT family from
     `model_route`. The primary executes the work; the
     cross-validation lane reads the diff and produces an
     independent review. Different-family is the load-bearing
     primitive — same-family review is a permissible fallback
     only with explicit labelling (see
     `references/cross-validation-lanes.md`).
   - `verification_lane` — same family as primary for mechanical
     verification (lint, test); different family for behavioral
     verification (does the change actually do what the SPEC says).
   - `mode` — `AFK` only when AFK Eligibility (below) is satisfied;
     otherwise `HITL`.
   - `deps` — list of T-IDs that MUST reach `done` before this one
     starts.
   - `write_scope` — `disjoint` for parallel slices; `overlap`
     blocks parallel dispatch and requires a serial integration
     order.
   - `parallelism_evaluated: true`.
   - `acceptance_commands` — subset of the parent SPEC's
     acceptance_commands that prove THIS slice plus any task-local
     verification.
5. Author each TASK.md's body sections per the template:
   - §1 Goal
   - §2 Parent SPEC anchor (cite the SPEC section this slice
     implements)
   - §3 Scope (owned files, read context, out-of-scope)
   - §4 Model dispatch (lane table)
   - §5 Acceptance (commands + criteria)
   - §6 Evidence (left blank for executor)
   - §7 Stop conditions
   - §8 tracker binding (filled when dispatched)
6. Compute integration order. If any slice has `deps`, it cannot
   start before its dependencies reach `done`. Record the
   topological order in the parent SPEC's §17 Completion Report
   (Task) or §19 Completion Report (Contract) as a Decomposition
   Index that lists `T-NN: <title>` in execution order.
7. Run `cmd://bash agents/scripts/lint-spec.sh
   specs/<parent_spec_id>/SPEC.md` and confirm exit 0.
8. Surface the decomposition to the owner with the Decomposition
   Index and the Parallelism Decision Record (Decision: `fanout` |
   `local`; Rationale: …; Lanes: …) per
   `file://specs/2026-05-04-agent-parallelism-and-model-routing-v2/SPEC.md`
   §8.1.
9. Owner reviews the decomposition. **One-shot approval**, not
   per-task. On owner directive, flip the parent SPEC's status
   `approved → decomposed`. The skill MUST NOT set the status; only
   the owner does (extends the existing owner-only `approved` /
   `closed` rule from
   `file://agents/specs/SPEC.schema.md` §1.3).
10. After owner approval, agents may dispatch tasks. Each TASK.md's
    tracker issue is created (manually or via tooling); the task's
    `tracker_issue` field is filled. the dispatcher picks up the issue and
    runs the per-issue workspace.

## AFK Eligibility (per task)

Mark a task `AFK` only when ALL of:

- `owned_files` are bounded and disjoint from other AFK slices.
- `acceptance_commands` are explicit and mechanically verifiable.
- No mid-slice owner judgment is required.
- Agent can stop safely on ambiguity (escalate to workpad blocker).
- The cross-validation lane is configured and a different family
  from primary.

Otherwise mark `HITL`.

## Cross-validation pattern

Every TASK.md MUST name a `cross_validation_lane` of a different
model family from `model_route`. The lane runs between
`in-progress` and `in-review`. Procedure, executor skills, and
the same-family-proxy fallback (SE2) when cross-family dispatch
is unavailable:
[`references/cross-validation-lanes.md`](references/cross-validation-lanes.md).

## Hard Rules

- Do not decompose unapproved specs.
- Do not emit TASK.md without a `cross_validation_lane` of a
  different model family from `model_route`.
- Do not assign overlapping `write_scope` to parallel `AFK` tasks
  without root-manager integration control and serial integration
  order.
- Do not flip the parent SPEC's status to `decomposed`. Owner alone
  does that.
- Do not create a peer authority. Each TASK.md cites its parent
  SPEC; the parent SPEC remains immutable execution authority.
- Do not skip integration verification. After all tasks reach
  `done`, the parent SPEC's full acceptance_commands run as the
  integration gate before flipping to `verified`.
- Do not dispatch AFK work with unresolved owner questions.
- Do not let cross-validation be performed by the same model family
  that authored the implementation.

## Output shape

After this skill runs, the parent SPEC's directory looks like:

```
specs/<parent_spec_id>/
├── IDEA.md
├── SPEC.md          (status: decomposed, set by owner)
└── tasks/
    ├── T-01-<slug>.md
    ├── T-02-<slug>.md
    └── ...
```

The parent SPEC's Completion Report gains a Decomposition Index:

```markdown
### Decomposition Index

Topological execution order (deps respected):

1. T-01-<slug> (mode: HITL, lanes: gpt-5.5 / claude-opus-4-7)
2. T-02-<slug> (mode: AFK, lanes: claude-opus-4-7 / gpt-5.5)
3. T-03-<slug> (mode: AFK, deps: [T-01], lanes: gpt-5.5 / claude-opus-4-7)
```
