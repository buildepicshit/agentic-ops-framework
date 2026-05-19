# Operations — Safety Invariants

MUST-numbered safety list per the Symphony §9.5 pattern
(`file://../../research/primary-sources/symphony-spec.md`
§3 — transferable building block 7). Each invariant is a
hard rule the framework's tooling enforces or the
adopter's discipline upholds.

## Tooling-enforced (PreToolUse hooks)

The framework's seven hooks in `../../hooks/` enforce:

- **SI-1**: Commits MUST NOT contain AI-attribution
  trailers (`Co-Authored-By: Claude`,
  `Co-Authored-By: GPT-...`, or equivalent). Enforced
  by `hooks/block-ai-attribution.sh`.
- **SI-2**: Staging MUST be explicit by path. Bulk
  staging (`git add .`, `git add -A`, `git add :/`) is
  rejected. Enforced by `hooks/block-git-add-all.sh`.
- **SI-3**: Verify gates MUST NOT be bypassed.
  `--no-verify` / `VERIFY_SKIP=1` / equivalent flags
  are rejected. Enforced by `hooks/block-verify-bypass.sh`.
- **SI-4**: The protected branch (default `main`) MUST
  NOT receive direct pushes unless an active SPEC at
  status `approved` / `in-execution` / `verified` /
  `closed` declares `branch_policy: main-direct`.
  Enforced by `hooks/block-push-to-main.sh`.
- **SI-5**: Edits on the protected branch MUST honour
  the same `branch_policy: main-direct` rule. Enforced
  by `hooks/block-edit-on-main.sh`.

## Lifecycle-enforced (owner-only authority)

- **SI-6**: Status transitions `approved`,
  `decomposed`, `closed` MUST be set only by the owner.
  No skill, agent, or automation may flip these.
  Enforced procedurally by skill rules and reviewable
  in commit messages.
- **SI-7**: Spec authoring artefacts MUST NOT contain
  uncited factual claims. Enforced by
  `scripts/lint-spec.sh`.
- **SI-8**: Contract SPECs MUST pass `lint-spec.sh`
  exit 0. Enforced by the §10.3 Contract gate +
  CI's `lint-spec` job.

## Discipline-upheld (no mechanical enforcement)

- **SI-9**: Cross-family review SHOULD be performed
  for every Contract SPEC's approved-pending-owner →
  approved transition. Same-family proxy is
  acceptable with explicit caveat recorded; external
  cross-family pass is the rigorous default.
- **SI-10**: Open Questions MUST be either resolved
  or marked `owner-blocking` before
  `approved-pending-owner` is reached. Reviewer
  enforces.
- **SI-11**: Workpads (AGENT_FEEDBACK.md,
  SESSION_JOURNAL.md, AGENT_INBOX.md) MUST NOT carry
  secrets or third-party private data. Adopter
  responsibility.
- **SI-12**: Public OSS repos MUST gitignore any
  agent-control surface that contains studio-specific
  context. Adopter responsibility; the framework
  provides the gitignore patterns at
  `../../scripts/fleet-oss-gitignore.example.txt`.

## Violation handling

Tooling-enforced violations (SI-1 through SI-5, SI-7,
SI-8) result in non-zero exit codes and visible block
messages. The agent or user MUST address the violation
before proceeding.

Lifecycle-enforced violations (SI-6) are caught at
review time; an unauthorised status flip is reverted
and the agent / skill that performed it is corrected.

Discipline-upheld violations (SI-9 through SI-12) are
caught at review or by adopter audit; remediation is
context-specific.

## See also

- `../../OPERATING_MODEL.md` for the lifecycle and the
  owner-only authority binding.
- `../customization/contract.md` for which invariants
  the adopter MAY relax (K-2 hook activation set) vs
  which are immutable.
- `failures.md` for the failure-class × recovery
  matrix that accompanies these invariants.
