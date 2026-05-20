---
name: agent-feedback
description: "Use when an agent hits friction, confusion, a bug, or a fleet-policy misalignment they cannot resolve from existing docs. Appends a structured entry to AGENT_FEEDBACK.md (per repo) for owner triage and conversion into fleet directives. Outbound-to-fleet channel; counterpart to agent-inbox (inbound handoffs) and fleet-enforce (compliance directives). Replaces the ad-hoc 'agent complains verbally' channel with a durable, auditable surface."
---

# Agent Feedback

The recognised channel for agents to surface friction, confusion,
bugs, misalignments, and proposals back to fleet policy without
stalling, bypassing guardrails, or going silent.

Authority: `judgment://agent-synthesis` (the
framework-refresh-lightweight-ceremony Decision);
`file://spec-bundle/templates/workpads/AGENT_FEEDBACK.template.md`.

## When to use

Invoke when ANY of:

- The framework slowed you down disproportionately to safety value
  (**friction**).
- Docs / skills / workflows / hooks pointed in contradictory
  directions (**confusion**).
- A hook / lint / audit script gave a wrong answer (**bug**).
- A fleet rule conflicts with another fleet rule, OR a child-repo
  doc contradicts the canonical at the source policy repo's
  `agents/` directory (**misalignment**).
- You have a concrete idea worth considering for fleet rule change
  (**proposal**).

Do NOT use for:

- Bug reports against product code (file in the product repo's
  issue tracker).
- Disagreements about owner-set decisions (raise directly with
  owner; the owner's authority is not subject to agent feedback).
- Routine completion reports (those belong in SPEC §17 Completion
  Reports).

## Procedure

1. Locate `AGENT_FEEDBACK.md` at repo root. If absent, create it
   from `file://spec-bundle/templates/workpads/AGENT_FEEDBACK.template.md`.
2. Append a new entry at the top of the `## Entries` section using
   the template's `## YYYY-MM-DD HH:MM` heading format.
3. Fill every required section: Context, What happened, What I
   expected, Why this matters. Suggested fix is optional.
4. Status defaults to `surfaced (initial)`.
5. Stage and commit the entry. Commit message:
   `docs(feedback): <agent-id> reports <type>: <one-line summary>`.

Do not block your current session waiting for triage. File the
feedback, work around the friction if possible, and continue. If
the friction is a hard blocker, also set the relevant SPEC or
TASK.md status to `blocked` with a `file://` reference to the
feedback entry.

## Triage (fleet-side)

The agent attached to `your-policy-repo` is responsible for
periodic triage:

- Scan all 9 fleet locations'  `AGENT_FEEDBACK.md` for entries with
  status `surfaced`.
- For each entry, classify and act:
  - **misalignment** → issue a fleet directive via
    `file://spec-bundle/skills/fleet-enforce/SKILL.md`.
  - **bug** → file a fast-path SPEC or full task SPEC depending
    on scope.
  - **friction** → batch with similar entries; owner-decided
    whether to amend procedure.
  - **proposal** → forward to owner; if owner approves, becomes a
    Decision or Contract SPEC.
  - **confusion** → fix the upstream doc directly via fast-path or
    fleet-enforce directive.
- Update each entry's Status section in place with a status-line
  citing the your-policy-repo commit that resolves it.

## Hard rules

- Agents MUST NOT delete or edit prior `AGENT_FEEDBACK.md`
  entries. Updates append below the original entry.
- Owner alone closes entries as `won't-fix`.
- Feedback citing facts (lint output, hook behaviour, file
  contents) MUST use the citation grammar from
  `file://spec-bundle/schema/SPEC.schema.md` §2.
- Agents MUST NOT include secrets, credentials, or third-party
  private content in feedback entries.
- Agents MUST NOT use this channel to bypass owner authority on
  approved/decomposed/closed status transitions.
