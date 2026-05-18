---
id: 2026-02-03-adopt-conventional-commits
status: approved
type: decision
owner: owner-A
repo: your-policy-repo
branch_policy: worktree-preferred
risk: low
requires_network: false
requires_secrets: []
acceptance_commands:
  - bash scripts/lint-spec.sh examples/decision-conventional-commits/SPEC.md
ideated_in: examples/decision-conventional-commits/IDEA.md
---

# SPEC: Adopt Conventional Commits for the engineering org

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

In Decision SPECs, RFC 2119 keywords appear ONLY in §7. Decision
Statement. They do not appear in any other section of this document.

## 1. Problem

Commit messages across the org are inconsistent
(`cmd://git log --since='90 days ago' --pretty=format:'%s'`
shows mixed styles). The auto-generated changelog
(`file://scripts/generate-changelog.sh`) requires manual
post-hoc triage on every release; the release manager reports
~2 hours per release of cleanup
(`file://docs/release-process.md`). Two missed minor-version
bumps in 90 days
(`file://docs/release-notes/v2.4.0.md`,
`file://docs/release-notes/v2.5.1.md`) trace to ambiguous
commit messages where a feature looked like a fix or vice
versa. Tech lead directive
(`decision-authority://tech-lead:2026-02-01`):

> "I'm tired of arguing about whether a commit warrants a minor
> version bump. Pick a convention. Enforce it via a hook. Move
> on."

## 2. Substance Citations

- `url://www.conventionalcommits.org/en/v1.0.0/` — the
  Conventional Commits 1.0.0 spec.
- `url://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit`
  — Angular's variant; the precedent Conventional Commits
  derives from.
- `url://github.com/conventional-commits/conventionalcommits.org`
  — implementations in 30+ languages.
- `file://scripts/generate-changelog.sh` — current changelog
  consumer; needs machine-parseable commit messages.
- `file://examples/decision-conventional-commits/IDEA.md` §4-§5 —
  producing IDEA's approaches-considered + recommendation.
- `decision-authority://tech-lead:2026-02-01` — the directive
  motivating this Decision.
- `decision-authority://tech-lead:2026-02-02` — type-set scope
  + enforcement-mechanism resolutions (IDEA §6 Q2-Q3).

## 3. Authority Map

Active authority for this decision:

- `examples/decision-conventional-commits/IDEA.md` —
  producing IDEA at `ready-for-spec` with §6 dispositioned.
- `decision-authority://tech-lead:2026-02-01` — "pick a
  convention, enforce via a hook, move on."
- `decision-authority://tech-lead:2026-02-02` — type-set
  scope + enforcement-mechanism resolutions.
- `url://www.conventionalcommits.org/en/v1.0.0/` — wire-format
  authority for what's adopted.

Stale, superseded, or evidence-only sources:

- `url://github.com/gitmoji/gitmoji` — cited in IDEA §4.4 as
  considered-and-rejected; evidence-only.

Owner decisions required before implementation:

- [x] All resolved in IDEA §6.

## 4. Decision Criteria

| Criterion | Source | Weight |
|---|---|---|
| Machine-parseable for changelog tooling | `file://scripts/generate-changelog.sh` | high |
| Sub-30-line spec, 10-minute-learnability | `decision-authority://tech-lead:2026-02-01` "move on" | high |
| Broad ecosystem support (libraries / converters in many languages) | `url://github.com/conventional-commits/conventionalcommits.org` | medium |
| Enforceable via a small bash commit-msg hook (no Node toolchain) | `decision-authority://tech-lead:2026-02-01` | high |
| Backward-compat with pre-SPEC history | IDEA §6 Q4 | medium |
| Allows for future type extension without rework | `judgment://agent-synthesis` | low |

## 5. Candidate Options

Each candidate is an agent-synthesis comparison of an
existing approach against the §4 criteria. Synthesis bound by
`decision-authority://tech-lead:2026-02-01` affirmation in §7.

### 5.1 Status quo (culture-only)
(`judgment://agent-synthesis`)

- Description: keep current freeform commits; add a paragraph
  to `CONTRIBUTING.md` requesting structured messages.
