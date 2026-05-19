# Changelog

All notable changes to this project. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with
date-stamped releases. Versions before v1.0 were README-only
milestones; v1.0 is the first git-tagged release.

## v2.0 — 2026-05-19

**Breaking layout change**: the framework is repacked into
a manifest+catalog packaging shape that exemplifies the
methodology the sibling repo
[`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology)
publishes. v1.1 remains tagged at `v1.1`; consumers pinning
that tag are unaffected. Consumers pinning `main` MUST
update their paths per the migration index below.

### Added

- **`spec-bundle/manifest.yaml`** — front-door manifest
  per the methodology's manifest+catalog packaging
  recommendation. Carries `spec_version`,
  `bundle_version`, `conformance_profile`, `intent` block
  (product name, purpose, developer + installer
  authority), eight `facets` entries, and a reserved
  `signature` field for v2.x Sigstore signing.
- **`scripts/validate-manifest.sh`** — mechanical
  completeness gate: validates schema version,
  conformance profile, intent block, facet ↔ filesystem
  bijection, and primary-file presence per facet. Exits
  0 iff the bundle is structurally complete.
- **Eight per-facet sub-spec directories** under
  `spec-bundle/`:
  - `architecture/` — arc42 §3 Context (`CONTEXT.md`) +
    arc42 §4 Solution Strategy (`solution-strategy.md`).
    Reserved for Structurizr DSL diagrams in v2.x.
  - `deployment/` — install procedure (`install.md`) +
    runtime requirements (`requirements.md`, 12-factor
    Factor II framing).
  - `behavior/features/` — Gherkin scenarios for lint
    citation grammar and the AI-attribution block hook.
    Reserved for additional features in v2.x.
  - `customization/` — deferral contract (`contract.md`)
    naming K-1 through K-7 adopter knobs + JSON Schema
    enumeration (`knobs.schema.json`).
  - `decisions/` — ADR-style decision index
    (`INDEX.md`) catalogues eight foundational
    framework decisions. Per-decision artefacts at
    `ADR-NNN-<slug>.md` are reserved for v2.x.
  - `quality/` — quality scenarios (`requirements.md`,
    six Q-1 through Q-6 quality goals) + 12-factor
    overlay (`12-factor-overlay.md`).
  - `operations/` — failure model (`failures.md`,
    seven F-1 through F-7 failure classes) +
    observability (`observability.md`, three-tier
    Symphony §13 pattern) + safety invariants
    (`safety-invariants.md`, SI-1 through SI-12).
  - `non-goals/` — per-facet negative space (`INDEX.md`,
    novel facet per the methodology's research §4.2).
- **`AGENTS.md`** at top-level — new entry doc for
  AGENTS-aware tools per `https://agents.md`. Imports
  via `CLAUDE.md`'s `@AGENTS.md` directive.
- **CI: `validate-manifest` job** in the workflow.

### Changed

- **Directory moves** (the v1.x → v2.0 migration index):
  - `schema/SPEC.schema.md` → `spec-bundle/schema/SPEC.schema.md`
  - `templates/*.template.md` → `spec-bundle/templates/*.template.md`
  - `skills/<name>/` → `spec-bundle/skills/<name>/`
  - `workflow/UNIVERSAL.md` → `spec-bundle/operations/workflow-universal.md`
  - `workpads/*.template.md` → `spec-bundle/templates/workpads/*.template.md`
  - `docs/` → removed (was empty)
- `scripts/validate-skill-frontmatter.sh` updated to
  scan `spec-bundle/skills/` (was `skills/`).
- `README.md` rewritten for v2.0 with migration table.
- `CLAUDE.md` rewritten to reference v2.0 layout with a
  v1.x cheat-sheet.

### Authority

This repack lands under the parent Decision SPEC at
`bes-fleet-policy/specs/2026-05-18-agentic-installation-methodology/SPEC.md`
§7 (Hybrid longread + SPEC bundle shape, paired
Product A v2.0 + Product B v1.0 release) and the slice 2
Contract SPEC at
`specs/2026-05-19-v2-manifest-catalog-repack/SPEC.md`.

Every methodology primitive adopted in v2.0 is grounded
in a primary-source corpus entry in the sibling repo at
`research/primary-sources/<slug>.md`. The corpus is the
authoritative evidence base; agent memory is not citable
for any methodology claim in v2.0 artefacts.

### Reserved for v2.x

- Per-decision ADR artefacts at
  `spec-bundle/decisions/ADR-NNN-<slug>.md` (currently
  just the INDEX is populated).
- Structurizr DSL diagrams at
  `spec-bundle/architecture/*.dsl`.
- Executable conformance suite at
  `spec-bundle/conformance/`.
- Sigstore signing of the bundle (`signature.status:
  unsigned` at v2.0; populates when cosign + Rekor
  tooling is wired).
- Reference customization profiles at
  `spec-bundle/customization/profiles/*.yaml`.

### Posture

The framework eats its own dog food: by adopting the
methodology's recommended packaging on itself, the v2.0
release becomes the worked case study the sibling
methodology repo references. Honest disclosure: v2.0
ships scaffold-grade content in several facets (the
`spec-bundle/conformance/` is empty; per-decision ADRs
are not yet authored beyond the INDEX). The structural
contract is sound; richer content lands in v2.x slices.

## v1.1 — 2026-05-18

Catalog expansion, cross-repo abstract patterns, and contributor
docs. No breaking changes; v1.0 consumers can adopt v1.1 by
copying the new skills + scripts.

### Added

- **Six new skills** lifting the catalog from 14 to 20:
  - `spec-driven-development` — 13-phase lifecycle skill.
  - `agents-md-improver` — entry-doc audit + canonical-pattern
    drift detection.
  - `agent-feedback` — outbound-to-fleet friction-surface
    workpad pattern.
  - `caveman` — opt-in compressed communication mode (safety
    exceptions baked in).
  - `cross-repo-policy-enforcement` — fleet-wide policy
    directive pattern with shell-block compliance checks.
  - `cross-repo-informational-channel` — per-repo
    `AGENT_INBOX.md` pattern for structured handoffs +
    fleet-update notices.
- **Two cross-repo scripts**:
  - `scripts/audit-fleet-compliance.sh` runs every directive's
    §3 shell-block compliance check against each named target;
    exit 0 iff every (directive × target) pair passes.
  - `scripts/send-fleet-message.sh` appends a structured entry
    to another repo's `AGENT_INBOX.md` and commits with a
    `fleet(inbox): …` message.
- **`workpads/AGENT_INBOX.template.md`** — the inbound channel
  template each fleet repo plants at its root for cross-repo
  informational messages.
- **`scripts/fleet-known-repos.txt`** manifest — `send-fleet-
  message.sh` reads valid target repo names from this file
  instead of a hardcoded array. Empty by default; single-repo
  projects need not populate it.
- **`CONTRIBUTING.md`** + **`CODE_OF_CONDUCT.md`** — how to
  contribute under the framework's own IDEA → SPEC →
  review → approve → execute → verify lifecycle.

### Changed

- Generic-fleet-friendly rename: `studio-principle-<topic>` slug
  taxonomy → `principle-<topic>`. `Studio Principles` skill
  section + per-type-gate check renamed to fleet-principle.
- `audit-entry-docs.sh` advisory phrasing on missing
  `WORKFLOW.md`: generic "issue-tracker-dispatch contract"
  replaces tool-specific naming.

## v1.0 — 2026-05-18

First tagged release. The framework is adoptable end-to-end:
schema + templates + lint + hooks + skills + worked examples +
operating model + CI.

### Added

- **CI** — `.github/workflows/ci.yml` runs four jobs on every
  push and PR: lint worked examples, validate skill frontmatter,
  hook test harness (33 cases), preflight self-check.
- **Hook test harness** at `tests/hooks/run-tests.sh` covers
  all seven hooks across block paths, allow paths, and false-
  positive guards. Uses ephemeral git-sandbox fixtures for
  branch-aware hooks so tests are hermetic.
- **Dogfooding SPEC** at `specs/2026-05-18-v1.0-release-foundations/`
  — the framework's first internal SPEC, documenting the v1.0
  release work via the capture-after pattern. The framework
  uses itself.

### Pre-v1.0 milestones (no tags)

**v0.5.2 milestone** — `preflight.mjs` config extracted to
`scripts/preflight-config.example.json`. JSON manifest of
topology + allowlist replaces hardcoded arrays in the script.

**v0.5.1 milestone** — `audit-entry-docs.sh` shipped with three
new repo-posture manifests (`fleet-internal-repos.example.txt`,
`fleet-oss-repos.example.txt`,
`fleet-local-only-repos.example.txt`). `Fleet Rule Origination`
canonical-phrase check renamed to `Policy Origination` (generic).

**v0.5 milestone** — `fleet-sync.sh` and six example manifests
(`fleet-files`, `fleet-skills`, `fleet-commands`, `fleet-hooks`,
`fleet-hook-fixtures`, `fleet-oss-gitignore`). Topology lives in
plain-text manifests; script auto-derives source path from its
own location with `FLEET_SOURCE` env override.

**v0.1 milestone** — initial framework substrate. Schema +
6 templates (IDEA, 4 SPEC types, TASK) + lint-spec.sh +
validate-skill-frontmatter.sh + 7 hooks + 6 procedure-only
skills + workflow/UNIVERSAL.md + workpads templates + a
lightweight OPERATING_MODEL.md + Apache-2.0 LICENSE.

### Path from v0.1 to v1.0

After v0.1 the framework grew via incremental feature commits
(no tags cut). Key additions between v0.1 and v1.0:

- **Skill catalogue 6 → 14**. Added: `approved-spec-decomposition`,
  `implementation-execution`, `owner-led-parallel-worktrees`,
  `autonomous-issue-dispatch`, `repo-orientation`,
  `spec-authoring`, `spec-review`, `fast-path`. Lifecycle now
  has skill coverage for every phase.
- **Worked examples 0 → 5**. Added: Task (auth structured
  logging), Contract (webhook signing), Decision (Conventional
  Commits), Fastpath (typo fix), TASK.md decomposition (under
  the Contract example). All four SPEC types now have lint-clean
  worked examples adopters can copy from.
- **OPERATING_MODEL.md 149 → 335 lines**. Added: Agent roles,
  Workspace policy, Lightweight ceremony modes, Parallel
  execution policy, Documentation placement, Content and
  creative authority. Expanded: citation grammar, memory
  boundary, cross-family review (with same-family-proxy fallback
  protocol), safety invariants, hard rules.
- **Citation grammar** gained `decision-authority://<role>:<date>`
  as the canonical multi-stakeholder citation prefix; `owner://`
  retained as the single-owner shorthand. Lint recognises both.

### Known gaps (queued for v1.1+)

- Four more skills classified as MIXED in the source audit:
  `spec-driven-development` (lifecycle index),
  `agents-md-improver` (entry-doc auditor), `agent-feedback`
  (outbound friction channel), `caveman` (opt-in compressed
  communication).
- Two multi-repo abstract patterns: `cross-repo-policy-enforcement`,
  `cross-repo-informational-channel`.
- `audit-fleet-compliance.sh` (blocked on the cross-repo
  enforcement skill generalisation).
- `CONTRIBUTING.md` / `CODE_OF_CONDUCT.md`.

The framework is usable end-to-end without these. They are
catalogue completeness, not load-bearing gaps.
