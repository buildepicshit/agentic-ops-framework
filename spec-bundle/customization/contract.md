# Customization — Deferral Contract

The novel facet per research §4.1 (`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/leaddev-agent-compiled.md`
§3 articulates the gap as risk; this contract closes it as
procedure). Following Helm values-schema patterns
(`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/helm-values-schema.md`
§3) for the JSON Schema validation layer.

This document states **what the framework provides by
default** and **what is deferred to the adopter (the
installing user-with-agent)**, with constraints on each
deferred surface.

## Provided by default (developer-owned)

The framework SHIPS the following as immutable contract:

- The IDEA / SPEC / TASK template structure
  (`file://../templates/`).
- The schema's citation grammar (`file://`, `cmd://`,
  `url://`, `owner://`, `decision-authority://<role>:<date>`,
  `judgment://owner`, `judgment://agent-synthesis`) and the
  RFC 2119 scoping rules per artefact type
  (`file://../schema/SPEC.schema.md` §2, §3).
- The 13-phase lifecycle states (Preflight → Orient →
  Predict → Ideate → Author → Review → Approve →
  Decompose → Dispatch → Execute → Cross-validate →
  Verify → Report+Close).
- The owner-only authority transitions
  (`approved`, `decomposed`, `closed` flip only by owner).
- The hard rules in the seven PreToolUse hooks (no AI
  attribution, no bulk staging, no verify-bypass, no
  push-to-protected-branch, edit-on-main only with
  branch_policy declared, session-start-context emit,
  verify-reminder on Stop).

The adopter MUST NOT alter these contracts without
authoring their own superseding Decision SPEC in their
own repo.

## Deferred to the adopter (installer-owned)

The following customization knobs are deferred to the
adopter; the framework expects them to be set in the
adopter's context:

### K-1: Skill catalog scope

Knob: which of the 20 published skills the adopter
adopts in their repo's `.agents/skills/` (or equivalent).

Default: adopt the seven lifecycle skills
(`repo-orientation`, `spec-authoring`, `spec-review`,
`fast-path`, `implementation-execution`, `verification`,
`spec-evidence-governance`).

Constraint: if the adopter adopts ANY skill, they MUST
include `spec-authoring` and `spec-review` (they are the
lifecycle's IDEA → SPEC → review gate; adopting downstream
skills without them violates the lifecycle).

### K-2: Hook activation set

Knob: which of the seven hooks the adopter enables in
their `.claude/settings.json` (or equivalent
PreToolUse-hook surface).

Default: enable all seven hooks; the framework's discipline
assumes all are active.

Constraint: the four block-* hooks (block-ai-attribution,
block-edit-on-main, block-git-add-all, block-verify-bypass)
are the MINIMUM viable set; disabling any of them is
ALLOWED per local risk acceptance but the adopter inherits
responsibility for the discipline they enforce.

### K-3: Branch policy declaration

Knob: per-SPEC `branch_policy` front-matter — values
`worktree-preferred` (default; agents work in worktrees)
or `main-direct` (edits on main allowed during this SPEC's
in-execution/verified/closed phases).

Default: `worktree-preferred`.

Constraint: `main-direct` is permissible only for SPECs
that the adopter has approved with the
`block-edit-on-main` + `block-push-to-main` hooks
honouring the policy.

### K-4: CI job set

Knob: which CI jobs the adopter runs.

Default: lint-spec + validate-skill-frontmatter +
hook-test-harness + validate-manifest (the four jobs in
the framework's reference CI workflow).

Constraint: lint-spec MUST run on every push; the rest
are recommended.

### K-5: Tracker integration

Knob: which issue tracker the adopter uses + how their
SPEC slices map to tracker issues.

Default: no binding (issue tracker integration is
adopter-provided).

Constraint: per the `autonomous-issue-dispatch` skill
(`file://../skills/autonomous-issue-dispatch/SKILL.md`),
if the adopter uses tracker-driven dispatch, their TASK.md
slices SHOULD map 1:1 to tracker issues.

### K-6: Verification gate sensitivity

Knob: whether the adopter treats lint advisory (exit 2)
as a CI failure or warning.

Default: exit 2 is advisory (CI passes; reviewer notes).

Constraint: for Contract SPECs the lint MUST exit 0;
exit 2 is permissible only for Task / Decision / Fastpath.

### K-7: Cross-family review enforcement

Knob: whether the adopter requires external cross-family
review or accepts same-family proxy.

Default: external cross-family review RECOMMENDED for
every approved-pending-owner → approved transition;
same-family proxy ACCEPTABLE with explicit caveat.

Constraint: the framework's own evolution requires
external cross-family for Contract SPECs that touch
the schema or lifecycle.

## Customization examples

For named reference profiles, see `profiles/*.yaml` (to
be populated as v2.x slices land). Initial profile
candidates:

- `solo-developer.yaml` — minimal skill set, all hooks
  enabled, exit 2 = failure (strict).
- `studio-fleet.yaml` — full skill set + cross-repo
  patterns, fleet-sync configured, exit 2 = advisory.
- `open-source-project.yaml` — full skill set, no AI
  attribution strict, public OSS posture gitignore
  patterns adopted.

## Schema

The mechanical knob enumeration is in `knobs.schema.json`
(JSON Schema; to be populated). The schema validates an
adopter's `customization.yaml` (or equivalent) against
this contract.
