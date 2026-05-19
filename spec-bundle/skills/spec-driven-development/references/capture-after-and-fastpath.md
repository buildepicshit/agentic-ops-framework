# Capture-after pattern and the `fastpath` SPEC type

Extracted from
`file://spec-bundle/skills/spec-driven-development/SKILL.md` per the
references/ progressive-disclosure convention (SE1 capture in
`judgment://agent-synthesis`).

Authority: `file://spec-bundle/schema/SPEC.schema.md` §1.3 "Capture-after
exception (owner-only)"; `file://spec-bundle/skills/fast-path/SKILL.md` for
fastpath thresholds.

## When to read this

Fires only when:
- the owner explicitly directs a small reversible change and
  you are evaluating the fastpath SPEC type, OR
- the work has already shipped before the SPEC was authored
  and you are considering the capture-after exception path.

For routine IDEA → SPEC → review → approve → execute → verify →
close work, read the spine of
`file://spec-bundle/skills/spec-driven-development/SKILL.md`
directly; this reference does not apply.

## Procedure

The IDEA → SPEC → review → approve → execute → verify → close
order is the default. There is one recognized exception:
**capture-after**, which is now formalized as the **`fastpath`
SPEC type** for small, single-component, reversible owner-directed
work (see `file://spec-bundle/skills/fast-path/SKILL.md` for
thresholds). Use fastpath when ALL fast-path thresholds hold
(≤ 1 file, ≤ 50 lines, single component, no public contract
impact, no cross-session compounding risk, explicit owner
directive). Fastpath SPECs land at `status: closed` in the same
commit as the work; no IDEA, no review gate, no decomposition.

Capture-after on task/contract/decision SPECs (work landed before
SPEC filed) is still permitted under tighter conditions:

Capture-after: the owner directs an urgent fleet fix that
pre-empts the IDEA → SPEC ceremony; agents land artefacts first;
the SPEC is filed retroactively as the citable authority record.

Capture-after is acceptable ONLY when ALL of:

- The owner directive is explicit (`owner://transcript-<date>`)
  authorizing the fix without prior SPEC.
- The artefacts pass the normal lint and gate (lint-spec.sh exit
  0; skill frontmatter clean; entry-doc audit PASS; hook tests
  green).
- The SPEC is filed BEFORE the next change to the affected
  surface — capture-after never compounds.
- The retroactive SPEC lands at `status: verified` with
  Completion Report filled in the same change set as the
  artefacts (or the next commit), not weeks later.

Reference precedents:
- First exercised at
  `judgment://agent-synthesis`
  §1, dispositioned PROMOTED.
- Codified in
  `file://examples/reference-inbox-spec`
  as the inaugural-capture-after Contract.
- Formalized in the schema state machine at
  `file://spec-bundle/schema/SPEC.schema.md` §1.3 "Capture-after
  exception".

Use sparingly; the default order exists because it produces
better artefacts.