- Fit with substance: low — culture decay is empirically the
  current state (`cmd://git log --since='90 days ago' --pretty=format:'%s'`
  shows mixed styles).
- Fit with constraints: high (zero work).
- Cost: zero.
- Risk: high — the problem persists.

### 5.2 Conventional Commits 1.0.0
(`judgment://agent-synthesis`)

- Description: adopt `<type>(<optional scope>): <subject>` per
  the spec at `url://www.conventionalcommits.org/en/v1.0.0/`.
  Types: `feat`, `fix`, `build`, `chore`, `ci`, `docs`,
  `style`, `refactor`, `perf`, `test`. Breaking changes marked
  with `!` or `BREAKING CHANGE:` footer.
- Fit with substance: high — broad ecosystem support
  (`url://github.com/conventional-commits/conventionalcommits.org`);
  machine-parseable; matches existing changelog parser shape.
- Fit with constraints: high — single-page spec at
  `url://www.conventionalcommits.org/en/v1.0.0/`; enforceable
  in <50 lines of bash.
- Cost: bounded — write the hook + update `CONTRIBUTING.md`
  + retrain the team. (`judgment://agent-synthesis`)
- Risk: low. Spec is mature (1.0.0 since 2021).
  (`url://www.conventionalcommits.org/en/v1.0.0/`)

### 5.3 Custom org DSL
(`judgment://agent-synthesis`)

- Description: invent a slightly different convention
  tailored to the org's workflow (e.g., embed tracker ticket
  ids).
- Fit with substance: medium. (`judgment://agent-synthesis`)
- Fit with constraints: medium — broader bus-factor concern.
- Cost: medium (design + document + maintain).
  (`judgment://agent-synthesis`)
- Risk: doesn't inter-operate with external tooling;
  new-joiner onboarding cost. (`judgment://agent-synthesis`)

### 5.4 Angular-style (precedent)
(`judgment://agent-synthesis`, see
`url://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit`)

- Description: same shape as 5.2 with a stricter / different
  type set per
  `url://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit`.
- Fit with substance: medium-high. (`judgment://agent-synthesis`)
- Fit with constraints: high. (`judgment://agent-synthesis`)
- Cost: same as 5.2. (`judgment://agent-synthesis`)
- Risk: weaker ecosystem support than vanilla Conventional
  Commits. (`judgment://agent-synthesis`)

## 6. Trade-off Comparison

| Criterion | 5.1 status quo | 5.2 Conventional Commits | 5.3 custom DSL | 5.4 Angular-style |
|---|---|---|---|---|
| Changelog parseable | no | yes | yes (custom parser) | yes |
| 10-min learnability | n/a | yes (single page) | partial (private doc) | yes |
| Broad ecosystem | n/a | yes (30+ langs) | no | medium |
| Hook enforceable in bash | n/a | yes (~30 lines) | yes (custom) | yes |
| Backward-compat | trivial | yes (grandfather pre-SPEC commits) | yes | yes |
| Future extension | n/a | yes (BREAKING CHANGE + new types) | yes | yes |

## 7. Decision Statement

The engineering org SHALL adopt Conventional Commits 1.0.0 as
the binding commit-message convention.

Commit messages in repos covered by this Decision MUST conform
to the format:

```
<type>[optional scope]: <subject>

[optional body]

[optional footer(s)]
```

where:

- `<type>` MUST be one of `feat`, `fix`, `build`, `chore`,
  `ci`, `docs`, `style`, `refactor`, `perf`, `test`.
- `<scope>`, when present, MUST be a single lowercase token in
  parentheses (e.g., `feat(auth): …`).
- `<subject>` MUST be ≤ 72 characters, present-tense
  imperative ("add" not "added"), no trailing period.
- Breaking changes MUST be marked with either a `!` after the
  type (`feat!: …`) or a `BREAKING CHANGE:` footer in the
  commit body.

Enforcement MUST be a `.githooks/commit-msg` hook that rejects
non-conforming messages on commit creation. The hook MUST be
copy-only (no Node / Python / external library dependency).
The hook is RECOMMENDED to also be enforced as a CI check on
PR commits as a belt-and-suspenders gate.

