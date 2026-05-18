---
id: [YYYY-MM-DD-kebab-case-topic]
status: closed
type: fastpath
owner: [owner-identifier]
repo: [repo-name]
branch_policy: worktree-preferred
risk: low
requires_network: false
requires_secrets: []
acceptance_commands: []
ideated_in: null
---

<!--
Fast-path SPEC template. Use ONLY when ALL fast-path thresholds in
`file://skills/fast-path/SKILL.md` "Thresholds" are met. If
your work exceeds any threshold, escalate to a full task/contract/
decision SPEC via the standard `/idea-capture` → `/author-spec`
flow.

Fast-path SPECs use the **capture-after** pattern by default
(`file://skills/spec-driven-development/SKILL.md`
"Exception: capture-after"): the work is performed first under
owner directive, then this SPEC is filed as the citable authority
record. The artefact lands at `status: closed` in the same commit
as the work itself, never later.

NO ceremony: no IDEA artefact, no blocking review gate, no
decomposition, no cross-validation lane (covered by the work
itself being small enough to be reviewed inline). Owner approval
is the inline commit message.

Fast-path SPECs MUST cite their authorising owner directive in §3.
-->

# SPEC (fast-path): [Title]

## Normative Language

The key words `MUST`, `MUST NOT`, `REQUIRED`, `SHALL`, `SHALL NOT`,
`SHOULD`, `SHOULD NOT`, `RECOMMENDED`, `MAY`, and `OPTIONAL` in this
document are to be interpreted as described in RFC 2119 and RFC 8174
when, and only when, they appear in all capitals.

## 1. Problem

[One paragraph. What was broken or missing. Cite the file/issue/
owner message that surfaced it.]

## 2. Files changed

[List the files touched. Single component, ≤ 1 file or ≤ 50 lines
total. If this list exceeds the threshold, this SPEC is wrong-typed
— rewrite as task/contract.]

## 3. Owner directive

[Verbatim quote of the owner directive that authorised the
fast-path. Cite `owner://transcript-<YYYY-MM-DD>` or
`judgment://owner` paired with transcript backing.]

> [verbatim owner quote]

## 4. Acceptance commands

[Inline list of commands that exit 0 to demonstrate the change
works. Subset of the parent repo's gates. lint-spec lint of this
file is implicit and not listed.]

- `cmd://...`

## 5. Completion Report

### 5.1 Verification result

| Check | Result |
|---|---|
| [acceptance command 1] | PASS |
| [acceptance command 2] | PASS |

### 5.2 Residual risk

[One paragraph at most. If residual risk is "real" or "non-trivial",
this work should have been a full SPEC. Honest framing here keeps
the fast-path honest.]

## Hard rules (template-enforced)

Fast-path SPEC files MUST:
- Lint-pass under `scripts/lint-spec.sh` fastpath mode.
- Be ≤ 100 lines total (this template is the upper bound).
- Cite owner directive in §3.
- Land at `status: closed` in the same commit as the work.
- Skip IDEA, review, decomposition, cross-validation phases.

If any rule above is hard to satisfy, the work isn't fast-path
material — escalate to a full SPEC type.
