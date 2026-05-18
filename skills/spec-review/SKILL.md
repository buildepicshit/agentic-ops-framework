---
name: spec-review
description: "Use as the BLOCKING per-type quality gate after authoring or revising an IDEA.md or SPEC.md. Selects Task/Contract/Decision bar from front-matter, runs lint-spec.sh (REQUIRED for Contract), emits a Quality Gate Result, transitions status to needs-revision or approved-pending-owner. Never sets status: approved (owner-only). Do not use to author specs — use spec-authoring."
---

# Spec Review

Authority: `file://examples/reference-procedure-spec`
§10, §11.3, §17.3. Shared schema:
`file://templates/SPEC.schema.md` §5.

This skill is **BLOCKING**. A spec MUST NOT advance to
`approved-pending-owner` while any blocking criterion fails. The
skill MUST NOT set `status: approved` — only the owner does that
(SPEC §7.6, schema §1.3).

Per-type gate criteria live in
[`references/per-type-gates.md`](references/per-type-gates.md). Read
that file as part of running the gate; this SKILL.md governs
selection, mechanics, and output.

## When to use

- A primary or sub agent has just authored or revised a `SPEC.md`
  and needs the gate to determine whether the spec is ready for
  owner approval.
- A primary agent has just run `/idea-capture` and needs the IDEA
  gate (§10.1) to determine whether the IDEA can transition from
  `draft` to `ready-for-spec`.
- Any review-time event re-opens a previously-approved spec for
  owner reconsideration (rare; typically owner-driven via
  `status: needs-revision`).

Companion workflow: `agents/workflows/review-spec.md`
(`/review-spec`).

## Inputs

- `spec_path` — repo-relative path to the artefact under review.
  MUST be either `<spec-folder>/SPEC.md` or
  `<spec-folder>/IDEA.md`.
- Front-matter is parsed first. The skill REQUIRES:
  - `type` (`task` | `contract` | `decision`) for SPEC.md, OR
  - `implies_spec_type` (`task` | `contract` | `decision`) for
    IDEA.md.
  If front-matter is missing or malformed, the run aborts with a
  blocking failure of `criterion: front-matter-parse`.

## Gate selection

Per SPEC §10 and SPEC.schema §5:

| Artefact | Gate | Bar | Lint requirement |
|---|---|---|---|
| `IDEA.md` | §10.1 IDEA gate | n/a | RECOMMENDED |
| `SPEC.md` with `type: task` | §10.2 Task gate | `b` (verifiable) | RECOMMENDED |
| `SPEC.md` with `type: contract` | §10.3 Contract gate | `c` (the autonomous-dispatch runner-grade) | **REQUIRED** |
| `SPEC.md` with `type: decision` | §10.4 Decision gate | `b-plus-candidates` | RECOMMENDED |

Detailed per-type criteria, including studio-principle additional
checks: see `references/per-type-gates.md`.

## Lint invocation

For `type: contract`, the skill MUST run:

```
bash scripts/lint-spec.sh <spec_path>
```

Exit-code mapping:

- `0` — pass; no lint failure recorded.
- `1` — blocking failure; record one entry per stderr diagnostic
  with `severity: blocking`.
- `2` — advisory only; record entries with `severity: advisory`.
  Does not block transition to `approved-pending-owner`.

For `type: task`, `type: decision`, and IDEA.md, lint is
RECOMMENDED. The skill SHOULD run it and record advisory entries;
it MUST NOT treat lint exit 1 as blocking for these types unless
the gate otherwise requires the underlying check.

## Contract capture-after defer-shorthand check (2026-05-17)

Per the 2026-05-17 ceremony-weight-refactor Decision SPEC §7,
Contract SPECs landing at `status: verified` via the
capture-after exception MAY use a one-paragraph defer-shorthand
in §1 Problem Statement and §13 Test and Validation Matrix. The
shorthand pattern: a single paragraph whose only substantive
content is a `file://specs/<id>/IDEA.md` cite pointing at the
producing IDEA's §1 / §13.

