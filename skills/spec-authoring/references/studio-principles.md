# Studio Principles

Authoring discipline for studio-level principle SPECs. Fires when
the SPEC's slug matches `studio-principle-<topic>`.

The shape was established by the first such SPEC at
`file://specs/2026-05-02-studio-principle-ai/SPEC.md`; the
disposition record is at
`file://specs/2026-05-02-studio-principle-ai/SPEC_EVIDENCE.md` §1
("studio-principle-<topic> taxonomy is now established") and §3
("Cascade-by-id-citation").

## Conventions

- **Slug**: `<YYYY-MM-DD>-studio-principle-<topic>`. Reserve
  `<topic>` at IDEA-capture time; reject an IDEA whose `<topic>`
  shadows an active principle.
- **Type**: `decision`. The §7 Decision Statement carries the
  principle as RFC 2119 normative postures.
- **Structure**: Decision-with-N-postures, where each posture is
  individually load-bearing. Document conjunctivity in §8 Decision
  Rationale (i.e. removing any single posture changes the
  principle's identity).
- **Cascade**: `specs/*` does not propagate; child repos bind by
  citing the principle SPEC's `id` from their per-product SPECs.
  Forward enforcement (per-product SPEC cites principle) is
  enforceable at child review; reverse enforcement (principle
  discovers all consumers) is manual cross-repo grep.

## Review check

Studio-principle SPECs trigger an additional `spec-review` check —
the verbatim-to-normative trace — documented in
`file://skills/spec-review/references/per-type-gates.md`
under "Studio-principle Decision SPECs". Author with that check in
mind: every RFC 2119 clause in §7 MUST trace back to an owner
verbatim or a `judgment://owner` capture in the upstream IDEA.
