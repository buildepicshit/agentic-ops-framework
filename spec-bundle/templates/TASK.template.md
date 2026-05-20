---
id: T-NN-kebab-case-slice
parent_spec: YYYY-MM-DD-kebab-case-spec-id
status: todo
owner: unassigned
model_route: gpt-5.5
cross_validation_lane: claude-opus-4-7
verification_lane: gpt-5.5
mode: HITL
deps: []
write_scope: disjoint
parallelism_evaluated: true
acceptance_commands: []
tracker_issue: null
---

<!--
Per-task artefact emitted by the `/decompose-spec` workflow from an
approved SPEC's §11 Execution Plan. One TASK.md == one tracker issue
== one autonomous-dispatch runner per-issue workspace run.

The parent SPEC remains the authority. This file IS NOT a peer
authority — it carries the slice's executable scope, the model lane
assignments, the verification commands, and the evidence trail.

Front-matter schema:

- `id` — kebab-case slice identifier (e.g. `T-01-fleet-baseline-body`).
  MUST be unique within the parent SPEC's `tasks/` directory.
- `parent_spec` — id of the SPEC this task implements.
- `status` — one of `todo` | `in-progress` | `in-review` | `done` |
  `blocked`. Mirrors tracker active states used in WORKFLOW.md
  YAML config. Owner alone moves to `done`.
- `owner` — agent id or `unassigned`.
- `model_route` — primary execution lane. MUST be a model slug from
  `your model-routing policy` in your routing policy.
- `cross_validation_lane` — DIFFERENT model FAMILY from
  `model_route`. The cross-validation reviewer reads the diff/
  artefact produced by the primary lane and emits findings before
  Human Review. SHOULD be a different family (different model family) per
  `your parallelism-and-routing SPEC`
  §7.3.
- `verification_lane` — model lane for fresh-evidence verification
  (running acceptance_commands, capturing output). MAY equal
  `model_route` if the verification is purely mechanical (lint,
  test); SHOULD be a different family for behavioral verification.
- `mode` — `HITL` (human-in-the-loop) or `AFK` (autonomous). AFK
  requires bounded ownership, explicit acceptance, no mid-slice
  owner judgment, safe-stop on ambiguity per
  `file://spec-bundle/skills/approved-spec-decomposition/SKILL.md`
  "AFK Eligibility".
- `deps` — list of TASK.md ids that MUST reach `done` before this
  one starts.
- `write_scope` — `none` | `disjoint` | `overlap`. Parallel writes
  REQUIRE `disjoint` per
  `your parallelism-and-routing SPEC`
  §6.1.1.
- `parallelism_evaluated` — boolean. MUST be true. Records that the
  decomposition phase evaluated parallelism per §7.1 of the v2
  routing SPEC.
- `acceptance_commands` — list of shell commands that MUST exit 0
  for this task to flip `in-progress → in-review`. Subset of the
  parent SPEC's acceptance_commands plus task-specific checks.
- `tracker_issue` — tracker identifier (e.g. `PROJ-123`) once the task
  is dispatched. Null until decomposition is reflected in the
  tracker.

Citation discipline applies: every factual claim in §3 (Scope), §4
(Read context), and §6 (Evidence) MUST carry a citation prefix per
`file://spec-bundle/schema/SPEC.schema.md` §2.
-->

# TASK: [Slice Title]

## 1. Goal

One sentence. The user-, contract-, or workflow-visible outcome this
slice delivers.

## 2. Parent SPEC anchor

This task implements §[NN] [section title] of
`file://specs/{{parent_spec}}/SPEC.md`. The parent SPEC remains the
authority for what is in scope. This file is the executable
contract for THIS slice only.

## 3. Scope

### 3.1 Owned files

Files this worker MAY edit:

- `path/to/file.ext` — [why this file is in scope; cite the parent
  SPEC section that names it].

### 3.2 Read context

Files this worker MUST read before editing:

- `file://AGENTS.md`
- `file://specs/{{parent_spec}}/SPEC.md`
- `file://your model-routing policy` (before any subagent dispatch)
- [other repo-specific reads]

### 3.3 Out of scope

Explicit non-goals for this slice. Surface as backlog tracker issues
if discovered during execution per
`file://spec-bundle/operations/workflow-universal.md` "Universal guardrails".

## 4. Model dispatch

| Lane | Model | Role |
|---|---|---|
| Primary | `{{model_route}}` | Implementation + workpad management. |
| Cross-validation | `{{cross_validation_lane}}` | Independent diff review before Human Review. Different family from primary. |
| Verification | `{{verification_lane}}` | Run acceptance_commands; capture fresh evidence. |

**Subagent dispatch rules** (from
`your parallelism-and-routing SPEC`
§7.1, §7.2):

- The primary agent MUST evaluate whether independent sub-work in
  this slice can fan out (read-only research, code review,
  verification streams).
- Subagents MUST receive bounded scope, allowed files, expected
  output, and write/read posture.
- Subagents MUST NOT modify the parent SPEC.md or this TASK.md
  (read-only).
- Long iterative loops SHOULD be bounded (≤ 50 tool uses or ≤ 30
  minutes per subagent) per
  `your spec-evidence registry`
  §5.

## 5. Acceptance

### 5.1 Acceptance commands

Each entry in front-matter `acceptance_commands` MUST exit 0 before
this task flips `in-progress → in-review`. List them here with a
one-line rationale:

- `cmd://...` — [what this proves].

### 5.2 Acceptance criteria

- [ ] AC-1: [criterion].
- [ ] AC-2: [criterion].

## 6. Evidence

Filled by the executor before `in-review`:

- Files changed: [list].
- Commands run + exit codes: [list].
- Cross-validation findings: [summary; full report linked from PR].
- Residual risk: [if any].

## 7. Stop conditions

Reasons to halt and route back to the owner or root manager:

- Owner judgment required mid-slice.
- Discovered scope expansion.
- Cross-validation surfaced a blocker.
- Acceptance commands cannot pass under the bounded scope.
- Required external auth/secret missing.

## 8. Tracker binding

Once dispatched:

- Tracker issue: `{{tracker_issue}}`
- PR (when opened): [URL]
- Workpad comment ID: [tracker comment id]

The tracker issue's `## Workpad` comment is the live execution
journal per `file://spec-bundle/operations/workflow-universal.md` Step 1.