The Contract per-type gate MUST add the following BLOCKING
check when the SPEC under review has `status: verified` AND
either §1 or §13 body appears to be defer-shorthand
(≤ 3 non-blank non-comment lines, all citation-prefixed,
including a `file://specs/<id>/IDEA.md` cite):

1. Resolve the cited IDEA section by path.
2. Read its body.
3. REQUIRED: the cited IDEA section MUST exist and contain at
   least 5 non-blank non-comment lines of substantive content
   (the defer must resolve to real substance, not to another
   defer).
4. On failure: emit a blocking diagnostic
   `capture-after-defer-shorthand: cited IDEA §<n> does not
   resolve to substantive content`. Status: `needs-revision`.

For Contracts at any other status (`draft`, `approved`,
`in-execution`), defer-shorthand in §1 or §13 MUST be rejected
with: `capture-after-defer-shorthand: not permitted at status:
<status>; defer-shorthand requires status: verified`. Status:
`needs-revision`.

This check is BLOCKING per
`file://specs/2026-05-17-ceremony-weight-refactor/SPEC.md` §7
"the Contract per-type gate verifying that any capture-after
defer-shorthand resolves to a cited IDEA section".

## Quality Gate Result

Output is a structured record per SPEC §6.1.4:

```yaml
spec_path: specs/<id>/SPEC.md         # or IDEA.md
type: contract                         # task | contract | decision
bar: c                                 # b | c | b-plus-candidates
pass: false
failures:
  - criterion: required-section-missing
    evidence: file://specs/<id>/SPEC.md missing "## 10. Failure Model"
    severity: blocking
  - criterion: lint
    evidence: cmd://bash scripts/lint-spec.sh specs/<id>/SPEC.md (exit 1, "uncited claim at SPEC.md:142")
    severity: blocking
  - criterion: rfc2119-uppercase
    evidence: file://specs/<id>/SPEC.md#L88 "must" lowercase in normative section
    severity: advisory
```

Schema:

- `spec_path` (string, REQUIRED).
- `type` (enum, REQUIRED) — `task` | `contract` | `decision`. For
  IDEA.md, use the IDEA's `implies_spec_type`.
- `bar` (enum, REQUIRED) — `b` | `c` | `b-plus-candidates`. For
  IDEA.md, use literal string `idea`.
- `pass` (boolean, REQUIRED) — `true` iff `failures` contains zero
  entries with `severity: blocking`.
- `failures` (list, REQUIRED, MAY be empty):
  - `criterion` (string, REQUIRED) — short slug (e.g.
    `required-section-missing`, `uncited-claim`, `lint`,
    `acceptance-criteria-orphan`,
    `decision-fewer-than-2-candidates`).
  - `evidence` (string, REQUIRED) — file/line citation per
    SPEC.schema §2 citation grammar.
  - `severity` (enum, REQUIRED) — `blocking` | `advisory`.

Citation discipline applies to the result itself. Every `evidence`
field MUST use a citation prefix (`file://`, `cmd://`, etc.) so
the result is itself contract-grade.

## Status transitions

Pre-condition: `<spec_path>` exists with parseable front-matter and
a status appropriate for review (typically `draft` or
`needs-revision`).

Algorithm (per SPEC §17.3):

```
let result = run_per_type_gate(spec_path)
if type == "contract":
  let lint_exit = run_lint(spec_path)
  if lint_exit == 1: append failure(criterion="lint", severity="blocking", evidence=...)
  if lint_exit == 2: append failure(criterion="lint", severity="advisory", evidence=...)
let blocking = any(f.severity == "blocking" for f in result.failures)
if blocking:
  set front-matter status: needs-revision
  result.pass = false
else:
  set front-matter status: approved-pending-owner   # only for SPEC.md
  result.pass = true
emit result
```

