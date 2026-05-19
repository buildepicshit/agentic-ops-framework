---
name: code-review
description: "Use for reviewing local diffs, branches, or PRs. Prioritises bugs, regressions, missing tests, unsafe assumptions, and broken repo contracts over surface polish. Do not use to author or review SPEC.md / IDEA.md artefacts — use spec-review for that BLOCKING gate."
---

# Code Review

Use this when asked to review.

## Review Focus

- Correctness bugs.
- Behavioral regressions.
- Missing or weak tests.
- Security, privacy, or secret-handling risks.
- Broken architecture boundaries.
- Drift from `AGENTS.md`, approved specs, or public docs.
- Verification gaps.

## Two-Stage Review For Decomposed Work

For substantial parallel work or slices produced by
`approved-spec-decomposition`, review in this order:

1. SPEC compliance: confirm the slice stayed inside approved scope,
   touched only allowed ownership, preserved acceptance evidence, and
   did not create a peer authority beside SPEC.md.
2. Code quality: review correctness, regressions, maintainability,
   security, tests, and verification gaps.

If the first pass finds scope drift, stop there and request correction
before spending review effort on style or deeper implementation detail.

## Output

Findings first, ordered by severity. Each finding should include:

- file and line reference when available
- the concrete risk
- why the current change causes it
- a practical fix direction

Then include open questions and a brief summary only after findings.

## Hard Rules

- If there are no findings, say that clearly and list residual risk.
- Do not lead with praise or broad summaries.
- Do not request stylistic churn unless it affects correctness,
  maintainability, or repo contracts.
- **Cross-family review for TASK.md execution.** When reviewing a
  diff produced by an agent fulfilling a TASK.md, the reviewer
  SHOULD run on a different model family from the TASK.md
  `model_route`. The TASK.md `cross_validation_lane` names the
  expected family. If only same-family review is available, record
  `same-family-review: <model>` in the output and surface as a
  residual risk. See
  `file://your model-routing policy` and
  `your parallelism-and-routing SPEC`
  §7.3.
- **Read-only.** Cross-validation reviewers MUST NOT edit files
  during review; they emit findings only. The primary executor
  addresses findings or posts justified pushback.
