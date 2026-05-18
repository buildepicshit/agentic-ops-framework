---
name: verification
description: Use before reporting done. Runs the narrowest relevant checks first, then the repo gate when warranted, and records fresh evidence plus residual risk.
---

# Verification

Use before claiming work is complete.

## Steps

1. Read the spec acceptance commands and repo `AGENTS.md` verification section.
2. Run the narrowest relevant test or lint first.
3. Run the broader repo gate when the change touches shared behavior,
   interfaces, CI, docs contracts, or release surfaces.
4. For decomposed work, verify slice evidence first, then run final
   integration acceptance commands from the approved SPEC.
5. Capture command, result, and important output.
6. If a command fails, diagnose whether the failure is caused by the change,
   existing repo state, missing dependency, sandbox/network limits, or secrets.
7. Re-run only after a meaningful fix or environment change.

## Output

- Commands run.
- Pass/fail result.
- Key output lines or summarized failures.
- For decomposed work, slice evidence and final integration evidence.
- Residual risk.
- Checks not run and why.

## Hard Rules

- Do not say "should pass" as verification.
- Do not hide failing checks.
- Do not spend CI minutes when local gates are required first.
- **Cross-family verification for behavioral checks.** Mechanical
  verification (lint, unit tests, type checks) MAY use the same
  model family as implementation. **Behavioral verification** —
  confirming the change actually delivers the SPEC's named outcome
  — SHOULD use a different model family from the implementer per
  the TASK.md `verification_lane`. Same-family behavioral
  verification inherits the same reasoning blind spots. See
  `file://your model-routing policy` and
  `your parallelism-and-routing SPEC`
  §7.3.
- **Integration gate.** When a parent SPEC's TASK.md set all reach
  `done`, the integration verifier runs the parent SPEC's full
  `acceptance_commands` as the gate before flipping
  `decomposed → in-execution → verified`. Per-task evidence MUST
  be aggregated into the parent SPEC's Completion Report.
