# Architecture — System Context

Per arc42 §3 Context and Scope
(`file://../../research/primary-sources/arc42.md` §3) and
the C4 model System Context level
(`file://../../research/primary-sources/c4-model.md` §3),
this file states what the framework is, who its users are,
and what surrounding systems it interacts with.

Note: the canonical research-primary-source corpus lives in
the sibling repo `agentic-installation-methodology` at
`research/primary-sources/`. Cross-repo `file://` paths in
this document resolve relative to that sibling.

## Product (system) under consideration

**agentic-ops-framework** — a framework for operating
engineering work with coding agents under spec-first
discipline.

Concretely, the framework ships:
- A typed SPEC schema with citation grammar, RFC 2119
  scoping, and a status state machine
  (`file://../schema/SPEC.schema.md`).
- Six templates (IDEA + 4 SPEC types + TASK) at
  `file://../templates/`.
- A lint script (`file://../../scripts/lint-spec.sh`) that
  enforces the schema per artefact type.
- A skill catalog (`file://../skills/`) covering the
  spec lifecycle plus multi-repo patterns.
- Seven PreToolUse hooks (`file://../../hooks/`) enforcing
  studio discipline (no AI attribution, no bulk staging,
  no verify-bypass, no push-to-protected-branch).
- A hermetic 33-case hook test harness
  (`file://../../tests/hooks/run-tests.sh`).
- Six worked IDEA+SPEC examples
  (`file://../../examples/`).
- A CI workflow (`file://../../.github/workflows/ci.yml`)
  that runs lint + skill-frontmatter + hook tests +
  manifest validation on every push.

## Users (per arc42 §3 stakeholder framing)

| User class | Goal | Authority |
|---|---|---|
| Framework adopter (a studio or team operating coding agents) | Install + customize the framework; author specs in their own repos | Owner-with-agent in their own context |
| Coding agent (Claude, Codex, Gemini, etc.) | Read the framework's discipline; author + execute against it | Bounded by the spec lifecycle + hook discipline |
| Framework maintainer (HasNoBeef) | Steward the framework's evolution; author spec changes | Final authority on framework direction |

## Surrounding systems

The framework does NOT include but interacts with:

- **GitHub** (or any git host) — the framework's own
  release artefacts + adopter repos live there.
- **Issue trackers** (Linear / GitHub Issues / others) —
  the framework's autonomous-issue-dispatch skill assumes
  a tracker exists; the contract is tracker-agnostic.
- **AI coding assistants** (Claude Code, Codex, Gemini CLI,
  Cursor, Aider, etc.) — the framework's AGENTS.md
  contract per `url://agents.md` is consumed by any
  AGENTS-aware tool.
- **Per-language toolchains** (the languages an adopter's
  product is implemented in) — out of scope of the
  framework itself; the framework is operating-model, not
  language-runtime.

## Boundary (what the framework does NOT cover)

- The framework does NOT prescribe a programming language.
- The framework does NOT bundle an agent runtime; agents
  are dispatched by the adopter's tooling (Claude Code
  CLI, Codex CLI, Symphony, etc.).
- The framework does NOT enforce a particular tracker;
  see Symphony for that pattern
  (`file://../../research/primary-sources/symphony-spec.md`
  §3).

See also: `solution-strategy.md` for arc42 §4 Solution
Strategy; `../non-goals/INDEX.md` for the formal facet-level
non-goal enumeration.
