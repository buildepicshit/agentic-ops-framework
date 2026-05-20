---
name: spec-driven-development
description: "the studio lifecycle index for non-trivial work — the 13-phase pipeline (IDEA → SPEC → review → approve → decompose → dispatch → execute → cross-validate → verify → close + capture-after / fastpath exception). Routes to per-phase skills (spec-authoring, spec-review, approved-spec-decomposition, implementation-execution, verification, spec-evidence-governance, fast-path). Read directly when you need the overall procedure; otherwise invoke the specific phase skill."
---

# Spec-Driven Development

Use this skill for non-trivial work in repos. This skill owns the
end-to-end lifecycle. Authoring mechanics (templates, schema, type
selection, IDEA capture) are owned by the
[`spec-authoring`](../spec-authoring/SKILL.md) skill. The blocking
quality gate is owned by the [`spec-review`](../spec-review/SKILL.md)
skill.

## Lifecycle

The full lifecycle for non-trivial work is a 13-phase pipeline:

1. **Preflight** — confirm repo, branch policy, and tooling per
   `AGENTS.md` / `CLAUDE.md` / `STATUS.md`.
2. **Orient** — read `.agents/DOCUMENTATION_GUIDE.md` if present, the
   relevant project docs, and existing approved specs that bear on the
   target area.
3. **Predict known failures** — before authoring, surface likely
   failure modes, scope drift risks, and ambiguous owner intent.
4. **Ideate** — for non-trivial work, conduct an IDEA conversation
   between owner and primary agent. Resolve the implied spec type
   (task / contract / decision), constraints, 2–3 considered
   approaches, a recommendation, and any owner-blocking questions.
   Capture the conversation as `IDEA.md` via `/idea-capture` and
   gate to `status: ready-for-spec` before proceeding. The IDEA
   artefact is itself contract-grade and citation-disciplined.
5. **Author spec** — run `/author-spec`. The
   [`spec-authoring`](../spec-authoring/SKILL.md) skill selects the
   matching template by `implies_spec_type:` and produces `SPEC.md`
   in the same spec folder.
6. **Review spec (BLOCKING)** — run `/review-spec`. The
   [`spec-review`](../spec-review/SKILL.md) skill applies the per-type
   quality gate (bar b for Task, bar c for Contract, bar b plus
   candidate-comparison for Decision), runs `lint-spec.sh` (REQUIRED
   for Contract), and produces a Quality Gate Result. The skill MUST
   NOT set `status: approved`.
7. **Approve** — owner reads SPEC and Quality Gate Result, then sets
   `status: approved`. Only the owner does this.
8. **Decompose (BLOCKING for Contract/Task with ≥2 slices)** — run
   `/decompose-approved-spec`. The
   [`approved-spec-decomposition`](../approved-spec-decomposition/SKILL.md)
   skill emits `specs/<id>/tasks/T-NN-*.md` from the SPEC's §11
   Execution Plan. Each TASK.md is the executable contract for a
   single slice and the 1:1 binding to a tracker issue. Each carries
   primary / cross-validation / verification model lanes per
   `file://your model-routing policy`. Cross-validation lane MUST be
   a different family from primary. Owner reviews the decomposition
   index; on directive, owner alone flips status `approved →
   decomposed`. Skip when the SPEC is one slice (emit one TASK.md
   and proceed) or a Decision SPEC (no implementation phase).
9. **Dispatch** — for each TASK.md, create a tracker issue (manually
   or via tooling) and record `linear_issue` in TASK.md
   front-matter. the autonomous-dispatch runner picks up the issues and runs per-issue
   workspaces using the repo's `WORKFLOW.md`. Per-task workpad
   discipline applies (see `<adopter-policy-repo>/agents/templates/WORKFLOW.body.md` (fleet-baseline reference; bes-fleet-policy-layout-specific)).
10. **Execute** — primary agents (one per tracker issue / TASK.md)
    work each slice within an isolated workspace. The TASK.md is
    immutable except for §6 Evidence; the parent SPEC is immutable
    except for the Completion Report. Surface scope drift; do not
    silently revise. Subagent fan-out within a slice MAY happen for
    independent read-only work (research, lint streams) per
    `judgment://agent-synthesis`
    §7.1; subagents MUST NOT modify SPEC or TASK.md.
