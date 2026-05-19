# Per-Type Gate Criteria

Detailed criteria for each gate type. Authority:
`file://examples/reference-procedure-spec` §10.
When this file and that SPEC diverge, the SPEC wins and this file
MUST be updated to match.

All criteria are **blocking** unless tagged `advisory`.

## Contents

- IDEA gate (§10.1)
- Task SPEC gate, bar (b) "verifiable" (§10.2)
- Contract SPEC gate, bar (c) "the autonomous-dispatch runner-grade" (§10.3)
- Decision SPEC gate, bar (b) + candidate-comparison (§10.4)
- Studio-principle Decision SPECs — additional verbatim-to-normative
  trace check

## IDEA gate (§10.1)

- All REQUIRED IDEA sections (§9.1) present and non-empty (or
  explicit `N/A: <reason>`).
- Every factual claim carries a citation prefix from the allowed
  grammar (`file://`, `cmd://`, `url://`, `owner://`,
  `judgment://owner`, `judgment://agent-synthesis`) per
  SPEC.schema §2.
- Every Owner Judgment in §7 is attributed with a verbatim
  transcript quote.
- Every `judgment://agent-synthesis` claim is paired with owner-
  affirmation in transcript.
- Every Open Question is either resolved or explicitly marked
  `owner-blocking` (the latter blocks transition to
  `ready-for-spec`).
- `implies_spec_type` front-matter is set to `task`, `contract`, or
  `decision`.
- RFC 2119 keywords used in the IDEA are uppercase. Lowercase
  variants in normative-feeling sentences are advisory (severity
  `advisory`).

## Task SPEC gate, bar (b) "verifiable" (§10.2)

- All REQUIRED Task SPEC sections (§9.2) present and non-empty.
- Every external fact cites a source per SPEC.schema §2.
- Every entity in the Domain Model section has a full schema
  (type, nullability; example RECOMMENDED).
- All Acceptance Criteria are checkbox items; each is paired with
  a Test Plan entry.
- Front-matter `acceptance_commands` is non-empty, OR set to `[]`
  with an explicit reason in the Acceptance Criteria section.
- All Open Questions resolved or marked `owner-blocking` (latter
  blocks approval).
- RFC 2119 keywords uppercase.

## Contract SPEC gate, bar (c) "the autonomous-dispatch runner-grade" (§10.3)

- All Task gate (bar b) criteria above, applied where they fit
  Contract sections.
- Normative Language preamble present.
- Test and Validation Matrix is 1:1 with Acceptance Criteria — no
  orphan tests, no unverified criteria.
- Definition of Done checklist mirrors the Test Matrix.
- When behavior is stateful, a state machine is named with states,
  transitions, triggers, and idempotency rules.
- Pseudocode for non-trivial algorithms.
- Failure Model section present with failure classes and recovery
  behavior.
- Observability section present.
- Trust Boundary / Security section present.
- `scripts/lint-spec.sh` exits 0 on this SPEC (exit 2 is
  advisory and does not block; exit 1 is blocking).

## Decision SPEC gate, bar (b) + candidate-comparison (§10.4)

- Task gate (bar b) criteria above, applied where they fit Decision
  sections.
- Candidate Options table has ≥ 2 candidates, each with all
  required fields (description, fit-with-substance,
  fit-with-constraints, cost, risk).
- Decision Criteria are sourced (substance citation or
  `judgment://owner`).
- Trade-off Comparison present.
- Decision Statement present, in RFC 2119 normative language. RFC
  2119 keywords MUST NOT appear elsewhere in a Decision SPEC
  (SPEC.schema §3).
- Locks section present (MAY state `no locks` with reason).
- Reversal Plan present (MAY state `irreversible: <reason>`).

### Fleet-principle Decision SPECs — additional check

When the SPEC slug matches `principle-*` (per
`file://skills/spec-authoring/SKILL.md`), apply the
**verbatim-to-normative trace** check in addition to the standard
Decision gate:

- Every RFC 2119 clause in §7 Decision Statement MUST trace back
  to a specific owner verbatim (`owner://transcript-<date>` quote)
  or to a `judgment://owner` capture in the upstream IDEA.
- Failure mode: a normative clause with no upstream owner anchor
  signals the principle is being authored ahead of owner intent.
  Record as `criterion: principle-not-owner-anchored`,
  `severity: blocking`; route to `needs-revision`.
- Authority:
  `judgment://agent-synthesis`
  §5 ("Trace-from-verbatim-to-normative is the principle SPEC
  quality signature").

The check is the principle SPEC's quality signature; lint catches
the structural failure (uncited claims) but not the semantic walk
from owner verbatim through IDEA decomposition into the specific §7
clause. The walk is a `spec-review` responsibility for principle
SPECs.
