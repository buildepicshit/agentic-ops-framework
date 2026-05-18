---
id: [YYYY-MM-DD-kebab-case-topic]
status: draft
type: task
owner: [owner-identifier]
repo: [repo-name]
branch_policy: worktree-preferred
risk: low
requires_network: false
requires_secrets: []
acceptance_commands: []
ideated_in: [repo-relative-path-to-IDEA.md]
---

<!--
Template per `specs/2026-01-15-example-procedure-v1/SPEC.md` §9.2.
Refer to `templates/SPEC.schema.md` for shared conventions
(front-matter ordering, citation grammar, RFC 2119 rules, section
naming). The shared section titles `## Authority Map`,
`## Code/Docs Reality Check`, `## Open Questions`,
`## Acceptance Criteria`, `## Rollback Plan`, `## Completion Report`
MUST appear with byte-identical text-after-number across the three
SPEC templates.

Quality gate: bar (b) "verifiable" — see authority §10.2.
-->

# SPEC: [Task Title]

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals. RFC 2119 keywords
in this Task SPEC appear in Desired Behavior, Acceptance Criteria,
Test Plan, and Safety / Scope Invariants sections.

## 1. Problem

<!-- guidance: describe the problem in concrete terms. Cite affected
files, observed behavior, and the owner directive or evidence that
makes the change matter now. Every factual claim carries a citation
prefix per SPEC.schema.md §2. -->

[Problem statement with citations.]

## 2. North Star / Product Promise

<!-- guidance: state the durable product, project, or operating promise
this work serves. For recovery work, state what the repo is trying to
become again after context loss. Ground this in checked-in docs and
owner decisions, not memory. -->

[Durable promise. Cite the canonical doc that owns the promise.]

## 3. Goals

<!-- guidance: list goals as imperatives. Each goal SHOULD be
verifiable in §13 Test Plan. -->

- [Goal 1.]
- [Goal 2.]

## 4. Non-Goals

<!-- guidance: explicitly excluded scope. Forecloses subagent
overreach. -->

- [Excluded scope.]
- [Related work deferred to another spec.]

## 5. Current System Facts

<!-- guidance: list only verified facts. Each fact MUST carry a
citation: file path, command output, owner statement. -->

- `file://[path]`: [fact].
- `cmd://[command]` → [observed result].

## 6. Authority Map

Active authority:

- `file://[path/to/current-doc.md]`: [why it is authoritative].

Stale, superseded, or evidence-only sources:

- `file://[path/to/old-doc.md]`: [how it should be treated].

Owner decisions required before implementation:

- [ ] [Decision.]

## 7. Code/Docs Reality Check

<!-- guidance: record contradictions, drift, and missing implementation
evidence. Each row MUST cite the surface in question. -->

| Surface | Current claim | Observed reality | Required action |
|---|---|---|---|
| `file://[path]` | [claim in docs] | [what code/tests/docs show] | [align, supersede, implement, or defer] |

## 8. Desired Behavior

<!-- guidance: state target behavior in terms an executor can implement
and a verifier can test. RFC 2119 keywords carry normative force here.

If this is a planning or alignment spec, state the desired authority
state: which docs become canonical, which become historical, which
questions remain owner-blocking, which implementation specs are
unlocked.

If the task needs a quality bar, design judgment, product choice,
public-release standard, or acceptance threshold, define the objective
evidence or explicit owner decision here. Do not leave the executor to
invent acceptance criteria.

If the task creates or changes content, creative direction, assets,
narrative, tuning, gameplay-feel, demo-quality, visual/audio output, or
public positioning, define the source of truth, allowed creative
latitude, provenance/licensing requirements, owner review checkpoint,
and verification criteria here. If any are unknown, leave this spec in
`draft` or `owner-blocking` status. -->

The implementation MUST [behavior 1].
The implementation MUST [behavior 2].
The implementation SHOULD [recommended behavior].
The implementation MAY [optional behavior].

## 9. Domain Model / Contract