11. **Cross-validate (BLOCKING per task)** — before a TASK.md flips
    `in-progress → in-review`, the `cross_validation_lane` (a
    different model family from primary) reviews the diff against
    the parent SPEC. Findings are recorded in the workpad
    `Validation` section. Primary agent addresses each finding or
    posts justified pushback. See `file://spec-bundle/skills/code-review/SKILL.md`
    and `file://spec-bundle/skills/spec-review/SKILL.md`.
12. **Verify** — when all TASK.md reach `done`, run the parent
    SPEC's full `acceptance_commands` as the integration gate.
    Record exit status and output excerpts. The
    `verification_lane` of each task and the integration verifier
    follow MODEL_ROUTING.md guidance: behavioral verification
    SHOULD use a different family from implementation.
13. **Report + close** — fill the parent SPEC's Completion Report
    (files changed, commands run, verification output, residual
    risk, spec evidence candidates). Append the Decomposition
    Index. Owner alone flips `verified → closed` after a
    spec-evidence-governance pass.

### Exception: capture-after pattern (and the `fastpath` SPEC type)

The IDEA → SPEC → review → approve → execute → verify → close
order is the default. One recognized exception (capture-after,
formalized as the `fastpath` SPEC type) applies when ALL its
thresholds hold; see
`file://spec-bundle/skills/spec-driven-development/references/capture-after-and-fastpath.md`
for the procedure, acceptance conditions, and reference
precedents.

## Spec Types

Specs are typed. Pick the matching template from `templates/`
(repo-relative under `your-policy-repo`; under `.templates/` in
each child product repo):

- `task` → `spec-bundle/templates/SPEC.task.template.md` — concrete, scoped,
  verifiable work. Default.
- `contract` → `spec-bundle/templates/SPEC.contract.template.md` — specifies
  behavior that future agents implement against (state machines,
  failure models, observability, reference algorithms). Bar c
  ("the autonomous-dispatch runner-grade") with REQUIRED lint.
- `decision` → `spec-bundle/templates/SPEC.decision.template.md` — chooses
  between named candidates with rationale, locks, and reversal plan.

Cross-template conventions (front-matter fields, citation grammar,
RFC 2119 rules, section-naming) live in the shared schema at
`spec-bundle/schema/SPEC.schema.md`. The IDEA artefact uses
`spec-bundle/templates/IDEA.template.md`.

Type selection is an authoring concern; defer to
[`spec-authoring`](../spec-authoring/SKILL.md) §"Type selection".

## IDEA Artefact Requirement

`/author-spec` REFUSES to run unless `<spec-folder>/IDEA.md` exists
with front-matter `status: ready-for-spec`. The IDEA artefact is
contract-grade and citation-disciplined: every factual claim carries
a citation prefix from the allowed grammar (`file://`, `cmd://`,
`url://`, `owner://`, `judgment://owner`, `judgment://agent-synthesis`
paired with owner-affirmation). Owner Judgments include verbatim
transcript quotes. See `spec-bundle/schema/SPEC.schema.md` §2 for the full
grammar.

## Cascade by id-citation (non-propagating SPECs)

`specs/*` does not propagate via `fleet-sync.sh`; only `agents/*`
content propagates. When a SPEC binds child repos without
mutating `agents/*` (typical of Decision SPECs encoding
studio-level principles), the cascade is **id-citation**.
Mechanism, implications for authors, and precedents:
[`references/cascade-by-id-citation.md`](references/cascade-by-id-citation.md).

## Memory Boundary (input vs. artefact)

Agent memory and training are LEGITIMATE INPUTS to ideation
conversations and to authoring/review reasoning. Long ideation
sessions require active agent participation using full context.

In artefacts (IDEA.md, SPEC.md, completion reports, spec evidence
candidates), every factual claim MUST carry a citation prefix from
the allowed grammar. Memory and training are NOT citable evidence.

This is the input-vs-artefact distinction: the conversation is where
agent capabilities are used fully; the artefact is the contract-grade
capture obeying citation discipline.

