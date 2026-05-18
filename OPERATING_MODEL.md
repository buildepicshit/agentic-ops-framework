# Operating Model

The operating model the framework encodes. This document is the
high-level overview; the schema, templates, lint, and hooks are the
machine-enforced surface.

## Lifecycle

Non-trivial agent work follows thirteen phases:

1. **Preflight** — confirm the repo + workspace state is sane.
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

## Spec types

| Type | When |
|---|---|
| `task` | Concrete, scoped, verifiable work with a defined endpoint. Default when in doubt and the work is small. |
| `contract` | Stateful, multi-component, protocol-defining work. Lint required. |
| `decision` | Binding choice between named options. RFC 2119 keywords appear only in the Decision Statement section. |
| `fastpath` | Owner-directed trivial reversible work. One file, ≤50 lines, no public-contract impact. Lands at `status: closed` in the same commit as the work. No IDEA, no review gate, no decomposition. |

Capture-after exception (`status: verified` directly under
explicit owner directive) is documented in the schema for cases
where work shipped before the spec was authored.

## Citation grammar

Every factual claim in any artefact carries a prefix:

| Prefix | Use |
|---|---|
| `file://` | Repository path. The most common cite. |
| `cmd://` | Shell or tool command, with the observed output recorded inline. |
| `url://` | External URL with a fetch date. |
| `decision-authority://<role>:<date>` | A binding directive from a named decision-holder (owner, product lead, governance committee, etc.). |
| `judgment://owner` | Owner-affirmed judgment. Paired with a `decision-authority://` cite that captures the affirmation. |
| `judgment://agent-synthesis` | Agent inference. MUST be paired with owner affirmation captured via `decision-authority://`. |

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
BLOCKING rule; it documents a deferral.

## Safety invariants

The framework MUST preserve these invariants. Hooks enforce
the most common violations:

- No edits on the protected branch unless an approved spec
  declares `branch_policy: main-direct`.
- No pushes to the protected branch outside that policy.
- No bulk staging (`git add .`, `git add -A`).
- No bypass of verify gates (`--no-verify`,
  `--no-gpg-sign`, etc.).
- No AI attribution in commit messages (no `Co-Authored-By:
  Claude`, no GPT trailers).
- Owner-only state transitions are non-negotiable.

## Completion Report format

Every completed non-trivial task reports, in §17 (Task) /
§14 (Decision) / §19 (Contract):

- **Files changed** — explicit list with NEW / UPDATED / DELETED.
- **Commands run** — `cmd://` excerpts of acceptance_commands.
- **Verification result** — AC-by-AC pass/partial/fail.
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
- Do not bypass cross-family review on decomposed work. Document
  fallback honestly when strict cross-family is unreachable.
