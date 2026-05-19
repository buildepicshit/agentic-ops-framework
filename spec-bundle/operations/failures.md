# Operations — Failure Model

Failure classes × recovery posture per the Symphony §14
pattern
(`file://../../research/primary-sources/symphony-spec.md`
§3 — transferable building block 10).

## Failure classes

### F-1: Lint regression

**Trigger**: a change to a spec / skill / template
causes `scripts/lint-spec.sh` to exit non-zero.

**Detection**: CI's `lint-spec` job; local `bash
scripts/lint-spec.sh <target>` invocation.

**Recovery**:
1. Author reads the lint stderr; addresses each
   diagnostic (citation prefix missing, RFC 2119 keyword
   in wrong section, etc.).
2. Re-runs lint locally until exit 0.
3. CI re-runs on push.

**Operator lever**: none required; mechanical fix.

### F-2: Hook test failure

**Trigger**: `bash tests/hooks/run-tests.sh` reports a
fail.

**Detection**: CI's `test-hooks` job; local invocation.

**Recovery**:
1. Identify the failing test from harness output.
2. If a hook regressed: fix the hook + add test for the
   regression (TDD per the `tdd` skill).
3. If the test itself was wrong: fix the test fixture
   or the assertion.

**Operator lever**: none for the framework's own
hooks; an adopter may disable specific hooks per K-2
in `../customization/contract.md`.

### F-3: Manifest validation failure

**Trigger**: `bash scripts/validate-manifest.sh` exits
non-zero.

**Detection**: CI's `validate-manifest` job; local
invocation.

**Recovery**:
1. Read stderr diagnostics: which facet is missing? which
   primary file is absent?
2. Reconcile manifest vs. filesystem (add missing
   facet directory + primary, or remove orphan
   directory, or update manifest entry).
3. Re-run validate-manifest until PASS.

**Operator lever**: schema version drift requires a
Contract SPEC amendment to §6.1 of the repack SPEC.

### F-4: Cross-reference rot

**Trigger**: an artefact's `file://X` reference points
at a path that no longer exists (after a refactor).

**Detection**: lint-spec.sh does not validate file paths
deeply; manual review or a separate cross-reference
checker (out of scope for v2.0).

**Recovery**:
1. Update the reference to the new path.
2. Consider authoring a Task SPEC for a cross-reference-
   validator script as a v2.x slice.

**Operator lever**: none.

### F-5: CI workflow regression

**Trigger**: a change to `.github/workflows/ci.yml`
breaks CI.

**Detection**: CI fails on the first push after the
workflow change.

**Recovery**:
1. Read CI run logs via `gh run view`.
2. Revert or fix the workflow change.
3. Verify CI green on next push.

**Operator lever**: none mid-flight; the workflow file
must land correct.

### F-6: Hook false-positive in real session

**Trigger**: a hook blocks a legitimate operation an
agent or user was attempting (e.g., `block-git-add-all`
fires on a heredoc body containing `git add .`).

**Detection**: user reports; agent surfaces blocker in
workpad.

**Recovery**:
1. Examine the hook's match logic.
2. Add a false-positive test fixture to
   `tests/hooks/fixtures/` capturing the case.
3. Tighten the match logic so the test passes AND the
   real-trigger tests still pass.

**Operator lever**: temporarily disable the hook via
`.claude/settings.local.json` (K-2 deferral); fix +
re-enable promptly.

### F-7: Spec lifecycle stuck at owner-blocking

**Trigger**: a SPEC's status is `owner-blocking` for an
extended period.

**Detection**: STATUS.md inventory; `/orient`-style
session start hook.

**Recovery**:
1. Owner reviews the blocking question(s) in the SPEC's
   §16 / §17 Open Questions.
2. Owner authors a `decision-authority://owner:<date>`
   resolution.
3. Author updates §7 (or §3 Authority Map) with the
   resolution; lifecycle continues.

**Operator lever**: owner-only.

## Recovery posture

The framework's failure model is **fail loud, recover
mechanically**. Every failure class has a deterministic
exit code (lint, validate, hooks); the recovery is
either mechanical (fix + re-run) or owner-routed
(judgment required).

No silent failures, no fallbacks. Per `../non-goals/INDEX.md`
the framework does NOT provide automatic remediation;
fixing is the contributor's responsibility.