<!-- guidance: define entities, states, schemas, invariants, inputs,
outputs, or file formats the implementation must preserve. Each entity
SHOULD have a full schema (type, nullability, example RECOMMENDED).
Use `N/A` only when the spec is purely administrative and no domain
contract is affected. -->

### 9.1 [Entity name]

| Field | Type | Required | Allowed values | Notes |
|---|---|---|---|---|
| `[field]` | [type] | REQUIRED \| OPTIONAL | [enum or `*`] | [notes] |

Invariants:

- [Invariant 1.]

## 10. Interfaces and Files

<!-- guidance: enumerate touch points. Use `N/A` if this spec
intentionally does not authorize file edits. -->

Expected touch points:

- `file://[path/to/file]`
- `file://[path/to/other-file]`

Public interfaces affected:

- [CLI/API/tool/user workflow].

## 11. Execution Plan

<!-- guidance: each step concrete enough that a worker does not choose
product, design, technical architecture, or release policy on its
own. -->

1. [Step one.]
2. [Step two.]
3. [Step three.]

## 12. Safety / Scope Invariants

<!-- guidance: invariants that MUST remain true. Files or directories
that MUST NOT be touched. Destructive actions that REQUIRE explicit
approval. Use `N/A` only when there is genuinely no meaningful safety
or scope boundary. For game work, this section usually includes
boundaries such as no content invention, no tuning guesses, no engine
imports in Core, no public actions, no asset licensing assumptions, no
unrelated repo cleanup. -->

- [Invariant that MUST remain true.]
- Files that MUST NOT be touched: `file://[path]`.
- Destructive actions REQUIRE: [explicit owner approval | written rollback].

## 13. Test Plan

<!-- guidance: each Test Plan entry pairs 1:1 with an Acceptance
Criterion in §14. No orphan tests; no unverified criteria. -->

Commands:

```bash
# fill in repo-specific verification; one block per Acceptance Criterion
```

Manual checks:

- [Check 1] — verifies §14 AC-1.
- [Check 2] — verifies §14 AC-2.

## 14. Acceptance Criteria

<!-- guidance: each criterion is a checkbox item paired with a Test
Plan entry in §13. RFC 2119 keywords carry normative force here.
Front-matter `acceptance_commands` MUST be non-empty OR explicitly `[]`
with a reason captured in §16 Open Questions or in surrounding prose
here. -->

- [ ] AC-1: [Behavior MUST match Desired Behavior §8.X.] — verified by §13 [test ref].
- [ ] AC-2: [Tests MUST pass.] — verified by §13 [test ref].
- [ ] AC-3: [Docs or operating instructions updated where REQUIRED.]
- [ ] AC-4: No unrelated changes in the worktree at completion.
- [ ] AC-5: Completion Report §17 includes verification output.
- [ ] AC-6: Acceptance criteria are objective enough that an
      executor/verifier does not need to supply product or design
      opinions.
- [ ] AC-7: Content/creative/product-quality decisions, if any, are
      fully sourced and do not require the executor to invent output
      or quality criteria.

## 15. Rollback Plan

<!-- guidance: describe how to revert or disable the change safely.
Per-component rollback preferred over all-or-nothing. -->

[Rollback procedure with concrete commands or git operations.]

## 16. Open Questions

<!-- guidance: every Open Question MUST be resolved or marked
`owner-blocking` before approval. No spec may move to implementation
while owner-blocking questions remain open. -->

- [ ] [Question that MUST be answered before approval.]
- [ ] [Subjective or ambiguous acceptance criteria that MUST be
      resolved before implementation.]

## 17. Completion Report

<!-- guidance: filled by executor/verifier. Subagents MUST NOT modify
any other section. Append, never overwrite. -->

### 17.1 Files changed

(to be filled)

### 17.2 Commands run

(to be filled — paste relevant excerpts of `acceptance_commands` outputs)

### 17.3 Verification result

(to be filled)

### 17.4 Residual risk

(to be filled)

### 17.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
