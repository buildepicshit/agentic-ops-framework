---
name: repo-orientation
description: Use at the start of work in any repo to build a current, cited map of instructions, repo state, verification gates, active plans, and likely risk before editing.
---

# Repo Orientation

Use this before planning or editing.

## Steps

1. Read the nearest `AGENTS.md`.
2. If present, read `CLAUDE.md`, `STATUS.md`,
   `.agents/DOCUMENTATION_GUIDE.md`, and the docs linked by `AGENTS.md`.
   `WORKFLOW.md` is the per-repo engagement contract; it has three
   sections: **Section 1 — Universal** (applies to every agent in
   this repo regardless of dispatch surface), **Section 2 —
   the autonomous-dispatch runner dispatch mode** (only when `{{ issue.* }}` is
   populated by the autonomous-dispatch runner runner), and **Section 3 — Owner-led
   parallel mode** (when running under `wt`). Interactive
   sessions read Section 1 only; do NOT install the tracker or
   the autonomous-dispatch runner.
3. Read `SESSION_JOURNAL.md` at the repo root (last 3 entries).
   It tells you what the previous agent did, what was left dirty,
   and what to pick up. If absent, copy from
   `.workpads/SESSION_JOURNAL.template.md`.
4. Read `AGENT_FEEDBACK.md` for open friction entries relevant
   to your work. If absent, copy from
   `.workpads/AGENT_FEEDBACK.template.md`.
5. Read `AGENT_INBOX.md` — the top 5 entries (newest first).
   Acknowledge any `Expects ack: true` entries with an ack line
   below the original. If absent, copy from
   `.workpads/AGENT_INBOX.template.md`. See
   `.skills/agent-inbox/SKILL.md`.
6. Before dispatch, delegation, model-specific work, or
   multi-agent review, read `your model-routing policy` or the
   propagated `.your model-routing policy`.
7. Check git state with `git status --short --branch`.
8. Identify the active branch, tracking branch, untracked files,
   and unrelated local changes.
9. Identify the repo's verification gate and any hook setup
   requirements.
10. Locate the task's likely files with `rg` and `rg --files`.
11. Report only verified facts. Cite files or command output.

## Output

- Target repo and branch.
- Source-of-truth docs read.
- Model-routing source read when delegation or model selection is in scope.
- Relevant files or directories.
- Verification commands.
- Documentation placement constraints for this task.
- Local changes that must be preserved.
- Open questions before implementation.

## Hard Rules

- Do not edit during orientation.
- Do not rely on memory when repo docs can answer the question.
- If instructions conflict, stop and report the conflict.
