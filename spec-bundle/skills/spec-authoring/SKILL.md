---
name: spec-authoring
description: "Use when capturing an IDEA (/idea-capture) or authoring a SPEC.md (/author-spec) under the spec-first model. Owns templates, type selection (fastpath / task / contract / decision), shared schema, citation discipline, IDEA-conversation tactics. Hands off to spec-review for the BLOCKING gate. Do not use to review existing specs (spec-review) or implement approved specs (implementation-execution)."
---

# Spec Authoring

Use this skill to produce IDEA.md and SPEC.md artefacts that pass the
per-type quality gates defined in the inaugural spec-authoring
procedure.

This skill does NOT approve specs. After authoring, it hands off to
`spec-review`, which runs the blocking gate and either returns
`approved-pending-owner` or `needs-revision`. Owner alone sets
`approved`.

## When to Use

- The owner has finished an ideation conversation and asks for an
  IDEA artefact captured under `/idea-capture <slug>`.
- An IDEA.md exists with `status: ready-for-spec` and the owner asks
  for a SPEC under `/author-spec`.
- Before hand-writing IDEA.md or SPEC.md content; this skill is the
  authority for which template, which sections, and which citations
  are REQUIRED.
- When picking a spec type for non-trivial work and the choice
  between Task, Contract, and Decision is not obvious.

Do not use this skill for:

- Trivial spec edits (typo fixes, link updates) — edit directly.
- Reviewing a spec already authored — use `spec-review`.
- Implementing an approved spec — use `implementation-execution`.

## Grill Before IDEA

For non-trivial IDEA capture, sharpen the owner conversation before
writing the artefact:

1. Check the repo first for answers the code or docs can provide.
2. Ask one owner question at a time.
3. Prefer concrete trade-offs over broad methodology debate.
4. When the design space is ambiguous, present 2-3 viable approaches
   with fit, cost, and risk.
5. Recommend one approach only after the constraints are clear.
6. Capture owner validation as verbatim `owner://transcript-<date>`
   quotes in IDEA.md.

Do not let grilling become a new approval gate. It is a clarification
tactic that feeds the existing IDEA -> SPEC procedure.

## Reference Architecture First

When a public reference architecture exists for the SPEC's domain,
cite it in §4 Authority Map and mirror its contract shape rather
than re-deriving its primitives. When adopting an external tool
that fits procedure (CLI, library, runner), follow the
six-part shape.

Procedure + worked examples (the autonomous-dispatch runner, worktrunk):
[`references/reference-architecture.md`](references/reference-architecture.md).

## Templates

The four authoring templates live at:

- `templates/IDEA.template.md` — the IDEA artefact.
- `templates/SPEC.task.template.md` — concrete, scoped, verifiable
  work.
- `templates/SPEC.contract.template.md` — stateful, multi-component,
  protocol-defining work.
- `templates/SPEC.decision.template.md` — binding choice between
  named options.

Cross-template conventions (front-matter schema, citation grammar,
RFC 2119 rules, section naming) live in `templates/SPEC.schema.md`.
Templates reference that schema rather than restating it. Read the
schema before authoring.

The produced IDEA.md and SPEC.md live at `specs/<spec_id>/` in
the repo that owns the work. In a fleet topology the source
policy repo holds fleet-policy specs under `specs/`; each
child repo holds its own work under `.agents/specs/` (or
equivalent gitignored path for OSS-posture repos). Pick the
location based on which repo owns the change.

## Type Selection

Pick the type before opening a SPEC template. The IDEA artefact
records the choice as front-matter `implies_spec_type`; the SPEC
inherits it as `type`.

Decision tree:

0. **Is this small, single-component, reversible work under
   explicit owner directive** — meeting ALL of: ≤ 1 file, ≤ 50
   lines, single component, no public-contract or persisted-state
   impact, no cross-session compounding, owner-cited authority?
   YES → `fastpath`. Use `SPEC.fastpath.template.md`. No IDEA, no
   review, no decomposition. Capture-after by default; lands at
   `status: closed` in the same commit as the work. See
   `skills/fast-path/SKILL.md` for thresholds. **If ANY
   threshold is missed, do not use fastpath** — fall through to
   the steps below.
1. **Is this a binding choice between two or more named options
   (stack pick, architecture pick, vendor pick, policy pick)?**
   YES → `decision`. Use `SPEC.decision.template.md`. The Decision
   Statement section is the only place RFC 2119 keywords appear in
   a Decision spec.
2. **Otherwise: does the work specify behavior that future agents
   implement against?** Signs: stateful (state machine, persistence,
   idempotency), multi-component (more than one skill/script/repo
   coordinates), defines a wire or file protocol, has a non-trivial
   failure surface, has observability requirements, will be referenced
   by other specs. YES → `contract`. Use
   `SPEC.contract.template.md`. Contract specs MUST pass the lint
   script.
3. **Otherwise: this is concrete, scoped, verifiable work with a
   defined endpoint** (add a file, refactor a module, fix a bug, run
   a migration). → `task`. Use `SPEC.task.template.md`. Task is the
   default; when in doubt and the work is small AND meets fastpath
   thresholds, prefer fastpath; otherwise, task.

