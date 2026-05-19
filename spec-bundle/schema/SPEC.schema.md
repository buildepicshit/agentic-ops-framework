# SPEC.schema.md — Shared schema for spec-driven framework

Status: v1.

This document is the single source of truth for cross-template
conventions used by IDEA.md and the four SPEC.md types
(Task / Contract / Decision / Fastpath). The four SPEC templates
and the IDEA / TASK templates reference this schema instead of
duplicating it.

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

`Implementation-defined` means the behavior is part of the contract
but this schema does not prescribe a single universal policy. The
implementation MUST document the selected behavior in the affected
artefact.

## 1. Front-matter schema

Every IDEA.md and SPEC.md MUST begin with a YAML front-matter block
delimited by `---` on its own line.

### 1.1 IDEA.md front-matter

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `id` | string | REQUIRED | kebab-case slug | matches `<topic>` portion of spec_id |
| `spec_id` | string | REQUIRED | `<YYYY-MM-DD>-<id>` | id of the SPEC this IDEA feeds |
| `status` | enum | REQUIRED | `draft` \| `ready-for-spec` \| `owner-blocking` \| `archived` | initial value `draft` |
| `owner` | string | REQUIRED | owner identifier | e.g. `owner-A` |
| `brainstormed_by` | string | REQUIRED | agent identifier | e.g. `codex-gpt-5.5`, `claude-opus-4-7-1m`, or any other model:lane label |
| `brainstormed_on` | date | REQUIRED | ISO-8601 date | e.g. `2026-01-15` |
| `implies_spec_type` | enum | REQUIRED | `task` \| `contract` \| `decision` | drives template selection in `/author-spec` |

Example:

```yaml
---
id: example-procedure-v1
spec_id: 2026-01-15-example-procedure-v1
status: ready-for-spec
owner: owner-A
brainstormed_by: codex-gpt-5.5  # or claude-opus-4-7-1m, etc. — any model:lane label
brainstormed_on: 2026-01-15
implies_spec_type: contract
---
```

### 1.2 SPEC.md front-matter (shared across all three types)

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `id` | string | REQUIRED | `<YYYY-MM-DD>-<topic>` | folder name MUST equal id |
| `status` | enum | REQUIRED | `draft` \| `needs-revision` \| `owner-blocking` \| `approved-pending-owner` \| `approved` \| `decomposed` \| `in-execution` \| `verified` \| `closed` | state machine; only owner sets `approved`, `decomposed`, and `closed` |
| `type` | enum | REQUIRED | `task` \| `contract` \| `decision` | determines which template was used |
| `owner` | string | REQUIRED | owner identifier | |
| `repo` | string | REQUIRED | repo name | e.g. `your-policy-repo` |
| `branch_policy` | enum | REQUIRED | `worktree-preferred` \| `main-direct` | matches OPERATING_MODEL Workspace Policy |
| `risk` | enum | REQUIRED | `low` \| `medium` \| `high` | |
| `requires_network` | boolean | REQUIRED | `true` \| `false` | |
| `requires_secrets` | list[string] | REQUIRED | env-var names or `[]` | |
| `acceptance_commands` | list[string] | REQUIRED | runnable commands | non-empty OR explicitly `[]` with reason in Acceptance Criteria section |
| `ideated_in` | string | REQUIRED | repo-relative path | path to producing IDEA.md |

Example (Contract SPEC):

```yaml
---
id: 2026-01-15-example-procedure-v1
status: approved
type: contract
owner: owner-A
repo: your-policy-repo
branch_policy: main-direct
risk: medium
requires_network: false
requires_secrets: []
ideated_in: specs/2026-01-15-example-procedure-v1/IDEA.md
acceptance_commands:
  - test -f templates/SPEC.task.template.md
  - bash scripts/lint-spec.sh specs/<id>/SPEC.md
---
```

### 1.3 Status state machine

