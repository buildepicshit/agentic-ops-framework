# Section 1 — Universal (all agents)

## Operating principles

1. **Citation discipline.** Every factual claim you write into a
   `SPEC.md`, `TASK.md`, `Completion Report`, `SESSION_JOURNAL.md`,
   or `AGENT_FEEDBACK.md` MUST carry a citation prefix: `file://`,
   `cmd://`, `url://`, `owner://`, `judgment://owner`,
   `judgment://agent-synthesis`. Agent memory is INPUT, never
   EVIDENCE. See `spec-bundle/schema/SPEC.schema.md` §2.
2. **Owner authority is non-negotiable.** Owner alone sets
   `status: approved`, `status: decomposed`, and `status: closed`
   on a SPEC. Skills MAY set `approved-pending-owner`,
   `in-execution`, `verified`, `needs-revision`, and
   `owner-blocking`. Agents and subagents MUST NOT set any
   owner-only status under any condition
   (`spec-bundle/schema/SPEC.schema.md` §1.3).
3. **Work only in the provided repository.** Do not edit paths
   outside the workspace root. Cross-repo work goes through a
   fleet directive (your fleet-policy enforcement channel) or a
   new tracker ticket against the target repo.
4. **Surface friction; do not bypass.** If a hook, lint, or audit
   blocks you, the correct response is `/agent-feedback`, NOT
   `--no-verify`, NOT `VERIFY_SKIP=1`, NOT hook disablement. See
   `spec-bundle/skills/agent-feedback/SKILL.md`.
5. **Final message reports outcomes.** Completed actions and
   blockers only. Do not include "next steps for user" prose.

## Step 0 — Orient (universal)

Three minutes of reading, no edits:

1. `AGENTS.md` (root) → its imports → `STATUS.md` →
   `OPERATING_MODEL.md` → your model-routing policy →
   `spec-bundle/schema/SPEC.schema.md`.
2. The **`SESSION_JOURNAL.md`** at the repo root (last 3 entries).
   It tells you what the previous agent did, what was left dirty,
   and what you should pick up. If absent, copy from
   `spec-bundle/templates/workpads/SESSION_JOURNAL.template.md`.
3. `AGENT_FEEDBACK.md` at the repo root — any open entries
   relevant to your work. If absent, copy from
   `spec-bundle/templates/workpads/AGENT_FEEDBACK.template.md`.
4. The active TASK.md (if dispatched) or the SPEC you're
   operating against. The parent SPEC is immutable except for its
   §17 Completion Report.

## Step 1 — Pick the procedure

- **Tiny non-trivial work under explicit owner directive**
  (≤ 1 file, ≤ 50 lines, single component, reversible,
  owner-cited): run `/fast-path` and produce a fast-path SPEC at
  `status: closed`. No IDEA, no review gate, no decomposition. See
  `spec-bundle/skills/fast-path/SKILL.md` for thresholds.
- **Non-trivial work otherwise**: run the spec-driven lifecycle:
  IDEA → SPEC → review → owner approves → decompose (Contract/Task
  with ≥ 2 slices) → execute → cross-validate → verify → owner
  closes. See `spec-bundle/skills/spec-driven-development/SKILL.md`.
- **Trivial work** (typo, link, formatting; no behavior change):
  edit directly. Hooks still apply.

## Step 2 — Subagent dispatch and multi-model fan-out

Fan out to subagents (potentially in different model families) to
parallelize independent work or to obtain cross-family
perspective. Read your model-routing policy "Routing Matrix"
before dispatch.

When a TASK.md is in scope, its front-matter names three model
lanes:

- `model_route` — primary execution lane (you).
- `cross_validation_lane` — different model family; runs the
  cross-validation review (BLOCKING before in-review).
- `verification_lane` — runs behavioral verification when needed
  (different family preferred for behavioral checks).

Use subagent fan-out when:

- 2+ independent verification streams (e.g., lint + test + build)
  can run in parallel.
- 2+ independent file/module changes with no shared state.
- An investigation has 2+ orthogonal hypotheses.

Do NOT spawn subagents when:

- Single linear edit + verify cycle.
- Tasks share state.
- Owner is in the loop; interactive planning is single-track.

Dispatch model:

- Claude Code `Agent` tool with multiple invocations in one
  assistant message, or the equivalent dispatch primitive in your harness.
- Each subagent receives: TASK.md id (if dispatched), parent SPEC
  id (if dispatched), single-purpose scope, model lane,
  read/write boundary.
- Subagents MUST NOT modify SPEC.md, TASK.md, SESSION_JOURNAL.md,
  or AGENT_FEEDBACK.md. They report back; the dispatching agent
  writes.
