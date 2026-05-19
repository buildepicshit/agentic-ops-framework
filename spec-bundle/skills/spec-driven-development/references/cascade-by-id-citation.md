# Cascade by id-citation (non-propagating SPECs)

Extracted from
`file://spec-bundle/skills/spec-driven-development/SKILL.md` per the
references/ progressive-disclosure convention (SE1 capture in
`judgment://agent-synthesis`).

## When to read this

Fires only when:
- a SPEC binds work in child repos but does NOT mutate
  `agents/*` content (typical of Decision SPECs encoding
  studio-level principles, taxonomies, or cross-repo
  policies), AND
- you are an author or reviewer evaluating how the SPEC's
  bindings reach the children.

For SPECs that DO mutate `agents/*` content, the standard
`file://scripts/fleet-sync.sh` propagation handles
distribution; this reference does not apply.

## Mechanism

`specs/*` does not propagate via `fleet-sync.sh`; only
`agents/*` content propagates. When a SPEC binds work in child
repos but does not mutate `agents/*` (typical of Decision SPECs
that encode studio-level principles, taxonomies, or cross-repo
policies), the cascade mechanism is **id-citation**: child
repos cite the upstream SPEC by its `id` from their per-product
SPECs.

## Implications for authors

- Do not expect file-level propagation of `specs/*` content.
  The inaugural SPEC §13.1 names this explicitly
  (`file://examples/reference-procedure-spec`
  §13.1).
- A studio-level Decision SPEC's downstream binding is enforced
  when per-product SPECs cite it by `id` and pass `spec-review`.
  Forward direction is automatic at review time; reverse
  direction (upstream discovers all downstream consumers) is
  manual cross-repo grep.
- Pattern reference:
  `judgment://agent-synthesis`
  §3 ("Cascade-by-id-citation is the fleet binding mechanism
  for non-propagating SPECs").
