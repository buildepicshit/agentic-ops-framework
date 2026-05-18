# Operating Model

The operating model the framework encodes. This document is the
high-level overview; the schema, templates, lint, and hooks are the
machine-enforced surface.

## Lifecycle

Non-trivial agent work follows thirteen phases:

1. **Preflight** — confirm the repo + workspace state is sane
   (workspace layout, hooks installed, MCP config sane).
2. **Orient** — read the entry docs, status, and any active
   spec; build a citable map of the work surface.
3. **Predict** — name the known-likely failure modes and the
   ambiguous owner intent up front.
4. **Ideate** — produce `IDEA.md` capturing problem, substance,
   constraints, approaches considered, recommendation, and any
   owner-blocking open questions.
5. **Author** — produce `SPEC.md` from a ready-for-spec IDEA,
   selecting the type (task / contract / decision) by the
   implied shape; fastpath is a separate type for trivial
   reversible work.
6. **Review** (BLOCKING) — run the per-type quality gate
   (`lint-spec.sh`) and structured review against bar criteria.
   Outcome: `needs-revision` or `approved-pending-owner`.
7. **Approve** — owner alone sets `approved`. Skills MUST NOT.
8. **Decompose** (BLOCKING for Contract/Task with ≥2 slices) —
   emit per-slice `TASK.md` artefacts. Each TASK.md pins
   `model_route`, `cross_validation_lane` (different family
   REQUIRED), and `verification_lane`. Owner alone flips
   `approved → decomposed`.
9. **Dispatch** — TASK.md artefacts feed your tracker / dispatch
   runtime. The framework doesn't dictate the runtime.
10. **Execute** — bounded implementation from an approved
    (and decomposed) spec.
11. **Cross-validate** (BLOCKING per task) — review on a model
    family different from the implementer. No exceptions.
12. **Verify** — run acceptance commands; fill the Completion
    Report; status moves to `verified`.
13. **Report + close** — owner alone sets `closed` after a
    spec-evidence-governance pass on durable lessons.

## Agent roles

Most non-trivial work passes through five roles. One agent MAY
fill more than one role across a session; an agent MUST NOT
fill conflicting roles within a single artefact.

- **Planner** — writes IDEA / SPEC from project facts and owner
  intent. Bounded by the citation grammar.
- **Spec reviewer** — runs the BLOCKING per-type quality gate.
  Rejects ambiguity, unsafe assumptions, and missing tests.
  Sets `needs-revision` or `approved-pending-owner`; never
  `approved`.
- **Executor** — edits code, configs, and directly-coupled
  tests/docs inside the approved scope. Reports scope drift
  rather than silently absorbing it.
- **Verifier** — runs acceptance commands and inspects diffs.
  Records fresh evidence. Cross-family verifier MUST run on a
  different model family from the executor for behavioral
  verification.
- **Archivist** — promotes durable lessons from completed work
  into spec evidence, backlog proposals, or operating-model
  amendments. Emits candidates; does not set `closed` on parent
  SPECs.

## Spec types

| Type | When |
|---|---|
| `task` | Concrete, scoped, verifiable work with a defined endpoint. Default when in doubt and the work is small. |
| `contract` | Stateful, multi-component, protocol-defining work. Lint required. |
| `decision` | Binding choice between named options. RFC 2119 keywords appear only in the Decision Statement section. |
| `fastpath` | Owner-directed trivial reversible work. One file, ≤50 lines, no public-contract impact. Lands at `status: closed` in the same commit as the work. No IDEA, no review gate, no decomposition. |

Capture-after exception (`status: verified` directly under
explicit decision-authority directive) is documented in the
schema for cases where work shipped before the spec was
authored.

## Workspace policy

- Use a separate branch or worktree for parallel write-capable
  agents. Multiple writers MUST NOT edit the same files
  concurrently without a worktree boundary.
- Stage files explicitly. The fleet-baseline hook rejects
  `git add .` and `git add -A`. Bulk staging quietly captures
  unrelated work and is a recurring source of failed reviews.
- Keep generated scratch, machine-local caches, and personal
  credentials out of tracked source. `.mcp.json` is machine-
  local and gitignored; the framework ships with no active
  MCP servers by default.
- Protected branches require an active SPEC declaring
  `branch_policy: main-direct` to allow direct edits and
  pushes. Without that declaration, hooks block both.
