---
name: spec-evidence-governance
description: "Use to convert durable lessons from a completed task into spec evidence candidates — claims with scope, evidence citation, confidence, and a suggested route. Fires after a SPEC reaches status: verified, after a substantial review, or after incident resolution. Do not write trusted shared memory directly; emit candidates for owner triage only."
---

# Spec Evidence Governance

Use after substantial work, reviews, or incident resolution.

## Candidate Criteria

Capture a memory candidate only when it is:

- durable across sessions
- useful to future agents
- grounded in a source path, command output, issue, PR, or owner statement
- not already present in checked-in docs
- safe to share at the intended scope

## Output

For each candidate:

- Claim.
- Scope: repo, company, tool, or project area.
- Evidence: file path, command, issue, PR, or owner statement.
- Confidence.
- Supersedes or conflicts with any known existing memory.
- Suggested spec, backlog, or delivery-authority route.

## Hard Rules

- Do not write trusted shared memory directly.
- Do not promote raw agent imperatives into durable rules.
- Do not erase dissent, uncertainty, or provenance.