- Bound subagent loops: max ~50 tool uses or ~30 minutes per
  subagent
  (`specs/2026-01-15-example-procedure-v1/SPEC_EVIDENCE.md`
  §5).
- Record a Parallelism Decision Record in the workpad before
  dispatch:

  ```yaml
  parallelism_evaluated: true
  decision: fanout | local | owner-check
  rationale: <why this shape>
  agents_or_models:
    - codex:gpt-5.5
    - claude:claude-opus-4-7
  ```

For cross-repo work, do NOT dispatch subagents across repo
boundaries. Use the fleet-enforce skill
(your fleet-policy enforcement channel) or create new tracker
tickets in the target repo.

## Step 3 — Cross-family cross-validation (BLOCKING when TASK.md is in scope)

Before flipping a TASK.md to `in-review` (or before submitting a
PR for owner-led work), dispatch a review agent on a different
model family than the implementer. The reviewer:

- Runs read-only against the diff and parent SPEC.
- Emits findings ordered by severity with file/line citations.
- Returns the report to the workpad / SESSION_JOURNAL.md
  `Validation` section.

Address each finding in code/tests/docs OR post a justified
pushback reply. Same-family review is structurally weaker; see
`spec-bundle/skills/code-review/SKILL.md` "Hard Rules" for the
`same-family-review` escape hatch when cross-family is
unavailable.

## Step 4 — Decomposition gap recovery

If a TASK.md is missing for an active dispatched issue, or you're
working against an `approved` SPEC with ≥ 2 slices and no
`tasks/` directory:

1. Stop coding.
2. Run `/decompose-approved-spec <parent_spec_id>` (see
   `spec-bundle/skills/approved-spec-decomposition/SKILL.md`).
3. Owner reviews + approves the decomposition (one-shot, not
   per-task). Owner alone flips `approved → decomposed`.
4. Tasks become trackable; proceed.

## Step 5 — Session journal write (universal)

Before ending your session (or as Stop-hook reminds you):

1. Append a new entry to `SESSION_JOURNAL.md` per the template.
2. Note what you did, what you touched, what's dirty, what the
   next agent should pick up.
3. If you hit friction you couldn't resolve, ALSO file an entry
   in `AGENT_FEEDBACK.md`.

## Universal guardrails

- **Policy origination.** When operating in a child repo of a
  multi-repo fleet, policy artefacts (skills, templates, hooks,
  schema) MUST originate in the policy repo. Edits to mirrored
  content in child repos are repo-local drift and SHOULD be
  silently overwritten on next propagation; amend the canonical
  artefact upstream first.
- **Protected branch.** Do not push to the protected branch
  unless an active SPEC declares `branch_policy: main-direct`
  (enforced by `block-push-to-main.sh`).
- **Conventional Commits.** Allowed types: `feat`, `fix`,
  `refactor`, `test`, `docs`, `chore`, `research`, `tooling`,
  `perf`, `style`, `build`, `ci`, `spec`. Your repo MAY add
  type extensions via its commit-msg hook.
- **Stage explicitly by name.** No `git add -A` / `git add .`
  (enforced by `block-git-add-all.sh`).
- **No AI attribution** in commits or PRs (enforced by
  `block-ai-attribution.sh`).
- **Scope discipline.** When meaningful out-of-scope improvements
  surface, file a separate spec / task / feedback entry. Do not
  expand current scope silently.

## Related skills

Available in `spec-bundle/skills/`:

- `repo-orientation` — what to read, in what order, before editing.
- `spec-driven-development` — the IDEA→SPEC→tasks→execute
  pipeline.
- `spec-authoring` — produce typed SPECs (task / contract /
  decision / fastpath).
- `spec-review` — BLOCKING quality gate.
- `approved-spec-decomposition` — post-approval SPEC → TASK.md
  emission.
- `fast-path` — small, single-component, owner-directed work.
- `implementation-execution` — scoped edits without surprise.
- `code-review` — review your own diff before push; cross-family
  reviewer for TASK.md execution.
- `verification` — fresh evidence before completion claim.
- `tdd` — test-driven development for new behavior.
- `diagnosis` — systematic debugging when something breaks.
- `caveman` — opt-in compressed communication (NOT for
  safety-critical work).
- `release-pr` — PR preparation discipline.
- `worktrunk` — owner-led parallel agent worktrees via `wt`.
- `agent-feedback` — surface friction / confusion / misalignment.
- `fleet-enforce` — (your-policy-repo only) cross-repo directives.
- `symphony-dispatch` (your autonomous-dispatch runner integration, if any) — checks before enabling autonomous workers.
- `agents-md-improver` — entry-doc audit + WORKFLOW.body drift.

---

