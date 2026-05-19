# Reference Architecture First + External Tool Adoption

Authoring discipline that fires when the SPEC's domain has a public
reference architecture, OR when the SPEC adopts an external tool.
Read this when either applies; the parent SKILL.md links here.

## Contents

- Reference Architecture First — procedure when a public reference
  exists.
- External tool adoption shape — the six-part shape for landing a
  new tool in the fleet.

## Reference Architecture First

When a public reference architecture exists for the SPEC's domain,
cite it in §4 Authority Map and mirror its contract shape. Novel
design is for gaps the reference does not cover.

Procedure:

1. Identify the reference architecture (an OSS project, a published
   spec, an academic paper, an internal-but-prior SPEC).
2. Fetch and read the reference's spec/SPEC.md/whitepaper.
3. Cite verbatim in §4 Authority Map with `url://`, `file://`, or
   `owner://` prefix per `file://spec-bundle/schema/SPEC.schema.md` §2.
4. Map the reference's primary entities, state machines, and
   normative requirements onto fleet primitives (citation
   discipline, owner-only authority, fleet propagation, hooks,
   lint).
5. Diff the gap: what does the reference cover that doesn't?
   What does cover that the reference doesn't?
6. The SPEC's design proposes the gap-closing primitives only; it
   does NOT re-derive what the reference already specifies.

Example: a SPEC adopting an issue-tracker-dispatch runner
mirrors the runner's per-issue isolated workspace contract
(cited via `url://` from the runner's published spec) rather
than re-deriving the dispatch model. The SPEC's design
section only proposes the gap-closing primitives — citation
discipline, owner-only authority transitions, fleet
propagation — that the runner does not cover.

## External tool adoption shape

When adopting an external tool that fits procedure (CLI, library,
runner), use this six-part shape:

1. **Decision SPEC** selecting the tool over alternatives. Cites
   the upstream repo + docs in §4 Authority Map; trade-off matrix
   in §6 covers the fleet-specific criteria (procedure binding,
   coexistence with existing tooling, citation+authority
   preservation, OSS posture, agent skill surface, maintenance
   cost).
2. **Task SPEC** executing the deliverables. Lists the artefact
   set in §17.1 Files Changed.
3. **`skills/<tool>/SKILL.md`** mirroring upstream's
   SKILL.md if one exists, adding bindings (citation grammar,
   owner-only authority, propagation contract, hard rules against
   bypassing existing fleet surfaces).
4. **`workpads/<tool>.<ext>.template`** project-level
   config bound to procedure via the tool's hook surface
   (lint-spec on staged artefacts, parent-SPEC acceptance on
   merge, evidence reminders, removal guards).
5. **`OPERATING_MODEL.md`** section documenting the tool
   boundary against existing fleet tooling (e.g., the
   autonomous-vs-interactive dispatcher boundary).
6. **`agents/SKILL_REGISTRY.md`** row in the supplementary skill
   table.

`fleet-sync.sh` propagates (3) + (4) + the manifest entry in
`scripts/fleet-files.txt`. `.config/<tool>.<ext>` is
overwritten on each sync; per-repo edits are drift.

The framework exercised this six-part shape when adopting
worktree-based parallel-agent tooling (`judgment://agent-
synthesis`). The SPEC_EVIDENCE entry from that adoption
promoted the pattern as the disposition that landed here.
