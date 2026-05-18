---
name: tdd
description: "Use when implementing a behavior change (feature, bug fix) where a runnable test can describe the expected behavior. Write the check first (red), implement (green), refactor. Do not use for refactors that preserve behavior — use implementation-execution alone."
---

# TDD

Use this skill for behavior changes where a test, fixture, lint case,
scripted check, or executable example can express the desired behavior.

TDD is a tactic, not a universal mandate. Some approved specs verify
through manual review, visual checks, release evidence, or document
lint. Use the verification method required by the approved SPEC.

## Loop

1. Identify the public behavior or contract being changed.
2. Write or update the narrowest meaningful failing check.
3. Run it and confirm it fails for the expected reason.
4. Implement the smallest change that makes the check pass.
5. Re-run the focused check.
6. Refactor only after the check passes.
7. Run the SPEC acceptance commands or directly coupled broader gate.

## Good Checks

- Exercise public behavior rather than private implementation details.
- Describe user-visible, contract-visible, or workflow-visible behavior.
- Stay deterministic.
- Fail clearly when the behavior regresses.
- Fit into the repo's existing test or lint style.

## When Not To Force It

Do not invent a weak test just to satisfy the tactic when:

- The approved SPEC names a different verification method.
- The change is docs-only and covered by spec lint or manual review.
- The behavior requires visual, release, infrastructure, or owner
  review evidence.
- The repo lacks a practical harness and adding one is outside scope.

Record the reason and run the best approved verification instead.

## Hard Rules

- Do not make TDD outrank the approved SPEC acceptance plan.
- Do not add brittle tests that only pin implementation details.
- Do not skip existing acceptance commands after the focused check
  passes.
- Do not claim completion without fresh verification output.