Concrete transitions:

| Artefact | Status before | Blocking failure? | Status after |
|---|---|---|---|
| `SPEC.md` | `draft` | yes | `needs-revision` |
| `SPEC.md` | `draft` | no | `approved-pending-owner` |
| `SPEC.md` | `needs-revision` | yes | `needs-revision` (idempotent re-run) |
| `SPEC.md` | `needs-revision` | no | `approved-pending-owner` |
| `IDEA.md` | `draft` | yes | `draft` (no transition; surface failures) |
| `IDEA.md` | `draft` | no | `ready-for-spec` |
| `IDEA.md` | `owner-blocking` | (any) | `owner-blocking` (no transition; only owner moves out) |

The skill MUST NOT set `status: approved` on a SPEC.md under any
condition. The owner sets `approved` after reviewing the Quality
Gate Result and the SPEC (SPEC §7.6).

If front-matter status is already a terminal or post-approval
value (`approved`, `in-execution`, `verified`, `closed`), the skill
MUST refuse to run with a blocking failure of
`criterion: status-not-reviewable` and MUST NOT mutate the
artefact.

## Hard rules

- The skill MUST NOT set `status: approved`. Only the owner does.
- The skill MUST NOT silently revise spec content. It MAY only
  mutate front-matter `status` per the table above.
- The skill MUST surface every blocking failure with a file/line
  citation. "Vague" findings without citation are themselves a
  quality failure of the review.
- The skill MUST NOT allow implementation scope to hide inside
  Open Questions. Open Questions that imply substantive design
  choices MUST be flagged with
  `criterion: scope-hidden-in-open-question`, `severity: blocking`.
- The skill MUST NOT review for style before correctness and
  safety. Editorial polish is advisory at most.
- Lint exit 1 on a Contract SPEC is blocking even if the gate
  otherwise passes. Lint exit 2 is advisory.
- **Cross-family review.** When the SPEC was authored primarily by
  a model in one family (the agent runner / Claude), the spec-review pass
  SHOULD be performed by a model from a different family. Same-
  family review is structurally weaker. If the only available
  reviewer is from the same family as the author, record this in
  the Quality Gate Result `evidence` field as
  `same-family-review: <model>` and surface it as an `advisory`
  finding. See `file://your model-routing policy` "Routing Matrix"
  row for Spec review and
  `file://specs/2026-05-04-agent-parallelism-and-model-routing-v2/SPEC.md`
  §7.3.

## Output to caller

After running the gate the skill MUST emit, in this order:

1. The Quality Gate Result block (YAML, schema above).
2. A short prose summary leading with blocking findings, ordered
   by severity, each with a file/line citation.
3. A recommendation line, one of:
   - `approve-pending-owner` (status set to
     `approved-pending-owner`; owner now reviews).
   - `block-needs-revision` (status set to `needs-revision`;
     author addresses failures and re-runs review).
   - `idea-ready-for-spec` (IDEA-mode pass; status set to
     `ready-for-spec`).
   - `idea-blocked` (IDEA-mode failure; status unchanged at
     `draft` or `owner-blocking`).

## Cross-references

- Authority:
  `file://examples/reference-procedure-spec`
  §10, §11.3, §17.3.
- Per-type criteria:
  `file://skills/spec-review/references/per-type-gates.md`.
- Shared schema: `file://templates/SPEC.schema.md` §5
  (handoff), §1.3 (state machine), §2 (citation grammar), §3
  (RFC 2119).
- Companion workflow: `file://agents/workflows/review-spec.md`.
- Lint script: `file://scripts/lint-spec.sh` (if absent at
  the time of invocation, a Contract SPEC review MUST report
  `criterion: lint-unavailable`, `severity: blocking`).
- Authoring side: `file://skills/spec-authoring/SKILL.md`.
- Lifecycle skill:
  `file://skills/spec-driven-development/SKILL.md`.
