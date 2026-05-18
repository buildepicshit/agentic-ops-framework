# agentic-ops-framework

[![CI](https://github.com/buildepicshit/agentic-ops-framework/actions/workflows/ci.yml/badge.svg)](https://github.com/buildepicshit/agentic-ops-framework/actions/workflows/ci.yml)

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
| `scripts/fleet-sync.sh` | Manifest-driven multi-repo propagation (v0.5) — copies fleet baseline from a source policy repo into N target repos |
| `scripts/audit-entry-docs.sh` | Audit AGENTS.md / CLAUDE.md / GEMINI.md / WORKFLOW.md presence + canonical-pattern adherence across all fleet repos (v0.5.1) |
| `scripts/preflight.mjs` | Workspace-layout preflight gate — MCP config status, codex CLI presence, fleet-content presence, unmanaged top-level entries (v0.5.2) |
| `scripts/preflight-config.example.json` | Example preflight topology + allowlist config; rename to drop `.example.` to activate |
| `scripts/fleet-*.example.txt` | Example manifest files (skills, slash-commands, hooks, hook fixtures, OSS-posture gitignore entries, internal-repo list, OSS-repo list, local-only repo list) |
| `skills/` | Fourteen skills covering the full lifecycle + multi-repo patterns: `repo-orientation`, `spec-authoring`, `spec-review`, `fast-path`, `approved-spec-decomposition`, `implementation-execution`, `verification`, `code-review`, `release-pr`, `spec-evidence-governance`, `tdd`, `diagnosis`, `owner-led-parallel-worktrees`, `autonomous-issue-dispatch` |
| `hooks/` | Seven Claude Code hooks: `block-edit-on-main`, `block-push-to-main`, `block-git-add-all`, `block-verify-bypass`, `block-ai-attribution`, `verify-reminder`, `session-start-context` |
| `workflow/UNIVERSAL.md` | Universal-mode WORKFLOW body shared across all agent contexts |
| `workpads/` | Per-repo append-only workpad templates: `AGENT_FEEDBACK`, `SESSION_JOURNAL` |
| `OPERATING_MODEL.md` | Operating model: lifecycle, types, citation discipline, memory boundary, safety invariants |
| `tests/hooks/` | Hook test harness (33 cases) verifying every hook's block-path, allow-path, and false-positive behavior |
| `.github/workflows/ci.yml` | CI gates lint, skill-frontmatter, hook tests, and preflight on every push |
| `specs/` | Internal SPECs tracking the framework's own evolution (the framework dogfoods itself) |
| `examples/` | Worked IDEA → SPEC pairs for all four SPEC types + a TASK.md decomposition |
| `CHANGELOG.md` | Release history |

## Status

**v0.5** — adds `fleet-sync.sh` and the manifest-driven
propagation pattern for multi-repo studios. The script ships
its topology in plain-text manifests (one entry per line);
edit the manifest to change what propagates without touching
the script. Single-repo studios can ignore `fleet-sync.sh`
entirely.

v0.1 shipped the "publishable with renaming only" content
(schema + templates + lint + hooks + 6 procedure-only skills +
universal workflow body + workpad templates + operating model).

**v1.0** (next) will add the rewritten operating-model
documentation, additional skills, and synthetic worked-example
SPECs.

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

## Multi-repo propagation (v0.5)

If you run a multi-repo studio where one policy repo owns the
canonical fleet content and N child repos consume it, the
`scripts/fleet-sync.sh` script propagates the baseline. The
topology lives in plain-text manifests next to the script:

| Manifest | What it lists |
|---|---|
| `fleet-files.txt` | Paths under `agents/` that propagate to each target's `.agents/` |
| `fleet-skills.txt` | Skill directory names (mirrored to `.agents/skills/` + `.claude/skills/`) |
| `fleet-commands.txt` | Claude Code slash-command basenames |
| `fleet-hooks.txt` | Claude Code hook script filenames |
| `fleet-hook-fixtures.txt` | Hook test fixture filenames |
| `fleet-oss-gitignore.txt` | `.gitignore` entries to inject for `posture=oss` targets |
| `fleet-internal-repos.txt` | Internal-posture repo names (agent-control content committed) |
| `fleet-oss-repos.txt` | Public-OSS-posture repo names (agent-control content gitignored) |
| `fleet-local-only-repos.txt` | Local-only working-tree repo names (no remote) |

The repo ships these as `*.example.txt` so adopters rename
them (drop `.example.`) and fill them in. Source path is
auto-derived from script location; override with `FLEET_SOURCE`.

Two postures:
- `internal` — full content committed to the target repo;
  `.agents/` and `.claude/` are tracked.
- `oss` — content lays into the target's working tree only;
  `.agents/`, `.claude/`, and the workpad files are appended to
  `.gitignore`. For public OSS repos that adopt the framework
  without leaking agent-control content to GitHub.

Single-repo studios don't need this. The schema, templates,
lint, hooks, skills, and workflow body work fine in one repo
without propagation.

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
