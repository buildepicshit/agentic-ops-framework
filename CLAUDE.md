# CLAUDE.md — agentic-ops-framework

@AGENTS.md

## Claude entry protocol

1. Read `AGENTS.md` (imported above).
2. Read `OPERATING_MODEL.md` — full 13-phase lifecycle.
3. Read `spec-bundle/manifest.yaml` — front-door
   manifest naming every facet + resource.
4. Read `spec-bundle/schema/SPEC.schema.md` — the
   schema every IDEA/SPEC/TASK must conform to.
5. If an active SPEC exists under `specs/<id>/SPEC.md`,
   read its body + §17 Completion Report.
6. For non-trivial work, follow the v1 spec-first
   procedure (IDEA → SPEC → blocking review → owner
   approval → execute → verify → spec-evidence →
   closed).

## v2.0 layout cheat sheet

| Looking for | New location |
|---|---|
| Schema | `spec-bundle/schema/SPEC.schema.md` |
| Templates (IDEA, SPEC types, TASK) | `spec-bundle/templates/` |
| Skills catalog (20 skills) | `spec-bundle/skills/` |
| Workpad templates (AGENT_FEEDBACK, etc.) | `spec-bundle/templates/workpads/` |
| Universal workflow | `spec-bundle/operations/workflow-universal.md` |
| ADR-style decisions index | `spec-bundle/decisions/INDEX.md` |
| Customization deferral contract | `spec-bundle/customization/contract.md` |
| Per-facet non-goals | `spec-bundle/non-goals/INDEX.md` |
| Safety invariants (SI-1..SI-12) | `spec-bundle/operations/safety-invariants.md` |

For v1.x consumers: every old top-level path under
`schema/`, `templates/`, `skills/`, `workflow/`,
`workpads/` has moved under `spec-bundle/`. See
`CHANGELOG.md` v2.0 entry for the full migration index.

## Hooks (active)

PreToolUse, SessionStart, and Stop hooks at `hooks/`:

- `block-ai-attribution.sh` — no `Co-Authored-By: AI`
  trailers in commits.
- `block-edit-on-main.sh` — protected-branch gate.
- `block-git-add-all.sh` — no bulk staging.
- `block-push-to-main.sh` — protected branch
  non-pushable without `branch_policy: main-direct`.
- `block-verify-bypass.sh` — verify gate is
  non-negotiable.
- `session-start-context.sh` — SessionStart hook
  injecting repo state.
- `verify-reminder.sh` — Stop hook reminding about
  acceptance commands.

33-case test harness at `tests/hooks/run-tests.sh`.

## Slash commands

This repo does not ship Claude Code slash-commands at the
framework level; adopters who use Claude Code wire their
own via `.claude/commands/`. The skill catalog at
`spec-bundle/skills/` is the canonical surface for
agent capabilities the framework offers.

## Posture

The framework's discipline (lifecycle, citation grammar,
hooks, lint) is binding. The framework's claims about
what the methodology IS are sourced from the primary-
source corpus in the sibling repo
`agentic-installation-methodology/research/primary-sources/`.
Memory and prior agent summaries are NOT citable
evidence in framework artefacts.

The seven open research questions from the methodology
workpad (LeadDev critique, ambiguity handling, patching
semantics, install-matches-intent verification,
equivalence classes, capability floor, adversarial
consumption) remain unresolved — the framework helps
address them, it does not pretend to resolve them.
