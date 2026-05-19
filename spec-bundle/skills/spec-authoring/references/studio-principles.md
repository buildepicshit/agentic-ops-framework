# Fleet-Wide Principle SPECs

Authoring discipline for SPECs that establish fleet-wide
binding principles. Fires when the SPEC's slug matches
`principle-<topic>` (or your fleet's equivalent reserved
namespace).

The pattern: a Decision SPEC whose §7 Decision Statement
states a principle as a small set of RFC 2119 normative
postures. Each posture is individually load-bearing; removing
any one changes the principle's identity.

## Conventions

- **Slug**: `<YYYY-MM-DD>-principle-<topic>`. Reserve
  `<topic>` at IDEA-capture time; reject an IDEA whose
  `<topic>` shadows an active principle.
- **Type**: `decision`. The §7 Decision Statement carries
  the principle as RFC 2119 normative postures.
- **Structure**: Decision-with-N-postures, where each
  posture is individually load-bearing. Document
  conjunctivity in §8 Decision Rationale (i.e. removing
  any single posture changes the principle's identity).
- **Cascade**: `specs/*` does not propagate; downstream
  consumers bind by citing the principle SPEC's `id` from
  their own SPECs. Forward enforcement (consumer SPEC cites
  principle) is enforceable at consumer review; reverse
  enforcement (principle discovers all consumers) is manual
  cross-repo grep.

## Review check

Principle SPECs trigger an additional `spec-review` check —
the verbatim-to-normative trace — documented in
`file://skills/spec-review/SKILL.md` under "Decision spec
review". Author with that check in mind: every RFC 2119
clause in §7 MUST trace back to an owner verbatim or a
`judgment://owner` capture in the upstream IDEA.
