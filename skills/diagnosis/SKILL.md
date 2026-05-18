---
name: diagnosis
description: "Use when debugging a failure, flaky behavior, regression, broken command, or unclear root cause. Builds a fast deterministic feedback loop before fixing."
---

# Diagnosis

Use this skill when the task is to understand why something fails,
regressed, flakes, or behaves unexpectedly.

Diagnosis comes before fixing. The output of diagnosis is evidence:
reproduction, observations, likely root cause, and the narrowest safe
fix direction.

## Procedure

1. Restate the symptom in observable terms.
2. Find the fastest deterministic feedback loop available: focused
   test, lint, command, log excerpt, local reproduction, or minimal
   fixture.
3. Reproduce the failure or record why reproduction is unavailable.
4. Inspect the relevant code, docs, and recent diff before proposing a
   fix.
5. Form one small hypothesis at a time.
6. Test the hypothesis with the feedback loop.
7. Apply the smallest fix that explains the observed failure.
8. Re-run the feedback loop and any directly related acceptance checks.

## Stop And Reframe

Stop and reframe before continuing when:

- Two plausible fixes fail.
- The failure contradicts the approved SPEC.
- The root cause requires changing behavior outside approved scope.
- The feedback loop is too slow or nondeterministic to support safe
  iteration.
- The evidence points to architecture, environment, secrets, or
  external service behavior rather than the local change.

## Output

Report:

- Symptom.
- Reproduction command or reason reproduction is unavailable.
- Key evidence.
- Root cause or strongest remaining hypothesis.
- Fix direction.
- Verification command and result.
- Residual risk.

## Hard Rules

- Do not guess a fix before checking the code and available evidence.
- Do not treat a passing unrelated command as proof.
- Do not expand implementation scope without an approved SPEC update.
- Do not claim completion without fresh verification evidence.