```text
                  /idea-capture (gate pass)
IDEA.draft ─────────────────────────────► IDEA.ready-for-spec
   ▲                                              │
   │ owner returns                                │ /author-spec
   └─────────────── IDEA.draft ◄──┐               ▼
                                  │      SPEC.draft
                                  │           │
                                  │           │ /review-spec
                                  │           ▼
                                  │   SPEC.needs-revision ─── revise+rerun ─┐
                                  │           ▲                              │
                                  │           │ owner returns                │
                                  │           │                              │
                                  │   SPEC.approved-pending-owner ◄──────────┘
                                  │           │
                                  │           │ owner sets status: approved
                                  │           ▼
                                  │   SPEC.approved
                                  │           │
                                  │           │ /decompose-approved-spec
                                  │           │ (BLOCKING for Contract/Task with ≥2 slices)
                                  │           │ emits specs/<id>/tasks/T*.md
                                  │           ▼
                                  │   SPEC.<owner sets decomposed>
                                  │           │
                                  │           │ tracker issues created from TASK.md set;
                                  │           │ dispatcher picks them up; execution begins
                                  │           ▼
                                  │   SPEC.in-execution
                                  │           │
                                  │           │ acceptance_commands pass + Completion Report filled
                                  │           ▼
                                  │   SPEC.verified
                                  │           │
                                  │           │ spec evidence captured
                                  │           ▼
                                  │   SPEC.closed
```

Idempotency: status transitions are monotonic except for the explicit
`needs-revision` and `owner-blocking` reverse edges. `approved`,
`decomposed`, and `closed` MUST NOT revert without owner action.
Owner alone sets `approved`, `decomposed`, and `closed`. The
`spec-review` skill MUST NOT set `approved`. The
`approved-spec-decomposition` skill MUST NOT set `decomposed`. The
`spec-evidence-governance` skill MUST NOT set `closed`. Skills MAY set
`approved-pending-owner` on a clean gate result.

**Capture-after exception (decision-authority only).** A Contract
or Decision SPEC MAY land directly at `status: verified` in the
same change-set as the work it specifies, when the work was
implemented before the SPEC was authored under explicit
decision-authority directive (`decision-authority://<role>:<date>`
or `owner://transcript-<date>`). The per-type quality gate
(`spec-review`) and citation grammar remain REQUIRED; only the
temporal precedence of SPEC-before-work is waived. Capture-after
is an exception path; routine work follows the normal lifecycle
so the BLOCKING review gate runs before approval.

### 1.4 TASK.md front-matter

TASK.md is the per-slice executable artefact emitted by the
`approved-spec-decomposition` skill from an approved SPEC's §11
Execution Plan (Task) or §11 / §14 / §15 (Contract). One TASK.md
== one tracker issue == one isolated workspace run. The parent
SPEC remains the immutable execution authority; TASK.md files
are NOT peer authorities.

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `id` | string | REQUIRED | `T-NN-<kebab-case-slug>` | unique within parent SPEC's `tasks/` directory |
| `parent_spec` | string | REQUIRED | a SPEC `id` at status `approved`, `decomposed`, `in-execution`, or `verified` | |
| `status` | enum | REQUIRED | `todo` \| `in-progress` \| `in-review` \| `done` \| `blocked` | mirrors tracker active states; only owner sets `done` |
| `owner` | string | REQUIRED | agent id or `unassigned` | |
| `model_route` | string | REQUIRED | model slug from your model-routing policy | primary execution lane |
| `cross_validation_lane` | string | REQUIRED | model slug; MUST be from a different family than `model_route` | independent diff/artefact reviewer |
| `verification_lane` | string | REQUIRED | model slug | MAY equal `model_route` for mechanical verification; SHOULD differ for behavioral verification |
| `mode` | enum | REQUIRED | `HITL` \| `AFK` | AFK requires bounded ownership and explicit acceptance |
| `deps` | list[string] | REQUIRED | TASK ids that MUST reach `done` first; `[]` allowed | |
| `write_scope` | enum | REQUIRED | `none` \| `disjoint` \| `overlap` | parallel writes require `disjoint` |
| `parallelism_evaluated` | boolean | REQUIRED | `true` | MUST be `true`; records evaluation per `your parallelism-and-routing SPEC` §7.1 |
| `acceptance_commands` | list[string] | REQUIRED | runnable commands or `[]` with reason in §5 | subset of parent SPEC's plus task-local checks |
| `tracker_issue` | string \| null | REQUIRED | tracker identifier (e.g. `PROJ-123`) or `null` | null until decomposition reflected in tracker |

TASK.md status state machine:

```text
todo ──► in-progress ──► in-review ──► <owner sets done>
   │                          ▲
   ▼                          │
blocked ──── unblock ─────────┘
```

Idempotency: `done` is monotonic and owner-set. `blocked` is the
only reverse edge from `in-progress`.

