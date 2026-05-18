# Changelog

All notable changes to this project. Format loosely follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) with
date-stamped releases. Versions before v1.0 were README-only
milestones; v1.0 is the first git-tagged release.

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
