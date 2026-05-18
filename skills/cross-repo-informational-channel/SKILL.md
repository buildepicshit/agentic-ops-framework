---
name: cross-repo-informational-channel
description: "Use to send a structured handoff / fleet-update / directive-notice / request / ack message to another fleet repo's inbox file. Also use on session start to read incoming messages in your own repo's inbox. Counterpart to AGENT_FEEDBACK.md (outbound-to-fleet); sibling to cross-repo-policy-enforcement (the enforced channel). Messages are informational; for compliance-required changes use cross-repo-policy-enforcement instead."
---

# Cross-Repo Informational Channel

Use this skill for cross-repo handoffs that DO NOT require
compliance. When a fleet rule changes in the source policy
repo and N child repos need to KNOW about it (but don't need
to be machine-audited for compliance), the informational
channel is the right shape.

The pattern: every repo in the fleet has an `AGENT_INBOX.md`
(or equivalent) at its root. Other repos write structured
entries into this file via a small helper script; the local
agent reads the last N entries on session start as part of
orientation.

## When to use

- Source policy repo wants to notify children of a soft
  change (a new template available, a new pattern adopted,
  a deprecation timeline).
- A child repo wants to hand off in-flight work to another
  child repo (the work belongs to that repo; this repo's
  agent finished its slice).
- A child repo wants to ack receipt of a prior message
  (closes the request-ack loop).
- A child repo wants to broadcast a status update relevant
  to other agents working in the fleet (e.g., "production
  freeze begins YYYY-MM-DD").

Do not use this skill for:

- Compliance-required directives. Those go on
  `cross-repo-policy-enforcement` with audit-script
  verification.
- Owner-private content. Inboxes are committed; what lands
  there reaches GitHub at internal repos and the working tree
  at OSS-posture repos.
- Same-repo communication. The `SESSION_JOURNAL.md` and
  `AGENT_FEEDBACK.md` workpads serve same-repo continuity
  and friction surfaces respectively.

## Inbox shape

Every fleet repo has an `AGENT_INBOX.md` at root. The file is
append-only with newest entries at the top. Each entry uses
the form:

```markdown
## YYYY-MM-DD HH:MM — <from-repo>/<agent-id> (<model>) — <type>

**Summary:** <one-line>

**Authority:** <source-repo@<sha> | file://... | decision-authority://role:date>

**What changed / what to pick up:**
<one to three short paragraphs. Cite files / commits. Be specific.>

**Action required:**
- [ ] [If actionable, list concrete steps; else "informational — no action".]

**Expects ack:** true | false

**Relates to:** <other inbox entry id, directive id, or feedback entry>
```

### Message types

| Type | When |
|---|---|
| `fleet-update` | A fleet rule, skill, workflow, hook, or template changed and target repo's agents should know about it. Informational. |
| `directive-notice` | A fleet directive (per `cross-repo-policy-enforcement`) has been issued targeting this repo; compliance check will run on next audit. Cross-references the directive id. |
| `handoff` | The sender finished a task and is handing continuation to whoever picks up next in the target repo. |
| `request` | The sender asks the target repo's agents to do something specific (read a SPEC, run a verification, file a feedback entry, etc.). |
| `ack` | A reply to a prior `request` confirming completion or status. |

## Procedure

### Reading (every agent, every session start)

Read the last 5 inbox entries as part of orientation (per
`skills/repo-orientation/SKILL.md`). Each entry tells you
something that changed externally or hands off work
continuation. Acknowledge any `expects_ack: true` entries by
appending an ack entry beneath the original.

### Writing (to another repo's inbox)

Never write to your own repo's inbox — it's an incoming
channel. Write to ANOTHER repo's inbox via a helper script:

```bash
bash agents/scripts/send-fleet-message.sh <target-repo> <type> "<one-line summary>" [< body.md]
```

The helper:
- Appends a structured entry to `<target-repo>/AGENT_INBOX.md`
- Commits with a structured message (`fleet(inbox): ...`)
- Pushes if a remote is configured

If the target repo's inbox is gitignored (OSS posture), the
entry lays in the working tree but does not reach GitHub. The
target repo's next-session agent still sees it locally.

## Hard rules

- Inbox entries are immutable once written. Acknowledgements
  append below the original entry; do not edit the original.
- Owner alone archives entries older than 90 days to
  `AGENT_INBOX.archive.md`.
- Truncate the file to the most recent 50 entries on
  archival pass; do not let it grow unboundedly.
- Entries citing facts MUST use the framework citation
  grammar (`schema/SPEC.schema.md` §2).
- Do NOT include secrets, credentials, or third-party private
  data. Inboxes are git-tracked or working-tree visible to
  any agent landing locally.
- Do NOT write to your own repo's inbox. Use
  `AGENT_FEEDBACK.md` for outgoing-to-fleet content or another
  repo's `AGENT_INBOX.md` for outgoing-to-peer-repo content.
- The source policy repo MAY use inbox messages alongside
  fleet directives. Messages are informational; directives
  are enforced. A `directive-notice` message is a courtesy
  notification that the formal directive exists.

## Counterpart

The enforced sibling pattern is
`cross-repo-policy-enforcement` (formal directives with
audit-script verification). Most cross-repo communication
goes on the informational channel; the enforcement channel
is reserved for changes that MUST be applied uniformly.

## Tooling notes

The `send-fleet-message.sh` helper is studio-implementation
detail; the contract is the inbox-entry shape + the read-on-
session-start convention. A single-repo studio doesn't need
this channel at all.