Future type-set extensions (adding a new `<type>` value) MUST
land as a new Decision SPEC superseding this one. Ad-hoc type
additions outside that path MUST NOT be merged.

Existing commit history pre-dating this SPEC's `closed` date is
grandfathered and MUST NOT be rewritten.

## 8. Decision Rationale

5.2 Conventional Commits 1.0.0 was chosen because it dominates
every weighted criterion in the §6 matrix
(`file://examples/decision-conventional-commits/SPEC.md` §6
trade-off matrix). 5.1 fails the load-bearing
machine-parseable + enforceability criteria. 5.3 introduces a
bus-factor risk for no compensating advantage over 5.2. 5.4 is
near-equivalent to 5.2 but with weaker ecosystem support.

The tech lead directive at
`decision-authority://tech-lead:2026-02-01` ("pick a
convention, enforce via a hook, move on") closed the design
space. The IDEA §5 recommendation arrived at 5.2 on the same
weighted-criteria comparison and was affirmed at
`decision-authority://tech-lead:2026-02-02` (type-set + hook
mechanism).

## 9. Locks

Unlocks:

- A follow-on Task SPEC implementing the `.githooks/commit-msg`
  hook + `CONTRIBUTING.md` update + `docs/release-process.md`
  rewrite around the new convention.
- The changelog script (`file://scripts/generate-changelog.sh`)
  can be simplified once it can rely on conforming input.
- Semantic-versioning automation can be wired to the type
  field (`feat` → minor bump, `fix` → patch, `!` /
  `BREAKING CHANGE` → major).

Forecloses:

- Adding a new `<type>` outside a new Decision SPEC.
- Gitmoji or custom-DSL adoption without superseding this
  Decision.
- Rewriting pre-SPEC history.

## 10. Reversal Plan

Triggers for reconsideration:

- Developer-friction telemetry (commit-msg hook rejection
  rate) exceeds 20% sustained over 30 days; suggests the
  convention is too strict for daily use.
- Conventional Commits 2.0 ships with breaking changes;
  re-evaluate adoption at that point.
- The changelog tool migrates to a different parser format
  (the dependency that's load-bearing here flips).

Exit procedure:

1. Author a superseding Decision SPEC.
2. Revert the `.githooks/commit-msg` hook to a no-op (or
   delete it).
3. Notify the team in `CONTRIBUTING.md`.
4. Existing commits remain valid in their format; no rewrite.

## 11. Validation Plan

- Check 1: candidates 5.1-5.4 are real and distinct — verified
  by §6 matrix population.
- Check 2: chosen option is feasible — verified by a sample
  `.githooks/commit-msg` script in
  `file://docs/conventional-commits-hook.example.sh` that
  enforces the §7 rules in ~30 lines of bash.
- Check 3: §9 Locks and §10 Reversal Plan are populated and
  coherent — verified by §11 Check 3 (this checkbox).
- Check 4: §7 Decision Statement names exactly one chosen
  candidate (5.2 Conventional Commits 1.0.0) with specific,
  verifiable normative requirements.

## 12. Acceptance Criteria

- [ ] AC-1: Decision Statement (§7) names exactly one chosen
  option.
- [ ] AC-2: At least 2 candidates compared in §5 with all
  required fields populated (4 candidates present).
- [ ] AC-3: Trade-off matrix (§6) is complete for all
  candidates and criteria.
- [ ] AC-4: Locks (§9) and Reversal Plan (§10) are populated.
- [ ] AC-5: Decision Rationale (§8) cites the trade-off matrix
  and the binding directive.
- [ ] AC-6: This SPEC passes `cmd://bash scripts/lint-spec.sh`
  with exit 0.
- [ ] AC-7: Completion Report §14 records when and how the
  decision was communicated to dependents (CONTRIBUTING.md
  update + team announcement).

## 13. Open Questions

- [x] All design questions resolved in IDEA §6.

## 14. Completion Report

(to be filled by the executor — see template sections 14.1
through 14.5)

### 14.1 Files changed

(to be filled)

### 14.2 Commands run

(to be filled)

### 14.3 Verification result

(to be filled)

### 14.4 Residual risk

(to be filled)

### 14.5 Spec evidence candidates

(to be filled — durable lessons for the spec-evidence-governance skill)
