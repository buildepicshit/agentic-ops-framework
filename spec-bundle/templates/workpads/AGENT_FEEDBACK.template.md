# AGENT_FEEDBACK.md — [Repo Name]

Structured channel for agents to surface friction, confusion,
bugs, proposals, or fleet-policy misalignments. Replaces the
ad-hoc "agent complains verbally and owner relays to fleet" path.

**Authority:**
`file://spec-bundle/skills/agent-feedback/SKILL.md`;
`file://workflows/agent-feedback.md`.

## How to use

Any agent operating in this repo MAY append a feedback entry when
they hit:

- **friction**: the framework slowed them down in a way that
  feels disproportionate to safety value
- **confusion**: docs / skills / workflows / hooks pointed in
  contradictory directions, or instructions were ambiguous
- **bug**: a hook / lint / audit script gave a wrong answer
- **misalignment**: a fleet rule conflicts with another fleet
  rule, or a child-repo doc contradicts the canonical at
  `your-policy-repo/agents/`
- **proposal**: an idea worth considering for fleet rule change

Run via `/agent-feedback` slash-command, or append manually using
the template below.

**Triage:** the agent attached to `your-policy-repo` is responsible
for triaging this file across all fleet repos via the
`audit-fleet-compliance.sh` script (which surfaces unaddressed
feedback) and the `fleet-enforce` skill (which converts feedback
into directives).

## Entry template

```markdown
## YYYY-MM-DD HH:MM — <agent-id> (<model>) — <type>: <one-line summary>

### Context
[What were you trying to do? What did you read first?]

### What happened
[Concrete observation. Cite `file://` / `cmd://` / specific docs.]

### What I expected
[What the docs/skills led you to expect.]

### Why this matters
[Severity: blocker / friction / nit. Who else is affected.]

### Suggested fix (optional)
[If you have a concrete fix in mind; otherwise leave blank for
fleet triage to propose.]

### Status
- [ ] surfaced (initial)
- [ ] triaged by fleet (acknowledged, classification confirmed)
- [ ] in-progress (directive issued, fix in flight)
- [ ] resolved (cite the your-policy-repo commit / directive)
- [ ] won't-fix (owner judgment; cite directive or transcript)
```

## Hard rules

- Entries are immutable once written. Status updates are appended
  as new lines below the original entry, signed by the updater.
- Entries citing facts MUST use the citation grammar.
- Do NOT include secrets, credentials, or third-party private data.
- Owner alone may close an entry as `won't-fix`. Fleet agents move
  entries through `triaged` → `in-progress` → `resolved`.
- Entries older than 180 days move to `AGENT_FEEDBACK.archive.md`
  with the resolution citation preserved.

## Entries

<!-- Newest entries at the top. -->
