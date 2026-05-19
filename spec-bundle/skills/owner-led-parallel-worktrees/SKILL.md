---
name: owner-led-parallel-worktrees
description: "Use to spin up an isolated parallel worktree for a TASK.md slice or a cross-family review of an in-flight PR, then bind the framework's lifecycle gates (lint-spec, acceptance_commands, spec-evidence) to the worktree's lifecycle. Pattern is git-worktree-native; pluggable wrapper (e.g., the `wt` CLI from worktrunk.dev) is RECOMMENDED but not required. Owner-led parallel mode only — autonomous dispatch uses per-issue workspaces from its own runner."
---

# Owner-Led Parallel Worktrees

Use this skill to manage parallel agent work that must not
share state with the current workspace. The framework requires
parallel writers to be isolated by branch + worktree boundary
(see `OPERATING_MODEL.md` §"Workspace policy" and §"Parallel
execution policy"). Native `git worktree` is sufficient;
wrapper CLIs that bind framework hooks to the worktree
lifecycle are RECOMMENDED.

## When to use

- An approved SPEC has decomposed into ≥2 TASK.md slices and
  you want to execute them in parallel by separate agents.
- You want a clean isolated environment to review an in-flight
  PR with a different-family agent without contaminating your
  current workspace.
- You're running an owner-led exploration (debugging, ad-hoc
  investigation, performance triage) that wants to share the
  repo's build artefacts but live on a separate branch.
- A long-running build / index needs to stay warm in one
  worktree while a different branch is being edited in
  another.

Do not use this skill for:

- Autonomous tracker-issue dispatch — that uses per-issue
  workspaces from the dispatch runner, not owner-led
  worktrees.
- Sequential single-track work — the overhead of worktree
  setup is wasted when only one agent is editing.
- Owner-interactive planning conversations — those stay
  single-track.

## Pattern

The worktree is a separate physical directory pointing at a
separate branch of the same repository. Files in one worktree
do not collide with files in another. Each worktree gets its
own build cache, test process pool, and language-server
session; the underlying `.git/` directory is shared.

```
parent-repo/                       # main worktree, branch: main
  .git/                            # the shared git store
  src/
  ...

../parent-repo.task-01/            # second worktree, branch: feat/task-01
  src/                             # same code, different working dir
  ...

../parent-repo.review-pr-42/       # third worktree, branch: PR-42-source-branch
  src/
  ...
```

## Lifecycle gates

The framework's lifecycle gates SHOULD fire at the worktree
boundary. Three hook points are RECOMMENDED:

- **pre-start** — before an agent enters the worktree:
  workspace preflight + skill-frontmatter validation +
  parent-SPEC presence check.
- **pre-commit** — before each commit in the worktree:
  `lint-spec.sh` on any changed SPEC or IDEA artefact.
- **pre-remove** — before deleting the worktree: confirm the
  parent SPEC is at `verified` or later AND the branch is
  merged OR the TASK.md is at `done`. Prevents accidental
  loss of in-flight work.

If you use a wrapper CLI (e.g., `wt` from worktrunk.dev),
register the framework's scripts at these hooks via the
wrapper's project config. With raw `git worktree`, register
them as repo-local `.githooks/` scripts.

## Procedure

1. **Pick the parent**. A TASK.md slice from an approved
   parent SPEC, OR a PR branch you want to review.
2. **Create the worktree**:

   ```bash
   git worktree add ../<repo>.<task-id> -b <branch>
   ```

   or via wrapper:

   ```bash
   wt switch -c <task-id> -x "claude"
   ```

3. **Inside the worktree, run preflight**: framework's
   `preflight.mjs` or equivalent. Verifies the workspace is
   sane, hooks are installed, lint passes on the parent
   SPEC.
4. **Run the agent**. Implementer in the worktree; the
   cross-validation lane in a sibling worktree on a different
   model family.
5. **Pre-commit gates fire on each commit**: lint-spec runs
   on any modified IDEA/SPEC; acceptance_commands run on
   completed TASK.md.
6. **When the slice is verified**, mark TASK.md `done`. Open
   PR or merge per your branch policy.
7. **Cleanup**: pre-remove gate validates state, then:

   ```bash
   git worktree remove ../<repo>.<task-id>
   ```

   or via wrapper:

   ```bash
   wt remove <task-id>
   ```

## Cross-family review with worktrees

The framework's cross-family review is naturally a worktree
operation. The reviewer's agent runs in a separate worktree
checked out to the PR branch (read-only by convention; the
reviewer emits findings, not edits). Findings flow back to
the implementer via PR comments or the workpad. The
reviewer's worktree is removed after the review is recorded.

## Safety invariants

- A worktree MUST be on a different branch from the main
  worktree. Two worktrees on the same branch is an error.
- Untracked files in a worktree are local to that directory;
  do not assume cleanup propagates.
- Long-running builds in a worktree MUST be cleaned up before
  `pre-remove` succeeds; orphan node_modules / target /
  build directories are a common worktree-leak failure.
- Worktrees on detached HEADs are permitted for read-only
  review work; for write work, always check out a real
  branch.

## Hard rules

- Do not run multiple write-capable agents in the same
  worktree.
- Do not delete a worktree without confirming the branch is
  merged or the TASK.md is at `done`.
- Do not mutate the parent SPEC.md from a worktree's TASK.md
  execution. The parent SPEC is immutable except for its
  Completion Report (which is filled at verification, by the
  parent's owner not the slice executor).
- Do not assume worktree-local hooks or env vars propagate
  from the main worktree. Each worktree configures its own.

## Tooling notes

- **Native `git worktree`** is sufficient and zero-install.
- **`wt` CLI** (worktrunk.dev) wraps `git worktree` with
  hook surface, build-cache sharing, and LLM commit-message
  generation. RECOMMENDED for studios running ≥3 parallel
  agents regularly.
- Other wrappers exist (e.g., `git-pile`, custom scripts).
  The framework doesn't endorse one; the contract is the
  pattern + the hook surface.
