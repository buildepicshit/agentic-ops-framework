# Architecture — Solution Strategy

Per arc42 §4 Solution Strategy
(`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/arc42.md` §3).

## Strategic decisions

The framework's core strategic choices, each backed by a
decision artefact in `../decisions/`:

1. **Spec-first discipline over code-first.** Every
   non-trivial change starts with a typed SPEC
   (IDEA → SPEC → review → approve → execute → verify
   → close). The lifecycle is documented in
   `../../OPERATING_MODEL.md`.
2. **Citation grammar over loose prose.** Every factual
   claim in every artefact carries a citation prefix per
   `../schema/SPEC.schema.md` §2.
3. **Owner-only authority transitions for `approved`,
   `decomposed`, `closed`.** No skill, agent, or
   automated tooling may flip those states.
4. **Hooks as the enforcement surface for safety
   invariants.** Hard rules (no AI attribution, no bulk
   staging, no verify-bypass, no push-to-protected-branch)
   are enforced by `../../hooks/` PreToolUse hooks rather
   than relying on agent compliance.
5. **Cross-family review is BLOCKING per slice.**
   Different-family review reduces single-family blind
   spots; the framework recommends it for every
   approved-pending-owner → approved transition.
6. **Worked examples are first-class.** The framework
   ships six worked examples
   (`../../examples/`) that exercise all four spec types
   plus TASK decomposition.
7. **Manifest+catalog packaging for the v2.0 bundle.**
   Per the parent agentic-installation-methodology
   Decision, the framework's v2.0 layout exemplifies the
   manifest+catalog shape it advocates downstream.

## Technology decisions

The framework is language-agnostic but ships:

- **Bash** for lint, hooks, hook tests, validate-manifest
  (POSIX-friendly; no agent-language assumptions).
- **Node.js** for `preflight.mjs` workspace-layout audit
  (the only Node dependency; CI installs it).
- **Markdown** for all artefacts (SPEC.md, IDEA.md,
  SKILL.md, templates, examples).
- **YAML** for the front-door manifest + workflow CI
  config + per-spec front-matter.
- **GitHub Actions** for CI; no other CI integration is
  assumed.

Each language/format choice is documented in a separate
ADR-style decision under `../decisions/`.

## Top-level quality goals

Per arc42 §1.2 (top three to five quality goals;
`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/arc42.md` §3):

1. **Citation precision** — every factual claim
   resolves to a source the reader can verify (file,
   command, URL, owner judgment).
2. **Mechanical verifiability** — every quality gate
   (lint, hook test, manifest validation, CI) is a
   script that exits 0 or non-zero; no judgment calls.
3. **Hermetic test surface** — hook tests run from
   ephemeral git sandboxes; not dependent on the host
   repo state.
4. **Honest disclosure** — failure modes, open
   research questions, same-family-review caveats are
   surfaced in artefacts, not buried.

## Architecture decomposition

For Container / Component diagrams (C4 model
`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/c4-model.md` §3),
see `architecture.dsl` once Structurizr DSL artefacts
land (v2.x slice — placeholder at v2.0).
