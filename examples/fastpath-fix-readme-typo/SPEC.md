---
id: 2026-02-14-fix-readme-typo
status: closed
type: fastpath
owner: owner-A
repo: your-policy-repo
branch_policy: worktree-preferred
risk: low
requires_network: false
requires_secrets: []
acceptance_commands:
  - grep -q "spec-driven" README.md
  - grep -qv "spec-drvien" README.md
ideated_in: null
---

# SPEC (fast-path): Fix typo in README.md introduction

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem

`file://README.md` line 3 contained the typo "spec-drvien"
(should read "spec-driven"). A community contributor flagged it
in `url://github.com/your-org/your-repo/issues/142`. Single-
character transposition; one file; reversible.

## 2. Files changed

- `file://README.md` — line 3: `spec-drvien` → `spec-driven`.
  Single-character fix; net change: 0 lines added, 0 removed,
  1 modified.

## 3. Owner directive

`decision-authority://owner:2026-02-14` (in PR review comment
on the issue thread):

> "Yes obviously, just fix it. Don't make a thing of it."

## 4. Acceptance commands

- `cmd://grep -q "spec-driven" README.md` — the corrected
  word is present after the fix.
- `cmd://grep -qv "spec-drvien" README.md` — the misspelled
  form is no longer present.

## 5. Completion Report

### 5.1 Verification result

| Check | Result |
|---|---|
| `grep -q "spec-driven" README.md` | PASS |
| `grep -qv "spec-drvien" README.md` | PASS |
| Manual review of the diff (1-character change) | PASS |

### 5.2 Residual risk

None. The fix is a single-character correction in prose; no
behavioural surface touched, no public-contract implication,
no reviewer disagreement plausible. If a reader complains
about the change in the next 30 days, revert is one commit.