## Hard Rules

- Specs are executable contracts, not brainstorming notes.
- Interactive planning is linear and focused. Do not run multiple
  owner-interactive planning tracks in parallel.
- Do not implement until the spec is `status: approved` (set by
  owner). The `spec-review` skill MAY set
  `status: approved-pending-owner`; that is not a green light to
  execute.
- Project docs and `AGENTS.md` beat generated memory.
- Durable cross-project instructions go through approved specs and
  spec evidence records.
- Put task-control specs in `.templates/` (or `specs/` in
  `your-policy-repo`); put durable product docs in the repo-native
  docs path defined by `.agents/DOCUMENTATION_GUIDE.md`.
- No silent scope expansion. If new facts emerge that change scope,
  stop and surface to owner.
- No completion claim without fresh verification.
- Subagents executing a SPEC MUST NOT modify any section except the
  Completion Report. Subagents executing a TASK.md MUST NOT modify
  any section except §6 Evidence.
- **Skill-addition atomicity.** Adding a canonical skill MUST land
  the source `skills/<name>/SKILL.md`, the Claude mirror
  `.claude/skills/<name>/SKILL.md`, the registry row in
  `agents/SKILL_REGISTRY.md`, the manifest entry in
  `scripts/fleet-files.txt`, and the propagation directory
  loop in `scripts/fleet-sync.sh` in the same verified
  change. Splitting across commits silently breaks propagation —
  a child sync after a partial commit overwrites destination state
  with an incoherent subset
  (`judgment://agent-synthesis`
  §1).
- **Decomposition is BLOCKING for Contract/Task SPECs with ≥ 2
  slices.** A SPEC at `status: approved` MUST be decomposed via
  `/decompose-approved-spec` before agents begin execution. The
  decomposition emits durable `TASK.md` files under
  `specs/<id>/tasks/`. Owner alone flips status `approved →
  decomposed`. the autonomous-dispatch runner / the agent runner / Claude subagents anchor on
  TASK.md, not on prose execution-plan bullets.
- **Decomposition output MUST be durable.** Non-durable
  decomposition output (scratch markdown emitted to a chat
  surface) is structurally weaker than durable per-slice
  artefacts. Agents working from non-durable output re-derive
  scope every session; agents working from TASK.md anchor on the
  same contract across sessions, agents, and model families. See
  `judgment://agent-synthesis`
  §3.
- **Cross-family cross-validation is REQUIRED.** Each TASK.md MUST
  carry `cross_validation_lane` of a different model family from
  `model_route`. Cross-validation runs between `in-progress` and
  `in-review`. Same-family review is structurally weaker and is not
  acceptable.
- **Multi-model dispatch.** Before delegation, model-specific work,
  or non-trivial planning, agents MUST read
  `your model-routing policy`. Routing is by role (research,
  implementation, code-review, verification, docs, planning),
  not by model preference. Use the whole fleet; do not waste
  frontier turns on tasks that read-only scans or fast lanes can
  handle.

## Spec Review Checklist

The blocking quality gate is enforced by the
[`spec-review`](../spec-review/SKILL.md) skill per type. The
checklist below is the per-author self-check before handing off to
review. It applies across all three types where relevant; type-
specific bars are documented in `spec-review`.

- Problem is specific and cites current evidence.
- North star / product promise is grounded in checked-in docs or
  owner decisions.
- Goals and non-goals draw a clean boundary.
- Authority Map identifies active, stale, superseded, and
  evidence-only sources.
- Code/Docs Reality Check records contradictions and required action.
- Executor can identify exact files and interfaces.
- Test plan is runnable on this machine.
- Safety / scope invariants protect user work, repo rules, and
  product authority. Use `N/A` only when there is genuinely no
  meaningful safety or scope boundary.
- Open Questions are resolved before implementation, or marked
  `owner-blocking`.
- Acceptance Criteria are objective, paired 1:1 with Test Matrix
  entries.
- The executor is not required to invent product, design, quality,
  release, or acceptance criteria.
- Every factual claim carries a citation prefix; RFC 2119 keywords
  appear only in the sections permitted by their type.
