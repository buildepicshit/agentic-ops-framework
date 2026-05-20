---
id: [YYYY-MM-DD-kebab-case-topic]
status: draft
type: contract
owner: [owner-identifier]
repo: [repo-name]
branch_policy: worktree-preferred
risk: medium
requires_network: false
requires_secrets: []
acceptance_commands: []
ideated_in: [repo-relative-path-to-IDEA.md]
---

<!--
Template per `specs/2026-01-15-example-procedure-v1/SPEC.md` §9.3.
Refer to `spec-bundle/schema/SPEC.schema.md` for shared conventions
(front-matter ordering, citation grammar, RFC 2119 rules, section
naming). The shared section titles `## Authority Map`,
`## Code/Docs Reality Check`, `## Open Questions`,
`## Acceptance Criteria`, `## Rollback Plan`, `## Completion Report`
MUST appear with byte-identical text-after-number across the three
SPEC templates.

Quality gate: bar (c) "protocol-grade", with REQUIRED `lint-spec.sh`
pass — see authority §10.3.
-->

# SPEC: [Contract Title]

Status: [Draft v1 | ...]
Type: Contract
Purpose: [one-paragraph statement of what this contract specifies].

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

`Implementation-defined` means the behavior is part of the contract
but this specification does not prescribe a single universal policy.
Implementations MUST document the selected behavior in the affected
artefact.

## 1. Problem Statement

<!-- guidance: state the contract's reason-for-being. Cite the
producing IDEA.md and any owner directives. Three-failure-mode
framing is RECOMMENDED.

Capture-after defer-shorthand (status: verified only): per
`file://spec-bundle/schema/SPEC.schema.md` §1.3 and the 2026-01-15
ceremony-weight-refactor Decision SPEC §7, when this SPEC lands
at `status: verified` via the capture-after exception, this
section MAY be a one-paragraph cite-by-id pointer to the
producing IDEA's §1 — e.g. "See `file://specs/<id>/IDEA.md` §1
for the problem statement (capture-after defer)." The lint
recognises this shorthand only when status is verified AND the
IDEA is cited. -->

[Problem statement with citations.]

Owner directive (`owner://transcript-[YYYY-MM-DD]`, captured in
[IDEA.md path] §[N]):

> [verbatim quote]

## 2. Goals and Non-Goals

### 2.1 Goals

- REQUIRED: [Goal 1.]
- REQUIRED: [Goal 2.]
- RECOMMENDED: [Goal 3.]

### 2.2 Non-Goals

- NOT [excluded scope 1].
- NOT [excluded scope 2].

## 3. System Overview

### 3.1 Components

<!-- guidance: name the components, abstraction layers, and
responsibilities. -->

1. [Component A] — [responsibility].
2. [Component B] — [responsibility].

### 3.2 External dependencies

- [Tool / library / runtime] — [version, why required].

## 4. Authority Map

Active authority for this SPEC:

- `file://[path]`: [why authoritative].
- `owner://transcript-[YYYY-MM-DD]`: [verbatim quote follows below].

Stale, superseded, or evidence-only sources:

- `file://[path]`: [how to treat].

Owner decisions required before implementation:

- [ ] [Decision.]

## 5. Code/Docs Reality Check

| Surface | Current claim | Observed reality | Required action |
|---|---|---|---|
| `file://[path]` | [claim] | [observed] | [align/supersede/implement/defer] |

## 6. Domain Model

### 6.1 Entities

<!-- guidance: full schemas. Each field declared here MAY be referenced
in downstream sections without re-citing (per SPEC.schema.md §2.3). -->

#### 6.1.1 [Entity name]

[Description.]

Fields:

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `[field]` | [type] | REQUIRED \| OPTIONAL | [enum or `*`] | [notes] |

Invariants:

- [Invariant 1.]

### 6.2 Stable identifiers and normalization

- [Identifier format rule.]
- [Normalization rule.]

## 7. [Behavior / Pipeline / State] Specification

<!-- guidance: this is the contract body. Sub-sections per state,
transition, or component. When behavior is stateful, name the state
machine with states, transitions, triggers, and idempotency rules. -->

### 7.1 [State or phase 1]

[Specification.]

### 7.2 [State or phase 2]

[Specification.]

### 7.3 State machine

```text
[states and transitions diagram]
```

Idempotency: [rules for repeated invocations].

## 8. Schema Specification

<!-- guidance: REQUIRED only when the contract defines schemas
(front-matter, file formats, message shapes). Otherwise mark `N/A`
with reason. -->

### 8.1 [Schema name]

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `[field]` | [type] | REQUIRED | [enum] | [notes] |

Example:

```yaml
[example]
```

## 9. Reference Algorithms

<!-- guidance: pseudocode for non-trivial logic. Pseudocode and
reference algorithms do NOT require per-line citation
(per SPEC.schema.md §2.3); the algorithm as a whole is authored
synthesis. -->

### 9.1 Algorithm: [name]

```text
function [name](inputs):
  [pseudocode]
  return [outputs]
```

## 10. Failure Model

<!-- guidance: REQUIRED. Each failure class names cause, recovery,
partial-state behavior, idempotency. -->

### 10.1 [Failure class 1]

- Cause: [...].
- Recovery: [...].
- Idempotent: [yes/no with rationale].

### 10.2 [Failure class 2]

- Cause: [...].
- Recovery: [...].
- Idempotent: [yes/no with rationale].

## 11. Trust Boundary / Security

<!-- guidance: REQUIRED. Identify the trust boundary, authority chain,
secrets handling, hook/script safety, and any subagent execution
boundary. -->

### 11.1 [Boundary 1]

[Specification.]

### 11.2 Secrets

[Secrets handled, or `none — requires_secrets: []`.]

## 12. Observability

<!-- guidance: REQUIRED. How operators and verifiers see the system's
state, signals, and provenance trail. -->

### 12.1 [Signal 1]

- Stdout / stderr: [...].
- Exit codes: [...].
- Logs: [...].

### 12.2 [Provenance / status visibility]

[Specification.]

## 13. Test and Validation Matrix

<!-- guidance: 1:1 with Acceptance Criteria in §15. No orphan tests; no
unverified criteria. Each row has a unique Test ID referenced from §15
and §14.

Capture-after defer-shorthand (status: verified only): when this
SPEC lands at `status: verified` via the capture-after exception
(`file://spec-bundle/schema/SPEC.schema.md` §1.3) and the validation
matrix is fully exercised by the front-matter `acceptance_commands`
plus a citation to the producing IDEA's §13, this section MAY be
a one-paragraph cite-by-id pointer to the IDEA — e.g. "See
`file://specs/<id>/IDEA.md` §13 (capture-after defer); the
front-matter `acceptance_commands` constitute the validation
matrix in this mode." Lint enforces this shorthand only when
status is verified AND the IDEA is cited. -->

| Test ID | What is verified | Method | Severity |
|---|---|---|---|
| T01 | [criterion 1] | [command / manual] | Blocking |
| T02 | [criterion 2] | [command / manual] | Blocking |
| T03 | [criterion 3] | [command / manual] | Advisory |

## 14. Implementation Checklist (Definition of Done)

<!-- guidance: mirrors §13. Each box maps to a Test ID. -->

- [ ] T01 [name]
- [ ] T02 [name]
- [ ] T03 [name]

## 15. Acceptance Criteria

<!-- guidance: each criterion references a Test ID in §13 1:1. RFC 2119
keywords carry normative force here. Front-matter `acceptance_commands`
MUST be non-empty OR explicitly `[]` with a reason in §17 Open
Questions. -->

- [ ] (T01) [Criterion 1.]
- [ ] (T02) [Criterion 2.]
- [ ] (T03) [Criterion 3.]

## 16. Rollback Plan

<!-- guidance: per-component rollback preferred. Provenance discipline
makes reverts identifiable when this contract spans multiple repos. -->

[Rollback procedure with concrete commands or git operations.]

## 17. Open Questions

<!-- guidance: per the 2026-01-15 ceremony-weight-refactor
Decision SPEC §7, this section is OPTIONAL when empty. "Empty"
means the body contains only `None.`, `N/A`, or a single
resolved citation to the producing IDEA's §6 / §7. The section
heading itself MAY be omitted entirely when no open questions
remain. -->

- [ ] [Question that MUST be answered before approval.]

OR (when no open questions remain):

`None. All design questions resolved in
file://specs/<id>/IDEA.md §6.`

OR omit the section entirely.

## 18. Migration / Coexistence

<!-- guidance: REQUIRED when prior versions exist; otherwise mark
`N/A` with reason. -->

### 18.1 Existing artefacts

[How prior-version artefacts are treated: migrated, frozen as historical,
or deprecated.]

### 18.2 In-flight work

[How work-in-progress under prior version is handled.]

## 19. Completion Report

<!-- guidance: filled by executor/verifier. Subagents MUST NOT modify
any other section. Append, never overwrite. -->

### 19.1 Files changed

(to be filled)

### 19.2 Commands run

(to be filled — paste relevant excerpts of `acceptance_commands` outputs)

### 19.3 Verification result

(to be filled)

### 19.4 Residual risk

(to be filled)

### 19.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
