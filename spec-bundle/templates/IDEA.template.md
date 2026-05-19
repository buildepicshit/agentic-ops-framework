---
id: [kebab-case-slug]
spec_id: [YYYY-MM-DD-kebab-case-slug]
status: draft
owner: [owner-identifier]
brainstormed_by: [agent-identifier]
brainstormed_on: [YYYY-MM-DD]
implies_spec_type: [task|contract|decision]
---

<!--
Template per `specs/2026-01-15-example-procedure-v1/SPEC.md` §9.1.
Refer to `templates/SPEC.schema.md` for shared conventions
(front-matter, citation grammar, RFC 2119 rules, section naming).

Citation discipline: every factual claim in this artefact MUST carry a
citation prefix from SPEC.schema.md §2.1 (`file://`, `cmd://`, `url://`,
`owner://`, `judgment://owner`, `judgment://agent-synthesis`). Memory
and training are NOT citable evidence. Any `judgment://agent-synthesis`
claim MUST be paired with owner-affirmation captured via `owner://`.
-->

# [Working Title]

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem Seed

<!-- guidance: state the problem in concrete terms. Cite affected files,
observed behavior, owner directives, or external references. Each
factual claim carries a citation prefix. -->

[Problem statement with citations.]

## 2. Substance Citations

<!-- guidance: enumerate the substantive sources this IDEA draws on:
existing code, prior specs, owner statements, external benchmarks.
Each entry is a citation; surrounding prose explains its relevance. -->

- `file://[path]` — [why it matters].
- `owner://transcript-[YYYY-MM-DD]` — [verbatim quote follows below].
- `url://[full-url]` — [fetch-date or `file://` cache pair].

## 3. Constraints & Non-Negotiables

<!-- guidance: list constraints that bound the design space. Each
constraint MUST be either externally cited or attributed to
`judgment://owner` (binding by ownership) with transcript backing. -->

- [Constraint 1.] (`[citation]`)
- [Constraint 2.] (`[citation]`)

## 4. Approaches Considered

<!-- guidance: minimum 2-3 approaches. For each: name, sketch,
fit-with-substance, fit-with-constraints, cost, risk. Synthesis claims
use `judgment://agent-synthesis` and MUST be paired with owner
affirmation in §7. -->

### 4.1 [Approach A]

- Sketch: [one-paragraph description].
- Fit: [substance/constraints fit].
- Cost: [effort, scope].
- Risk: [what breaks].

### 4.2 [Approach B]

- Sketch: [...].
- Fit: [...].
- Cost: [...].
- Risk: [...].

### 4.3 [Approach C — OPTIONAL]

- Sketch: [...].
- Fit: [...].
- Cost: [...].
- Risk: [...].

## 5. Recommendation

<!-- guidance: name the recommended approach and why. If the
recommendation is `judgment://agent-synthesis`, §7 MUST capture the
owner affirmation that binds it. -->

[Recommended approach name and rationale.] (`judgment://agent-synthesis`,
affirmed in §7 — see `owner://transcript-[YYYY-MM-DD]`)

## 6. Open Questions for Owner

<!-- guidance: every Open Question MUST be either resolved (move to §7)
or marked `owner-blocking`. Unresolved questions block the IDEA quality
gate (§10.1 of the authority spec). -->

- [ ] [Question 1.] — `owner-blocking` | resolved in §7
- [ ] [Question 2.] — `owner-blocking` | resolved in §7

## 7. Owner Judgments

<!-- guidance: for each owner judgment captured during ideation, paste
the verbatim transcript quote and tag with `owner://transcript-<date>`.
Owner affirmations of `judgment://agent-synthesis` claims live here. -->

- `owner://transcript-[YYYY-MM-DD]`:
  > [verbatim quote]
  Binds: [which claim or recommendation this affirms].