- Public OSS repos require extra release hygiene. Do not push
  doc-only agent-control churn to a public surface unless the
  owner approves a low-noise PR plan with explicit CI impact.

## Citation grammar

Every factual claim in any artefact carries a prefix:

| Prefix | Use |
|---|---|
| `file://` | Repository path. The most common cite. |
| `cmd://` | Shell or tool command, with the observed output recorded inline. |
| `url://` | External URL with a fetch date. |
| `decision-authority://<role>:<date>` | A binding directive from a named decision-holder (owner, product lead, tech lead, governance committee, etc.). |
| `owner://` | Shorthand for `decision-authority://owner:<date>` in single-owner studios. |
| `judgment://owner` | Owner-affirmed judgment. Paired with a `decision-authority://` cite. |
| `judgment://agent-synthesis` | Agent inference. MUST be paired with decision-authority affirmation. |

Agent memory and training data are LEGITIMATE INPUTS to ideation
and authoring reasoning. They are NOT citable evidence in
artefacts. If a claim cannot be backed by one of the prefixes
above, it does not belong in the artefact.

## Memory boundary

Long ideation conversations require active agent participation
using full context. In artefacts (IDEA.md, SPEC.md, completion
reports, spec evidence), every fact-bearing claim carries a
cite per the grammar above. The boundary is sharp: the
conversation is the input; the artefact is the evidence.

Practical implications:

- Agents draft options, inventories, and questions during
  ideation. Drafts are planning evidence only until the owner
  records the selected direction in an approved spec.
- Durable facts MUST cite their source. Restating training
  knowledge as a spec claim without a cite is a lint failure.
- Memory across sessions is carried by the SESSION_JOURNAL.md
  workpad and the spec corpus, not by agent-private memory
  stores.

## Owner-only state transitions

The status state machine has three transitions only the owner
sets:

- `approved-pending-owner → approved` (after a clean gate)
- `approved → decomposed` (after decomposition emits TASK.md)
- `verified → closed` (after a spec-evidence-governance pass)

Skills MUST NOT set any of these three. The gate-passing
`spec-review` skill sets `approved-pending-owner` on a clean
result; the `spec-evidence-governance` skill emits candidate
captures but does not flip `closed`.

## Lightweight ceremony modes

The 13-phase lifecycle is the default for non-trivial work. Two
lightweight modes coexist:

**Fastpath SPEC type** applies when ALL of: ≤1 file changed,
≤50 lines, single component, no public-contract or persisted-
state impact, reversible in one commit, explicit owner
directive. Skips IDEA, review, decomposition, cross-validation;
lands at `status: closed` in the same commit as the work. If
ANY threshold fails, escalate to task / contract / decision.

**Capture-after** on task / contract / decision SPECs is
permitted under explicit decision-authority directive when
(a) the artefacts pass lint and the per-type gate, (b) the SPEC
is filed before the next change to the affected surface, and
(c) the SPEC lands at `status: verified` with the Completion
Report filled. Reference: `schema/SPEC.schema.md` §1.3.

These modes exist because the 13-phase ceremony is heavier than
necessary for tiny but non-trivial work. They are NOT escape
hatches — thresholds are objective and lint-enforced.

## Parallel execution policy

Before substantial research, code review, verification, or
implementation, agents evaluate whether independent parts of
the task can run in parallel.

Fanout when:

- Subtasks are independent or file ownership is disjoint.
- Expected wall-clock savings exceed coordination cost.
- Write scope is `none` or `disjoint` (per the TASK.md
  `write_scope` field).
- Each worker has a bounded role, allowed files or read-only
  scope, and a defined output shape.
- One primary agent remains accountable for integration, final
  verification interpretation, and reporting.

Preferred fanout cases:

- Research / inventory / static analysis (read-only).
- Independent verification streams (lint + test + build).
- Code review on multiple independent diffs.
- Documentation audits across non-overlapping surfaces.

Implementation work MAY fan out only when write ownership is
disjoint or isolated by branch / worktree. Multiple write-
capable agents MUST NOT edit the same files concurrently.

Owner-interactive planning stays serial. Do not run multiple
unresolved owner-conversation tracks in parallel. Trivial local
commands, tightly-coupled single-file edits, urgent blocking
steps, and owner-interactive ideation remain local unless the
owner explicitly requests fanout.

Record the parallelism decision in the workpad or TASK.md
front-matter (`parallelism_evaluated: true`) before dispatch.

