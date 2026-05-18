# agentic-ops-framework

A spec-driven operating-model framework for multi-agent software studios.
Schemas, templates, lint, hooks, skills, and workpads for running
non-trivial agent work through an IDEA → SPEC → review → approve →
execute → verify → close lifecycle.

Extracted from one studio's working internal practice and sanitized for
adoption. We eat our own dog food. Your mileage may vary.

## What's here

| Path | What |
|---|---|
| `schema/SPEC.schema.md` | Shared schema: front-matter, citation grammar, RFC 2119 conventions, status state machine |
| `templates/` | IDEA + 4 SPEC type templates (task / contract / decision / fastpath) + TASK template for decomposition |
| `scripts/lint-spec.sh` | Per-type quality-gate lint over IDEA / SPEC artefacts |
| `scripts/validate-skill-frontmatter.sh` | Skill frontmatter validator |
| `skills/` | Six procedure-only skills: `verification`, `code-review`, `release-pr`, `spec-evidence-governance`, `diagnosis`, `tdd` |
| `hooks/` | Seven Claude Code hooks: `block-edit-on-main`, `block-push-to-main`, `block-git-add-all`, `block-verify-bypass`, `block-ai-attribution`, `verify-reminder`, `session-start-context` |
| `workflow/UNIVERSAL.md` | Universal-mode WORKFLOW body shared across all agent contexts |
| `workpads/` | Per-repo append-only workpad templates: `AGENT_FEEDBACK`, `SESSION_JOURNAL` |
| `OPERATING_MODEL.md` | Operating model: lifecycle, types, citation discipline, memory boundary, safety invariants |

## Status

v0.1 — the "publishable with renaming only" content from a larger
operating model. Subsequent releases will add the config-extracted
audit tooling (v0.5) and the rewritten operating-model
documentation, additional skills, and synthetic worked-example
SPECs (v1.0).

## Design posture

- **Schema is the contract**, lint enforces it, hooks guard against
  the obvious failure modes (edits on protected branch, bulk
  staging, verify bypass, AI attribution in commits).
- **Citation grammar separates input from evidence**: agent memory
  and training are inputs to reasoning; only `file://` / `cmd://` /
  `url://` / `decision-authority://` cites are evidence in artefacts.
- **RFC 2119 normative language** carries force in the sections the
  templates designate; other sections are descriptive.
- **Owner-only state transitions** (`approved`, `decomposed`,
  `closed`) keep agency boundaries explicit; gate-passing skills
  set `approved-pending-owner` only.
- **Cross-family review** as a first-class merge gate for decomposed
  work — different model family from the implementer reviews the
  diff before it lands.

## What this is not

- Not a CLI runtime. The framework is schema + templates + lint +
  hooks + skills. Wire it into your own agent harness (Claude Code,
  Cursor, your custom dispatcher); the framework doesn't dictate
  the harness.
- Not an opinion on which models to use. The framework specifies
  *that* cross-family review happens; it doesn't specify *which*
  families.
- Not a finished product. The lint script handles common cases; the
  hooks cover the obvious foot-guns; the skill set is six of the
  twenty-something a complete studio runs. v1.0 fills in the rest.

## Licence

Apache-2.0. See `LICENSE`.
