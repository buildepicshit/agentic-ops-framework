# Decisions — Index

ADR-style decision records per Nygard's foundational
template (`file://../../research/primary-sources/adr-nygard.md`
§3): five-section Title / Context / Decision /
Consequences / Status.

Status lifecycle (Nygard §3): `proposed` → `accepted` →
`deprecated` → `superseded`.

| ID | Title | Status | Date |
|---|---|---|---|
| ADR-001 | Spec-first discipline (IDEA → SPEC → review → approve) | accepted | 2026-05-01 |
| ADR-002 | Citation grammar with seven prefixes | accepted | 2026-05-01 |
| ADR-003 | Owner-only authority transitions | accepted | 2026-05-01 |
| ADR-004 | RFC 2119 keywords confined to §7 in Decision SPECs | accepted | 2026-05-01 |
| ADR-005 | Capture-after exception for owner-directed urgent fixes | accepted | 2026-05-17 |
| ADR-006 | Fastpath SPEC type for ≤50-line, single-file, reversible work | accepted | 2026-05-13 |
| ADR-007 | Cross-family review BLOCKING per slice | accepted | 2026-05-04 |
| ADR-008 | Manifest+catalog packaging for v2.0 | accepted | 2026-05-19 |

Per-decision artefacts live at `ADR-NNN-<slug>.md` (to be
populated as v2.x slices land; current v2.0 inventory is
the index only, with the underlying decisions traceable
to the framework's internal SPEC ledger at
`file://../../specs/`).

## Why this format

- Nygard's lightweight thesis
  (`file://../../research/primary-sources/adr-nygard.md`
  §3 verbatim "Large documents are never kept up to date.
  Small, modular documents have at least a chance at
  being updated"): each ADR is ≤2 pages.
- The state-of-practice ADR ecosystem catalogue
  (`file://../../research/primary-sources/adr-tools-state.md`
  §3) lists alternatives (MADR, Y-statements) — the
  framework adopts Nygard's template as the minimum
  contract; adopters MAY use MADR's richer fields in
  their own repos.