## Cross-family review

Decomposed work requires a cross-family review pass between
`in-progress` and `in-review` on every TASK.md. The reviewer
agent runs on a different model family from the implementer.
Findings are recorded in the workpad; the implementer addresses
them or pushes back explicitly per the PR feedback protocol.

Cross-family review is the most important quality-control
primitive in the operating model. Same-family review is a
permissible *fallback* (with the limitation honestly labelled
in the artefact) only when the execution context cannot
dispatch cross-family. The fallback does not satisfy the
BLOCKING rule; it documents a deferral that owner-led external
dispatch resolves.

When the execution context can only dispatch one model family
(e.g., a Claude-Code-only session that can't spawn Codex /
Gemini), the agent MUST: (a) perform a same-family verification
with a different lane / subagent type; (b) label the limitation
in the artefact; (c) document the deferral as residual risk;
(d) leave the strict cross-family pass as an owner-triggered
follow-on.

## Documentation placement

Three layers of documentation coexist; each has a canonical
home:

- **Orchestration content** (specs, audits, migration
  proposals): `specs/` or your policy repo's equivalent. These
  are agent-control artefacts.
- **Durable product architecture**: the repo's native docs
  path (`docs/`, `docs/architecture/`, etc.). These are reader-
  facing and outlive any single SPEC.
- **Workpads** (per-repo session continuity + feedback +
  inbound messages): root-level files (`SESSION_JOURNAL.md`,
  `AGENT_FEEDBACK.md`, `AGENT_INBOX.md` if used).

Public-facing repos treat agent-control content as gitignored.
Fleet content lays into the working tree but never reaches
GitHub at OSS posture.

Audits start as scratch; they don't move directly into public
docs. Rewrite them for the intended audience after approval.

## Content and creative authority

Engineering and plumbing work may proceed from objective
technical contracts. Content, creative, product-positioning,
asset, narrative, tuning, gameplay-feel, demo-quality, and
visual/audio decisions require stricter authority.

Before a write-capable agent creates or changes content or
creative output, the approved spec MUST name:

- The repo-local source of truth.
- Allowed creative latitude.
- Provenance and licensing requirements.
- Exact output paths.
- Review checkpoint.
- Verification criteria.

If the spec does not answer where the content comes from or
how quality is judged, the agent stops as `owner-blocking`
instead of generating plausible content.

Agents MAY draft options, inventories, or questions for
creative work, but those drafts are planning evidence only
until the owner records the selected direction in the
approved spec or in durable product docs.

## Safety invariants

The framework preserves these invariants. Hooks enforce the
most common violations:

- No edits on the protected branch unless an approved spec
  declares `branch_policy: main-direct`.
- No pushes to the protected branch outside that policy.
- No bulk staging (`git add .`, `git add -A`).
- No bypass of verify gates (`--no-verify`,
  `--no-gpg-sign`, etc.).
- No AI attribution in commit messages (no `Co-Authored-By:
  Claude`, no GPT trailers).
- Owner-only state transitions are non-negotiable.
- No deletion of user work, branches, or untracked project
  files without first proving they are stale agent artefacts.
- No claim of completion without fresh verification output
  captured in the Completion Report.
- No raw memory used to override checked-in instructions.

## Completion Report format

Every completed non-trivial task reports, in §17 (Task) /
§14 (Decision) / §19 (Contract):

- **Files changed** — explicit list with NEW / UPDATED / DELETED.
- **Commands run** — `cmd://` excerpts of acceptance_commands.
- **Verification result** — AC-by-AC pass / partial / fail.
- **Residual risk** — what's deferred, what's known-fragile.
- **Spec evidence candidates** — durable lessons for the
  `spec-evidence-governance` pass.

## Hard rules

- Do not author IDEA / SPEC without reading the schema first.
- Do not put uncited factual claims in any artefact.
- Do not set `approved`, `decomposed`, or `closed` from a
  skill. These are owner-only.
- Do not silently mix Decision and implementation work in one
  spec. Author the Decision first; the implementation follows
  as Task or Contract.
- Do not bypass cross-family review on decomposed work.
  Document fallback honestly when strict cross-family is
  unreachable.
- Do not generate creative or product-positioning output
  without an approved spec that names the source of truth and
  quality bar.
- Do not run multiple write-capable agents against the same
  files without a worktree boundary.
- Do not push agent-control content to public repos that hold
  OSS posture.
