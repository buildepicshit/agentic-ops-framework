---
id: adopt-conventional-commits
spec_id: 2026-02-03-adopt-conventional-commits
status: ready-for-spec
owner: owner-A
brainstormed_by: claude-opus-4-7
brainstormed_on: 2026-02-03
implies_spec_type: decision
---

# Adopt Conventional Commits for the engineering org

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem Seed

Commit messages across the engineering org are inconsistent.
`cmd://git log --since='90 days ago' --pretty=format:'%s' |
head -20` returns a mix of `Fix bug`, `wip`, `Update README`,
`feat(auth): add OAuth flow`, `fixed the thing finally lol`,
and `chore: bump deps`. Two consequences are surfacing:

- The auto-generated changelog
  (`file://scripts/generate-changelog.sh`) produces a noisy
  output that requires manual editing before every release;
  the release manager reports ~2 hours of post-hoc commit
  triage per release
  (`file://docs/release-process.md` §"changelog generation").
- Semantic versioning decisions (patch / minor / major) are
  judgment-called per release instead of derived from commit
  types, which has caused two version bumps in the past
  quarter where a feature commit was missed
  (`file://docs/release-notes/v2.4.0.md`,
  `file://docs/release-notes/v2.5.1.md`).

Owner directive
(`decision-authority://tech-lead:2026-02-01`):

> "I'm tired of arguing about whether a commit warrants a
> minor version bump. Pick a convention. Enforce it via a
> hook. Move on."

## 2. Substance Citations

- `cmd://git log --since='90 days ago' --pretty=format:'%s'`
  — observed inconsistency across the corpus.
- `url://www.conventionalcommits.org/en/v1.0.0/` — the
  Conventional Commits 1.0.0 spec.
- `url://github.com/angular/angular/blob/main/CONTRIBUTING.md#commit`
  — Angular's variant (the precedent that Conventional Commits
  itself derives from).
- `url://github.com/gitmoji/gitmoji` — gitmoji style
  (emoji-prefixed commits); cited for awareness, not adoption.
- `file://scripts/generate-changelog.sh` — the current
  release-time changelog script.
- `file://docs/release-process.md` §"changelog generation" —
  release manager pain point.
- `file://docs/release-notes/v2.4.0.md`,
  `file://docs/release-notes/v2.5.1.md` — two recent missed-
  bump incidents.
- `decision-authority://tech-lead:2026-02-01` — the
  "pick a convention" directive.

## 3. Constraints & Non-Negotiables

- Enforcement MUST be a pre-commit hook check, not a
  best-effort culture norm.
  (`decision-authority://tech-lead:2026-02-01`)
- Whatever convention is adopted MUST be machine-parseable
  enough for the changelog script to consume.
  (`file://scripts/generate-changelog.sh` — current consumer.)
- The convention MUST NOT require any tooling install beyond
  what's already in the repo (no Husky on Node, no commitizen,
  no global commitlint install). One small bash hook only.
  (`decision-authority://tech-lead:2026-02-01` — implicit;
  "move on" rules out heavy tooling.)
- The convention MUST be self-explanatory enough that a new
  contributor reading `CONTRIBUTING.md` can adopt it without
  studying an external spec for more than 10 minutes.
  (`judgment://agent-synthesis` — adoption ergonomic constraint.)

## 4. Approaches Considered

### 4.1 Status quo — culture-only

- Sketch: keep current freeform commits; add a paragraph to
  `CONTRIBUTING.md` requesting structured messages.
- Fit: low — culture norms decay without enforcement; the
  observed corpus is the evidence.
- Cost: zero.
- Risk: the problem persists.

### 4.2 Conventional Commits (full 1.0.0 spec)

- Sketch: adopt `<type>(<optional scope>): <subject>` per
  `url://www.conventionalcommits.org/en/v1.0.0/`. Allowed
  types per the spec: `feat`, `fix`, plus a recommended
  extensions set (`build`, `chore`, `ci`, `docs`, `style`,
  `refactor`, `perf`, `test`). Breaking changes marked with
  `!` or `BREAKING CHANGE:` footer.