Cross-validation gate: `in-progress → in-review` requires findings
from `cross_validation_lane` to be addressed (or explicit
justified pushback) per `skills/code-review/SKILL.md` and the
spec-review skill in your harness.

Integration gate: when ALL TASK.md in a parent SPEC's `tasks/`
directory reach `done`, the parent SPEC MAY flip
`decomposed → in-execution → verified` after running the parent's
full `acceptance_commands`. The parent SPEC's §17 / §19 Completion
Report aggregates per-task evidence.

## 2. Citation grammar

Every factual claim in IDEA.md or SPEC.md MUST carry a citation
prefix from the table below. Memory and training are NOT citable
evidence (per OPERATING_MODEL Memory Policy, input-vs-artefact
distinction).

### 2.1 Allowed prefixes

| Prefix | Form | Required surrounding context |
|---|---|---|
| `file://` | `file://<repo-relative-or-absolute-path>` | MAY include `#<line>` or `§<section>` suffix; path MUST exist at the cited commit |
| `cmd://` | `cmd://<command>` | surrounding prose MUST include the observed result or output excerpt |
| `url://` | `url://<full-url>` | surrounding prose MUST include fetch-date, OR pair with a `file://` cache reference |
| `decision-authority://<role>:<date>` | `<role>` ∈ {`owner`, `product-lead`, `tech-lead`, `governance-committee`, `<your-role>`} | binding directive; surrounding prose MUST include the verbatim quote or directive record |
| `owner://` | `owner://transcript-<YYYY-MM-DD>` | shorthand for `decision-authority://owner:<date>` in single-owner studios; surrounding prose MUST include verbatim quote |
| `judgment://owner` | literal | binding by ownership not external evidence; MUST be attributable to a decision-authority record |
| `judgment://agent-synthesis` | literal | MUST be paired with decision-authority affirmation captured via `decision-authority://` or `owner://` |

Repo-relative `file://` paths are RECOMMENDED. Absolute paths are
RECOMMENDED only when the cited file is outside the repo.

**Precondition.** The citation grammar presumes the studio has a
named decision-authority (single owner, named product lead, or
governance committee) that produces attributable directives.
Multi-stakeholder organizations without a named decision-authority
SHOULD define one before adopting the schema.

### 2.2 What constitutes a citable claim

A *citable claim* is any statement of fact, constraint, decision,
behavior, or requirement that an executor or verifier MUST rely on.
Examples: counts, file paths, line numbers, owner directives,
constraints, behavioral requirements, design decisions.

### 2.3 What does NOT require citation

The following SHALL NOT be flagged as missing citations:

- **Section headers and document structure** — `## 1. Problem` is not
  a claim.
- **Editorial framing and transitions** — "The following sections
  specify ...", "We now turn to ...".
- **Restatements within a paragraph of an already-cited claim** —
  one citation at the source statement; subsequent references in the
  same paragraph or list inherit it.
- **Definitions internal to the spec** — when the spec defines a
  term, the definition does not need an external citation.
- **References to other sections of the same document** — "see §7.6"
  is not a claim.
- **Pseudocode and reference algorithms** — line-level pseudocode
  does not require per-line citation; the algorithm as a whole is
  authored synthesis.
- **Domain model field declarations** — once declared in the Domain
  Model section, downstream sections may reference fields without
  citation.

### 2.4 Examples

**Positive — citation REQUIRED:**

1. "The repo-root `/some/path` is gitignored." → `cmd://git
   check-ignore -v some/path` (output excerpt MUST follow).
2. "Owner directed local-only repo." → `decision-authority://owner:2026-01-15`
   (verbatim quote MUST follow).
3. "External reference spec is 2169 lines." → `cmd://wc -l
   /tmp/refs/external-spec.md` (output MUST follow).
4. "OPERATING_MODEL was last updated 2026-01-15." →
   `file://OPERATING_MODEL.md` (heading line citation
   acceptable).
5. "Three failure modes follow." → `file://specs/2026-01-15-example-procedure-v1/IDEA.md`
   §1 (the producing IDEA.md is the source).

**Negative — citation NOT required:**

1. `## 6. Domain Model` — section header.
2. "The following entities are defined below." — editorial framing.
3. "An IDEA artefact has front-matter and a body." — internal
   definition.
4. "See §7.6 for the state machine." — internal cross-reference.
5. "The algorithm above iterates until convergence." — internal
   reference to in-document pseudocode.

