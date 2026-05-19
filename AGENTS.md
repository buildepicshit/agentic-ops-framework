# AGENTS.md — agentic-ops-framework

> Entry doc for AGENTS-aware tools (Codex, Cursor, Aider,
> Jules, Copilot, and other AGENTS-spec consumers per
> `https://agents.md`). Claude Code enters via `CLAUDE.md`.

## What this repo is

A framework for operating engineering work with coding
agents under spec-first discipline: typed IDEA → SPEC
artefacts with citation grammar, RFC 2119 scoping rules,
a per-type quality gate, owner-only authority transitions,
and a hermetic hook test harness. v2.0 reorganizes into
manifest+catalog packaging that exemplifies the
methodology the sibling repo
[`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology)
publishes.

The framework is offered as honest experience from one
studio's working internal practice — not as prescription.

## Authority chain

Read in order when entering the repo:

1. **AGENTS.md** (this file).
2. **`OPERATING_MODEL.md`** — the 13-phase lifecycle in
   detail.
3. **`spec-bundle/manifest.yaml`** — the front-door
   manifest naming every facet + resource.
4. **`spec-bundle/schema/SPEC.schema.md`** — the schema
   every IDEA/SPEC/TASK must conform to.
5. **`spec-bundle/architecture/CONTEXT.md`** — the
   framework's own architecture context.
6. **Active SPEC** (if one exists) under
   `specs/<id>/SPEC.md`.
7. **The methodology corpus** at
   `../agentic-installation-methodology/research/primary-sources/`
   (sibling repo) — primary-source artefacts that
   ground every methodology primitive the framework
   adopts.

When sources conflict, stop and surface the conflict.

## v2.0 layout

Top-level (OSS-conventional + repo plumbing):

- `LICENSE`, `README.md`, `CONTRIBUTING.md`,
  `CODE_OF_CONDUCT.md`, `CHANGELOG.md`.
- `AGENTS.md`, `CLAUDE.md` — entry docs.
- `OPERATING_MODEL.md` — lifecycle reference.
- `scripts/` — tooling (lint, validators, hooks,
  fleet-sync helpers).
- `hooks/` — PreToolUse hooks enforcing discipline.
- `tests/` — hook test harness + future facet tests.
- `examples/` — worked IDEA+SPEC examples.
- `specs/` — the framework's own internal SPEC ledger.
- `.github/workflows/ci.yml` — five CI jobs.

The manifest+catalog bundle (the methodology artefact):

- `spec-bundle/manifest.yaml` — front-door manifest.
- `spec-bundle/{architecture, deployment, behavior,
  customization, decisions, quality, operations,
  non-goals}/` — eight per-facet sub-specs.
- `spec-bundle/{schema, templates, skills,
  conformance}/` — resource directories.

## Engineering standards

- Conventional Commits 1.0.0.
- Stage files explicitly by name. **Never** `git add .`
  or `git add -A` (enforced by `block-git-add-all.sh`).
- Do not commit machine-local files, secrets, or
  generated output.
- Do not add AI attribution to commits (no
  `Co-Authored-By: Claude` / similar trailers; enforced
  by `block-ai-attribution.sh`).
- Do not bypass verify gates (`--no-verify`,
  `VERIFY_SKIP=1`, etc. enforced by
  `block-verify-bypass.sh`).
- Do not push directly to `main` unless an active SPEC
  declares `branch_policy: main-direct` (enforced by
  `block-push-to-main.sh` + `block-edit-on-main.sh`).

## Citation discipline

Every factual claim in every artefact MUST carry a
citation prefix from the grammar:

- `file://<path>` — repo-local files.
- `cmd://<command>` — commands run.
- `url://<full-url>` — external sources.
- `owner://transcript-<date>` — owner verbatim.
- `decision-authority://<role>:<date>` — role-scoped
  authority.
- `judgment://owner` or `judgment://agent-synthesis` —
  judgments with explicit attribution.

Memory and training data are inputs to your reasoning,
not citable evidence. The lint script enforces this.

When a sentence is in fact editorial framing or an
internal cross-reference, append
`<!-- lint-ok: no-citation -->` per
`spec-bundle/schema/SPEC.schema.md` §2.5. Use sparingly.

## Spec lifecycle (13 phases)

See `OPERATING_MODEL.md` for the full description. Short
version:

Preflight → Orient → Predict → Ideate → Author → Review
(BLOCKING) → Approve (owner-only) → Decompose (BLOCKING
for Contract/Task with ≥2 slices) → Dispatch → Execute →
Cross-validate (BLOCKING) → Verify → Report + Close
(owner-only).

For trivial reversible work the **Fastpath** SPEC type
collapses the lifecycle into one capture-after artefact
landing at `status: closed` in the same commit.

## CI gates (five jobs)

Every push runs:

1. `lint-spec` — six worked examples + the inaugural
   internal SPEC.
2. `validate-skills` — skill frontmatter sanity.
3. `test-hooks` — 33-case hermetic hook test harness.
4. `validate-manifest` — front-door manifest schema +
   facet bijection.
5. `preflight-self-check` — `node --check
   scripts/preflight.mjs`.

All five MUST pass for the push to be considered green.

## Posture

The framework's posture: honest experience, not
prescription. Contributors disagree about the work, not
about contributors. Failure modes are first-class.
Citation grammar exists so claims can be argued
precisely.

The seven open research questions from the methodology
research workpad
(`../agentic-installation-methodology/research/primary-sources/leaddev-agent-compiled.md`
§3 articulates the risks) are unresolved; the framework
helps address them, it does not pretend to resolve them.

## Branch and remote policy

- Default branch: `main`.
- Remote: `git@github.com:buildepicshit/agentic-ops-framework.git`
  (public).
- Internal SPECs at `specs/<id>/SPEC.md` MAY declare
  `branch_policy: main-direct` when the work is owner-
  approved direct-on-main; both `block-edit-on-main`
  and `block-push-to-main` honour the declaration.

## See also

- `CLAUDE.md` — Claude Code entry doc (imports this
  file).
- `CONTRIBUTING.md` — how to contribute under the
  lifecycle.
- `CODE_OF_CONDUCT.md` — interaction norms.
- `spec-bundle/customization/contract.md` — the
  deferral contract for adopter customization.
- Sibling repo:
  [`agentic-installation-methodology`](https://github.com/buildepicshit/agentic-installation-methodology)
  for the methodology this framework's v2.0 layout
  exemplifies.