Edge cases:

- Mixed Decision-and-implementation work: author the Decision spec
  first, then a follow-on Task or Contract spec for the
  implementation. Do not fold them into one artefact.
- "Refactor" that changes a public contract: this is a Contract spec,
  not a Task spec.
- Owner explicitly directs a type via `judgment://owner`: honour the
  directive; do not re-derive.

## Contract §17 OPTIONAL when empty

Per the ceremony-weight Decision (`judgment://agent-synthesis`),
Contract SPEC §17 Open Questions is OPTIONAL when empty:

- Authors MAY omit the §17 heading entirely when no open
  questions remain.
- If retained, the body MAY contain only `None.`, `N/A`, or a
  single citation to the producing IDEA's §6 / §7 resolution.
- If non-empty, existing per-section checks apply (citation
  grammar, RFC 2119, etc.).

This relaxation only applies to Contract SPECs; Task and
Decision SPECs continue to require §17.

## Contract §1 / §13 capture-after defer-shorthand

Per the same ceremony-weight Decision, Contract SPECs landing at
`status: verified` via the capture-after exception
(`file://spec-bundle/schema/SPEC.schema.md` §1.3) MAY use a
defer-shorthand for §1 Problem Statement and §13 Test and
Validation Matrix:

- The section body MAY be a one-paragraph cite-by-id pointer
  to the producing IDEA's corresponding section, e.g.
  `See file://specs/<id>/IDEA.md §1 (capture-after defer).`
- The shorthand is RECOMMENDED only when the producing IDEA's
  section is itself substantive — the defer must resolve to
  real content, not to another defer.
- Lint passes the shorthand by construction (a single-paragraph
  `file://` cite satisfies the §2 citation-grammar rule); the
  per-type gate in `spec-review` validates that the cited IDEA
  section exists and is non-empty.

For Contracts at any other status (`draft`, `approved`,
`in-execution`), §1 and §13 MUST be filled with substantive
content; defer-shorthand is rejected by the spec-review gate.

## Fleet-Wide Principle SPECs

Fleet-level principles (binding tenets that cross every
fleet product) are authored as Decision SPECs under the
`principle-<topic>` slug taxonomy.

Conventions, cascade-by-id-citation mechanics, and the
verbatim-to-normative review trace:
[`references/studio-principles.md`](references/studio-principles.md).

## Citation Discipline

Every factual claim in IDEA.md and SPEC.md MUST carry a citation
prefix. Allowed prefixes: `file://`, `cmd://`, `url://`, `owner://`,
`judgment://owner`, `judgment://agent-synthesis`. The full grammar,
positive and negative examples, and the list of constructs that do
NOT require citation (section headers, editorial framing, internal
definitions, internal cross-references, pseudocode, domain-model
field references) live in
`file://spec-bundle/schema/SPEC.schema.md` §2.

Operating principle: agent memory and training are LEGITIMATE INPUTS
to the ideation conversation and to your authoring reasoning. They
are NOT citable evidence in the artefact. This is the input-vs-
artefact distinction recorded in `OPERATING_MODEL.md` Memory
Policy. If you cannot back a claim with `file://`, `cmd://`,
`url://`, or an owner-affirmed judgment, the claim does not belong
in the artefact.

When the lint flags a sentence that is in fact editorial, append
`<!-- lint-ok: no-citation -->` per
`file://spec-bundle/schema/SPEC.schema.md` §2.5. Use sparingly; pervasive
suppression is itself a quality signal.

## Quality Gate Handoff

This skill MUST NOT set `status: approved` on any artefact.
Authority for approval rests with the owner alone, per
`file://spec-bundle/schema/SPEC.schema.md` §1.3 and
`file://examples/reference-procedure-spec`
§7.6.

After authoring:

1. Set IDEA.md or SPEC.md `status: draft`.
2. Hand off to `spec-review`. For IDEA.md the gate is §10.1 of the
   authority spec; for SPEC.md it is §10.2 (task), §10.3 (contract),
   or §10.4 (decision).
3. `spec-review` runs `lint-spec.sh` (REQUIRED for Contract,
   RECOMMENDED for Task and Decision) and produces a structured
   Quality Gate Result.
4. On a clean pass, `spec-review` sets `status: approved-pending-owner`
   (SPEC) or `status: ready-for-spec` (IDEA). On any blocking
   failure, `spec-review` sets `status: needs-revision` (SPEC) or
   leaves `status: draft` (IDEA) and surfaces failures with file:line
   citations.
5. Owner reviews the gate result and the artefact. Owner alone
   transitions SPEC.md to `status: approved`.

If `spec-review` returns `needs-revision`, return to this skill: read
the failures, revise the artefact, re-hand-off. Do not silently
escalate failures to `owner-blocking`; that status is for unresolved
Open Questions, not for gate failures.

## Hard Rules

- Do not author IDEA.md or SPEC.md without reading
  `templates/SPEC.schema.md` first.
- Do not use a SPEC template without first picking a type per the
  decision tree above.
- Do not put uncited factual claims in any artefact. Memory is
  input, not evidence.
- Do not set `status: approved`. The owner does that.
- Do not silently mix Decision and implementation work in one spec.
