---
name: agents-md-improver
description: "Use to audit or improve AGENTS.md / CLAUDE.md / GEMINI.md / WORKFLOW.md against the canonical fleet entry-doc pattern. Fires when authoring or revising entry docs, when audit-entry-docs.sh flags drift, or when a new repo joins the fleet and needs entry docs scaffolded. Do not use to write product documentation — entry docs are agent-control content per OPERATING_MODEL Source Of Truth."
---

# AGENTS.md Improver

Use this skill when authoring, auditing, or repairing the entry-doc
set in any fleet repo. The skill encodes the canonical pattern
declared in
`file://OPERATING_MODEL.md` §"Source Of Truth" and §"Public
OSS posture", and is the policy reference that
`file://scripts/audit-entry-docs.sh` enforces mechanically.

## When to use

- Creating entry docs for a new repo joining the fleet.
- Revising `AGENTS.md` or `CLAUDE.md` in any existing repo.
- An `audit-entry-docs.sh` run reported drift.
- A propagation cycle introduced changes that touch entry docs.

## Canonical pattern (internal repos)

INTERNAL repos (active child product repos plus the source
policy repo) MUST have:

- `AGENTS.md` (the canonical, agent-agnostic entry doc — read by
  the agent runner, Cursor, Aider, Copilot, Jules, and other AGENTS-aware
  tools per `url://https://agents.md`). REQUIRED sections:
  - `## What this repo is` — a one-paragraph orientation.
  - `## Engineering standards` — the studio rules (Conventional
    Commits; explicit staging; no AI attribution; no verify-bypass;
    no push to the protected branch). Reference enforcement hooks
    by name where applicable.
  - The literal phrase "Fleet Rule Origination" referencing
    `file://OPERATING_MODEL.md` §"Fleet Rule Origination".
- `WORKFLOW.md` (the autonomous-dispatch runner-compatible dispatch contract). MUST be
  composed of three parts: per-repo YAML config (tracker /
  polling / workspace / hooks / agent / codex / bes); a one-section
  per-repo intro naming the repo and its canonical verify command;
  the fleet-baseline prompt body verbatim from
  `<adopter-policy-repo>/agents/templates/WORKFLOW.body.md` (fleet-baseline reference; bes-fleet-policy-layout-specific) (or
  `.workpads/WORKFLOW.body.md` in a child repo).
  Per-repo content lives ABOVE the body; the body is fleet-uniform.
  Drift between a repo's WORKFLOW.md body and the fleet baseline
  is a blocking failure surfaced by `audit-entry-docs.sh`.
- `CLAUDE.md` (OPTIONAL but recommended) — Claude Code reads this
  first per `url://https://code.claude.com/docs/en/memory`. It MUST
  start with `@AGENTS.md` to import the canonical content; only add
  Claude-specific extensions on top (slash-command list, hook
  inventory, posture).
- `GEMINI.md` (OPTIONAL) — same pattern as `CLAUDE.md` but for
  Gemini CLI.

## Canonical pattern (public OSS repos)

Public OSS repos (per `file://OPERATING_MODEL.md` §"Public
OSS posture") MUST NOT have:

- Root-level `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, or `WORKFLOW.md`.
- Tracked `.agents/` or `.claude/` directories.

`.agents/` and `.claude/` content lays in the working tree (gitignored)
so any AI assistant landing locally has the engagement model
available; nothing reaches the public surface. See
`file://OPERATING_MODEL.md` §"Public OSS posture" for the
full rationale.

## Hard rules

- AGENTS.md is canonical. CLAUDE.md and GEMINI.md MUST NOT carry
  policy that the agent-agnostic file lacks. If a rule applies to
  any agent, it belongs in AGENTS.md.
- Agent-specific extensions are import-only at the top
  (`@AGENTS.md`) plus tool-specific additions (slash-commands,
  statusline, hooks). Don't duplicate AGENTS.md content; reference it.
- Public OSS repos are protected: agent infrastructure MUST stay
  out of the GitHub surface. The auditor flags any tracked
  `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`/`WORKFLOW.md` in those repos
  as a blocking failure.
- Fleet rule origination per
  `file://OPERATING_MODEL.md` §"Fleet Rule Origination":
  changes to AGENTS.md and CLAUDE.md in child repos that contradict
  the canonical pattern are repo-local drift, not fleet changes.
  Amend the canonical doc in `your-policy-repo` first, then
  propagate.

## Enforcement

`file://scripts/audit-entry-docs.sh` checks all of the above
mechanically. Run it from the studio root (validates all 7 repos)
or from any repo root (validates that one repo). Exit codes:

- `0` — all checks pass.
- `1` — at least one blocking criterion failed; per-repo PASS/FAIL
  written to stderr with file:line citations.

## Quality Gate Handoff

This skill does not approve or block work. It documents the policy.
Mechanical enforcement is `audit-entry-docs.sh`. Substantive
review of entry-doc changes goes through the v1 SPEC procedure:
amend canonical docs in `your-policy-repo` via IDEA → SPEC →
review → propagate.