- Fit: high — broad ecosystem support, machine-parseable,
  changelog tooling exists.
- Cost: bounded — write the hook + update
  `CONTRIBUTING.md` + retrain.
- Risk: low. The 10-minute-learnability target is met
  (single-page spec, ~30 lines of rules).

### 4.3 Custom org-specific DSL

- Sketch: invent a slightly different convention tailored to
  this org's workflow (e.g., `feature/AUTH-123: short
  description` referencing tracker tickets).
- Fit: medium — fits the local workflow but doesn't
  inter-operate with external tooling.
- Cost: medium — design + document + maintain.
- Risk: bus-factor 1; new joiners learn an org-private
  convention.

### 4.4 Gitmoji

- Sketch: emoji-prefixed commits (`:sparkles: add feature`,
  `:bug: fix crash`).
- Fit: low — fun but the changelog parser would have to map
  emoji glyphs to semantic types, adding complexity for no
  gain over 4.2.
- Cost: same as 4.2.
- Risk: emoji rendering issues in some terminals / CI logs.

### 4.5 Angular-style (the original)

- Sketch: same shape as Conventional Commits but with
  Angular's slightly different type set (e.g., includes
  `build` but not `ci` as separate).
- Fit: medium-high — established precedent but a stricter
  subset.
- Cost: same as 4.2.
- Risk: lower ecosystem support than vanilla Conventional
  Commits.

## 5. Recommendation

**Approach 4.2 — Conventional Commits 1.0.0**
(`judgment://agent-synthesis`, affirmed in §7 by
`decision-authority://tech-lead:2026-02-01`).

Rationale: 4.1 leaves the problem unsolved. 4.3 reinvents
what 4.2 already provides with worse tooling. 4.4's emoji
prefix doesn't add value over a textual prefix. 4.5 is a
near-equivalent of 4.2 but with weaker ecosystem support and
no compensating advantage. 4.2 has broad ecosystem support
(`url://github.com/conventional-commits/conventionalcommits.org`
lists implementations in 30+ languages), a sub-30-line spec,
and matches the existing changelog script's parsing needs.

## 6. Open Questions for Owner

- [x] **Q1**: Which approach? — Resolved 4.2 per
  `decision-authority://tech-lead:2026-02-01` "pick a
  convention" directive + agent recommendation §5.
- [x] **Q2**: Allowed types beyond `feat` / `fix`? — Resolved:
  the Conventional Commits-recommended set: `feat`, `fix`,
  `build`, `chore`, `ci`, `docs`, `style`, `refactor`,
  `perf`, `test`. (`decision-authority://tech-lead:2026-02-02`)
- [x] **Q3**: Enforcement mechanism — git commit-msg hook,
  CI check, or both? — Resolved: **commit-msg hook**
  (developer-side, immediate feedback). CI gate as a
  belt-and-suspenders second check on the PR's commits.
  (`decision-authority://tech-lead:2026-02-02`)
- [x] **Q4**: Migration of existing history? — Resolved: no
  rewrite. The convention applies from the SPEC's `closed`
  date forward; pre-existing commits are grandfathered.

## 7. Owner Judgments

- `decision-authority://tech-lead:2026-02-01`:
  > "I'm tired of arguing about whether a commit warrants a
  > minor version bump. Pick a convention. Enforce it via a
  > hook. Move on."

  Binds: §1 framing, §3 enforcement constraint, §5 (the
  decisive "pick" directive).

- `decision-authority://tech-lead:2026-02-02`:
  > "Use the Conventional Commits canonical type set. No
  > custom extensions. If we need a new type later, it's a
  > follow-on Decision SPEC."

  Binds: §6 Q2 type-set scope; §6 Q3 enforcement mechanism.
