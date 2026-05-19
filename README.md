# agentic-ops-framework

[![CI](https://github.com/buildepicshit/agentic-ops-framework/actions/workflows/ci.yml/badge.svg)](https://github.com/buildepicshit/agentic-ops-framework/actions/workflows/ci.yml)

A spec-driven operating-model framework for multi-agent software studios.
Schemas, templates, lint, hooks, skills, and workpads for running
non-trivial agent work through an IDEA → SPEC → review → approve →
execute → verify → close lifecycle.

Extracted from one studio's working internal practice and sanitized for
adoption. We eat our own dog food. Your mileage may vary.

**v2.0 status**: the framework has been reorganized into a
manifest+catalog packaging shape that exemplifies the methodology
the sibling repo
[`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology)
publishes. v1.x consumers: see the **Migration from v1.x** section
below for the new path layout.

## What's here (v2.0)

Top-level (OSS-conventional + repo plumbing):

| Path | What |
|---|---|
| `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md` | Standard OSS scaffolding |
| `AGENTS.md`, `CLAUDE.md` | Entry docs for AGENTS-aware tools + Claude Code |
| `OPERATING_MODEL.md` | The 13-phase lifecycle in detail |
| `CHANGELOG.md` | Release history (v0.1 → v2.0) |
| `scripts/` | Tooling: `lint-spec.sh`, `validate-skill-frontmatter.sh`, `validate-manifest.sh` (v2.0), `fleet-sync.sh`, `audit-entry-docs.sh`, `audit-fleet-compliance.sh`, `send-fleet-message.sh`, `preflight.mjs` |
| `hooks/` | Seven PreToolUse hooks: `block-edit-on-main`, `block-push-to-main`, `block-git-add-all`, `block-verify-bypass`, `block-ai-attribution`, `verify-reminder`, `session-start-context` |
| `tests/hooks/` | 33-case hermetic hook test harness |
| `examples/` | Worked IDEA + SPEC pairs across all four SPEC types + a TASK decomposition |
| `specs/` | The framework's own internal SPEC ledger (dogfooding) |
| `.github/workflows/ci.yml` | Five CI jobs |

The manifest+catalog bundle (the methodology artefact):

| Path | What |
|---|---|
| `spec-bundle/manifest.yaml` | Front-door manifest naming every facet + resource |
| `spec-bundle/architecture/` | arc42 §3 Context + arc42 §4 Solution Strategy + (future) Structurizr DSL diagrams |
| `spec-bundle/deployment/` | Install procedure + runtime requirements (12-factor Factor II framing) |
| `spec-bundle/behavior/features/` | Gherkin scenarios for lint + hook behaviour |
| `spec-bundle/customization/` | Deferral contract (`contract.md`) + JSON Schema knob enumeration (`knobs.schema.json`) |
| `spec-bundle/decisions/` | ADR-style decision index (Nygard template) |
| `spec-bundle/quality/` | Quality scenarios + 12-factor overlay |
| `spec-bundle/operations/` | Failure model (Symphony §14 pattern) + observability (Symphony §13) + safety invariants (Symphony §9.5) + universal workflow body |
| `spec-bundle/non-goals/` | Per-facet negative space (novel facet per the methodology) |
| `spec-bundle/schema/SPEC.schema.md` | The schema every IDEA/SPEC/TASK conforms to |
| `spec-bundle/templates/` | IDEA + 4 SPEC type templates + TASK template + workpad templates |
| `spec-bundle/skills/` | Twenty skills covering the full lifecycle + multi-repo patterns + meta-skills |
| `spec-bundle/conformance/` | (Reserved for v2.x) Executable conformance suite |

## Migration from v1.x

v2.0 is a **breaking** layout change. Every file under the
old top-level `schema/`, `templates/`, `skills/`, `workflow/`,
and `workpads/` has moved under `spec-bundle/`:

| v1.x path | v2.0 path |
|---|---|
| `schema/SPEC.schema.md` | `spec-bundle/schema/SPEC.schema.md` |
| `templates/*.template.md` | `spec-bundle/templates/*.template.md` |
| `skills/<name>/` | `spec-bundle/skills/<name>/` |
| `workflow/UNIVERSAL.md` | `spec-bundle/operations/workflow-universal.md` |
| `workpads/*.template.md` | `spec-bundle/templates/workpads/*.template.md` |

Top-level scripts (`scripts/`), hooks (`hooks/`), tests
(`tests/`), examples (`examples/`), specs (`specs/`), and
all OSS-conventional files (LICENSE, README, CONTRIBUTING,
CHANGELOG, etc.) are unchanged.

v1.1 remains tagged at `v1.1` — consumers pinning v1.1
continue to work; consumers pinning `main` need to update
their paths. The CHANGELOG v2.0 entry documents the full
move set.

## Status

**v2.0** — manifest+catalog repack of v1.1 into the
shape the sibling
[`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology)
methodology advocates. Eight per-facet sub-specs with
primary-file contracts, a front-door
`spec-bundle/manifest.yaml`, and a mechanical
`scripts/validate-manifest.sh` gate. CI gains a fifth job
for manifest validation.

v1.1 shipped six new skills (catalog 14 → 20), two
cross-repo abstract patterns (`cross-repo-policy-enforcement`,
`cross-repo-informational-channel`), and contributor docs
(CONTRIBUTING.md + CODE_OF_CONDUCT.md).

v1.0 was the first git-tagged release: end-to-end
adoptable (schema + templates + lint + hooks + 14 skills +
worked examples + operating model + CI).

## Design posture

- **Schema is the contract**, lint enforces it, hooks guard against
  the obvious failure modes (edits on protected branch, bulk
  staging, verify bypass, AI attribution in commits).
- **Citation grammar separates input from evidence**: agent memory
  and training are inputs to reasoning; only `file://` / `cmd://` /
  `url://` / `decision-authority://` / `owner://` / `judgment://`
  cites are evidence in artefacts.
- **RFC 2119 normative language** carries force in the sections the
  templates designate; other sections are descriptive.
- **Owner-only state transitions** (`approved`, `decomposed`,
  `closed`) keep agency boundaries explicit; gate-passing skills
  set `approved-pending-owner` only.
- **Cross-family review** as a first-class merge gate for decomposed
  work — different model family from the implementer reviews the
  diff before it lands.
- **Manifest+catalog packaging** (v2.0): the front-door manifest
  enumerates eight per-facet sub-specs; agents consuming the
  framework can fetch the facet they need rather than the whole
  tree.

## Multi-repo propagation

If you run a multi-repo studio where one policy repo owns the
canonical fleet content and N child repos consume it, the
`scripts/fleet-sync.sh` script propagates the baseline. The
topology lives in plain-text manifests (`fleet-files.txt`,
`fleet-skills.txt`, `fleet-internal-repos.txt`, etc.). The
repo ships these as `*.example.txt`; adopters rename them
and fill them in. Source path is auto-derived from script
location; override with `FLEET_SOURCE`.

The framework also ships two cross-repo abstract patterns:

- `cross-repo-policy-enforcement` — fleet-wide policy
  directives with shell-block compliance checks
  (`scripts/audit-fleet-compliance.sh` walks the directives).
- `cross-repo-informational-channel` — per-repo
  `AGENT_INBOX.md` for structured handoffs +
  fleet-update notices (`scripts/send-fleet-message.sh`).

Single-repo studios don't need either pattern.

## What this is not

- Not a CLI runtime. The framework is schema + templates + lint +
  hooks + skills. Wire it into your own agent harness (Claude Code,
  Cursor, Codex, Aider, your custom dispatcher); the framework
  doesn't dictate the harness.
- Not an opinion on which models to use. The framework specifies
  *that* cross-family review happens; it doesn't specify *which*
  families.
- Not a finished product. The lint script handles the common cases;
  the hooks cover the obvious foot-guns; the skill catalog at 20
  covers the studio's full lifecycle but adopters MAY add their own.
- Not the methodology itself. The methodology — agentic installation
  — is published separately at
  [`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology).
  This framework is the *worked case study* the methodology
  references.

## Licence

Apache-2.0. See `LICENSE`.
