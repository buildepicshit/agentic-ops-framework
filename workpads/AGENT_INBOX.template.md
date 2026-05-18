# AGENT_INBOX.md — [Repo Name]

Incoming message channel for this repo. **Read on session start;
write only to OTHER repos' inboxes** (via the
`send-fleet-message.sh` helper or `/send-message` slash-command).

Counterpart to `AGENT_FEEDBACK.md` (outgoing — agents in this repo
write here for fleet triage). Sibling to fleet-directives (which
require enforcement; messages here are informational handoffs).

**Purpose:** when your-policy-repo or another fleet agent has
context the next-session agent in this repo needs — a fleet-rule
change, a cross-repo handoff, a "pick up from here" note — that
context lives in a durable per-repo inbox rather than vanishing
into chat.

**Authority:**
`file://skills/cross-repo-informational-channel/SKILL.md`;
`file://skills/cross-repo-informational-channel/SKILL.md`.

## How to use

**On session start (every agent in this repo):** read the last 5
inbox entries as part of Step 0 orientation (see
`file://agents/skills/repo-orientation/SKILL.md` Step 3). Each
entry tells you something that changed externally or hands off
work continuation.

**On message ack:** if a message is `expects_ack: true`, append an
acknowledgement entry to the bottom of the original message
block:
```
- 2026-MM-DD HH:MM — <agent-id>: read + ack
```

**On message dispatch:** never write to your own inbox. Write to
ANOTHER repo's inbox via:
```bash
bash .agents/scripts/send-fleet-message.sh <target-repo> <type> "<one-line summary>"
```
or `/send-message` slash-command. Both append a structured entry
to the target's `AGENT_INBOX.md` and commit there.

## Entry template

Each inbox message is appended to the `## Inbox` section using
the format below. Newest at top.

```markdown
## YYYY-MM-DD HH:MM — <from-repo>/<agent-id> (<model>) — <type>

**Summary:** <one-line>

**Authority:** <your-policy-repo@<sha> | file://specs/<id>/SPEC.md | owner://transcript-<date>>

**What changed / what to pick up:**
<one to three short paragraphs. Cite files / commits. Be specific.>

**Action required:**
- [ ] [If actionable, list concrete steps; else "informational — no
      action".]

**Expects ack:** true | false

**Relates to:**
- <other inbox entry id, fleet directive, SPEC, or feedback entry>
```

### Message types

| Type | When |
|---|---|
| `fleet-update` | your-policy-repo changed a rule, skill, workflow, hook, or template that this repo's agents should know about. Informational. |
| `directive-notice` | A fleet directive has been issued targeting this repo; compliance check will run on next audit. Cross-references the directive in `your-policy-repo/agents/fleet-directives/`. |
| `handoff` | The sender finished a task and is handing continuation to whoever picks up next in this repo. |
| `request` | The sender asks this repo's agents to do something specific (read a SPEC, run a verification, file a feedback entry, etc.). |
| `ack` | A reply to a prior `request` confirming completion or status. |

## Hard rules

- Inbox entries are immutable once written. Acknowledgements append
  below the original entry.
- Owner alone may archive entries older than 90 days to
  `AGENT_INBOX.archive.md`.
- Truncate this file to the most recent 50 entries on archival;
  do not let it grow unboundedly.
- Entries citing facts MUST use the citation grammar
  (`file://agents/specs/SPEC.schema.md` §2).
- Do NOT include secrets, credentials, or third-party private
  data. Inboxes are git-tracked or working-tree visible to any
  agent landing locally.
- Do NOT write to your own repo's inbox (it's an incoming
  channel). Use AGENT_FEEDBACK.md for outgoing-to-fleet content
  or another repo's AGENT_INBOX.md for outgoing-to-peer-repo
  content.
- your-policy-repo MAY use inbox messages alongside fleet
  directives. Messages are informational; directives are
  enforced. A directive-notice message is a courtesy notification
  that the formal directive exists.

## Inbox

<!-- Newest entries at the top. Use the entry template above. -->
