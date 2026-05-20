# SESSION_JOURNAL.md — [Repo Name]

Per-repo session continuity journal. Append-only. The universal
form of the an autonomous-dispatch runner workpad pattern: where an autonomous-dispatch runner writes one
`## Workpad` comment per tracker ticket, every other agent
context (Claude Code interactive, an agent runner CLI, owner-led `wt` worktree)
writes here.

**Purpose:** close the asymmetric-tightness gap — an autonomous-dispatch runner runs have
workpad continuity in tracker comments; interactive sessions had
nothing. This journal is read in Step 0 orientation by ALL agents
(dispatched or interactive) and appended on session end.

**Authority:**
`file://spec-bundle/operations/workflow-universal.md` "Section 1 — Universal";
`file://spec-bundle/skills/repo-orientation/SKILL.md` Step 2.

## How to use

**On session start (every agent):** read the last 3 entries. They
tell you what the previous agent did, what was left dirty, what the
next agent should pick up.

**On session end (every agent):** append a new entry using the
template below. Run via `/log-session` slash-command, or write
manually.

If the dirty-tree state changed during your session, you MUST log.
If your session was read-only (no edits), logging is OPTIONAL but
recommended.

## Entry template

```markdown
## YYYY-MM-DD HH:MM — <agent-id> (<model>)

### What I did
[One paragraph. Concrete outcomes; not "I tried to ...".]

### What I touched
- `path/to/file.ext` — [why; brief]
- `path/to/file2.ext` — [why]

### What I left dirty
- `path/to/wip.ext` — WIP, blocked on owner decision about X
- `path/to/safe.ext` — safe to discard if next agent doesn't continue

### Next agent should
[One sentence directive: continue X, discard Y, owner-blocking
question Z.]

### Notes
[Optional — surprises, confusions, decisions worth flagging.]
```

## Hard rules

- Append-only. Never edit prior entries (immutable record).
- Owner alone may archive entries older than 90 days to
  `SESSION_JOURNAL.archive.md`.
- Truncate this file to the most recent 30 entries on archival
  pass; do not let it grow unboundedly.
- Entries citing facts (lint output, commit hash, etc.) MUST use
  the citation grammar from `spec-bundle/schema/SPEC.schema.md` §2.
- Do NOT include secrets, credentials, or owner private content.
  This file may be read by any agent entering this repo.

## Entries

<!-- Newest entries at the top. -->