### 2.5 Suppression escape hatch

Where the lint script flags a claim that is in fact an editorial
sentence, the author MAY append the HTML comment
`<!-- lint-ok: no-citation -->` to the offending line. Suppression
comments SHALL be sparing; pervasive suppression is itself a quality
signal and SHOULD be raised in spec review.

The companion marker `<!-- lint-ok: no-rfc -->` silences the lint's
lowercase-RFC-2119 warning for a single line; use this where a
lowercase keyword appears in unambiguously non-normative prose
(for example, a verbatim block-quote of an external source). Both
markers are line-local: `no-citation` applies to the paragraph
containing the marker, `no-rfc` applies to the line containing it.

## 3. RFC 2119 adoption rules

| Artefact / Section | Normative preamble | Keyword usage |
|---|---|---|
| `IDEA.md` | REQUIRED | constraints, recommendations, owner judgments |
| `SPEC.task.md` | REQUIRED | Desired Behavior, Acceptance Criteria, Test Plan, Safety Invariants |
| `SPEC.contract.md` | REQUIRED | throughout normative sections |
| `SPEC.decision.md` | REQUIRED only on §Decision Statement | **MUST NOT** appear outside the Decision Statement section |

Lint rules:

- Any RFC 2119 keyword MUST be uppercase to carry normative force.
- Lowercase variants ("must", "should", "may") are ordinary English
  and MUST NOT carry normative force.
- The lint script flags lowercase variants in normative sections as
  *advisory warnings* (exit 2), not blocking failures, to avoid
  false positives on ordinary English usage.

## 4. Section naming conventions

- Top-level sections: `## N. Title` with Arabic numerals.
- Sub-sections: `### N.M Title`.
- Sub-sub-sections (RECOMMENDED only when needed): `#### N.M.K Title`.
- Section titles in the shared skeleton MUST match verbatim across
  the three SPEC templates and IDEA template (e.g. "Authority Map"
  is identical wording wherever it appears).
- Front-matter `id` MUST equal the spec folder name.
- Spec id format: `<YYYY-MM-DD>-<kebab-case-topic>`.

### 4.1 Shared section skeleton

The following sections, when present, MUST have identical titles
across all spec types (Task / Contract / Decision):

- `## Normative Language` (preamble, RECOMMENDED in IDEA, REQUIRED in SPECs)
- `## Authority Map`
- `## Code/Docs Reality Check`
- `## Open Questions`
- `## Acceptance Criteria`
- `## Rollback Plan` (REQUIRED in Task, Contract; OPTIONAL in Decision)
- `## Completion Report`

Type-specific sections (e.g. Domain Model, State Specification,
Failure Model, Trade-off Comparison, Locks, Reversal Plan) appear
only in the templates that REQUIRE them; their titles are also
fixed across templates that include them.

## 5. Quality-gate handoff to `spec-review`

When `/review-spec` runs:

1. Reads front-matter `type`.
2. Selects the per-type quality gate
   (`task` → bar b, `contract` → bar c, `decision` → bar b + candidates).
3. Runs `lint-spec.sh` on the artefact (REQUIRED for `contract`,
   RECOMMENDED for `task` and `decision`).
4. Produces a structured Quality Gate Result with `pass`, `failures`
   (with `criterion`, `evidence`, `severity`).
5. Sets `status: needs-revision` on any blocking failure;
   `status: approved-pending-owner` on a clean pass.
6. Owner sets `status: approved` after reviewing the Quality Gate
   Result and the SPEC.

The `spec-review` skill MUST NOT set `status: approved`.

## 6. Cross-references

- Templates: `templates/SPEC.task.template.md`,
  `templates/SPEC.contract.template.md`,
  `templates/SPEC.decision.template.md`,
  `templates/SPEC.fastpath.template.md`,
  `templates/IDEA.template.md`,
  `templates/TASK.template.md`.
- Lint script: `scripts/lint-spec.sh`.
- Skill validator: `scripts/validate-skill-frontmatter.sh`.
- Procedure-only skills: `skills/verification/SKILL.md`,
  `skills/code-review/SKILL.md`, `skills/release-pr/SKILL.md`,
  `skills/spec-evidence-governance/SKILL.md`,
  `skills/diagnosis/SKILL.md`, `skills/tdd/SKILL.md`.
- Operating model: `OPERATING_MODEL.md`.
