---
id: [YYYY-MM-DD-kebab-case-topic]
status: draft
type: decision
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
Template per `specs/2026-01-15-example-procedure-v1/SPEC.md` §9.4.
Refer to `spec-bundle/schema/SPEC.schema.md` for shared conventions
(front-matter ordering, citation grammar, RFC 2119 rules, section
naming). The shared section titles `## Authority Map`,
`## Open Questions`, `## Acceptance Criteria`, `## Completion Report`
MUST appear with byte-identical text-after-number across the three
SPEC templates. (`## Code/Docs Reality Check` and `## Rollback Plan`
are OPTIONAL in Decision specs per SPEC.schema.md §4.1.)

Quality gate: bar (b) + candidate-comparison structure — see
authority §10.4.

CRITICAL: RFC 2119 keywords (`MUST`, `MUST NOT`, `REQUIRED`, `SHALL`,
`SHALL NOT`, `SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, `OPTIONAL`)
appear ONLY in §7. Decision Statement. They MUST NOT appear in any
other section of this template (per SPEC.schema.md §3). Lowercase
"must"/"should"/"may" in ordinary English are permitted elsewhere but
carry no normative force.
-->

# SPEC: [Decision Title]

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

In Decision SPECs, RFC 2119 keywords appear ONLY in §7. Decision
Statement. They do not appear in any other section of this document.

## 1. Problem

<!-- guidance: state the choice that needs making. Cite the producing
IDEA.md and the owner directive that surfaced this decision. Plain
English only — no RFC 2119 keywords. -->

[Statement of the choice with citations.]

## 2. Substance Citations

<!-- guidance: enumerate substantive sources informing this decision:
prior specs, owner statements, external benchmarks, code reality. -->

- `file://[path]` — [why it matters].
- `owner://transcript-[YYYY-MM-DD]` — [verbatim quote follows].
- `url://[full-url]` — [fetch-date or `file://` cache pair].

## 3. Authority Map

Active authority for this decision:

- `file://[path]`: [why authoritative].
- `owner://transcript-[YYYY-MM-DD]`: [verbatim quote].

Stale, superseded, or evidence-only sources:

- `file://[path]`: [how to treat].

Owner decisions required before implementation:

- [ ] [Decision.]

## 4. Decision Criteria

<!-- guidance: each criterion sourced from substance citation or
`judgment://owner`. No RFC 2119 keywords here. -->

| Criterion | Source | Weight |
|---|---|---|
| [Criterion 1] | `file://[path]` or `judgment://owner` | [high/med/low] |
| [Criterion 2] | `[citation]` | [...] |

## 5. Candidate Options

<!-- guidance: minimum 2 candidates, each with all required fields.
Per authority §10.4 quality gate. -->

### 5.1 [Candidate A]

- Description: [...].
- Fit with substance: [...].
- Fit with constraints: [...].
- Cost: [...].
- Risk: [...].

### 5.2 [Candidate B]

- Description: [...].
- Fit with substance: [...].
- Fit with constraints: [...].
- Cost: [...].
- Risk: [...].

### 5.3 [Candidate C — OPTIONAL]

- Description: [...].
- Fit with substance: [...].
- Fit with constraints: [...].
- Cost: [...].
- Risk: [...].

## 6. Trade-off Comparison

<!-- guidance: criteria × candidates matrix. -->

| Criterion | [Candidate A] | [Candidate B] | [Candidate C] |
|---|---|---|---|
| [Criterion 1] | [score / note] | [score / note] | [score / note] |
| [Criterion 2] | [...] | [...] | [...] |

## 7. Decision Statement

<!-- guidance: THIS IS THE ONLY SECTION WHERE RFC 2119 KEYWORDS APPEAR.
State the chosen option in normative language. Be specific and
verifiable. -->

The fleet SHALL adopt [Candidate X].

[Candidate X] MUST [normative consequence 1].
[Candidate X] MUST NOT [foreclosed behavior].
Implementations of [Candidate X] SHOULD [recommended pattern].
Implementations MAY [optional extension].

## 8. Decision Rationale

<!-- guidance: cite the trade-off matrix (§6) and owner judgments. No
RFC 2119 keywords here. -->

[Candidate X] was chosen because [...]. (`file://[path]` §6 trade-off
matrix; `owner://transcript-[YYYY-MM-DD]` affirmation.)

[Candidate Y] was rejected because [...].

## 9. Locks

<!-- MANDATORY section per authority §9.4. State what this decision
unlocks and what it forecloses. May state `no locks` with reason. No
RFC 2119 keywords here. -->

Unlocks:

- [Subsequent work or design freedom now available.]

Forecloses:

- [Path no longer available without revisiting this decision.]

OR: `no locks` — [reason: e.g. this decision is purely informational
and does not constrain downstream work].

## 10. Reversal Plan

<!-- MANDATORY section per authority §9.4. State what triggers
reconsidering this decision and how to exit cleanly. May state
`irreversible: <reason>`. No RFC 2119 keywords here. -->

Triggers for reconsideration:

- [Signal 1 that would prompt a follow-on Decision spec.]
- [Signal 2.]

Exit procedure:

1. [Step to reverse the decision: e.g. supersede with a new Decision
   SPEC; revert affected commits; notify dependents.]
2. [...]

OR: `irreversible: [reason — e.g. external commitment, structural
choice that cannot be unwound without rebuilding from scratch]`.

## 11. Validation Plan

<!-- guidance: decision well-formedness checks; for technical decisions,
basic-feasibility evidence. No RFC 2119 keywords here. -->

- [Check 1: candidates are real and distinct.]
- [Check 2: chosen option is feasible — cite spike, prototype, or prior
  art.]
- [Check 3: Locks and Reversal Plan are populated and coherent.]

## 12. Acceptance Criteria

<!-- guidance: each criterion is a checkbox item. No RFC 2119 keywords
here — these are verification statements, not normative requirements
(those live in §7). Front-matter `acceptance_commands` is non-empty OR
explicitly `[]` with reason in §13 Open Questions. -->

- [ ] AC-1: Decision Statement (§7) names exactly one chosen option.
- [ ] AC-2: At least 2 candidates compared in §5 with all required
      fields populated.
- [ ] AC-3: Trade-off matrix (§6) is complete for all candidates and
      criteria.
- [ ] AC-4: Locks (§9) and Reversal Plan (§10) are populated (or
      explicit `no locks` / `irreversible` with reason).
- [ ] AC-5: Decision Rationale (§8) cites the trade-off matrix and
      owner judgment.
- [ ] AC-6: Completion Report §14 records when and how the decision
      was communicated to dependents.

## 13. Open Questions

<!-- guidance: every Open Question is resolved or marked
`owner-blocking` before approval. No RFC 2119 keywords here. -->

- [ ] [Question that needs an answer before approval.]

## 14. Completion Report

<!-- guidance: filled by executor/verifier. Subagents do not modify any
other section. Append, never overwrite. -->

### 14.1 Files changed

(to be filled)

### 14.2 Commands run

(to be filled)

### 14.3 Verification result

(to be filled)

### 14.4 Residual risk

(to be filled)

### 14.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
