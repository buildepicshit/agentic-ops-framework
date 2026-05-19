---
name: caveman
description: "Use when the owner asks for caveman, terse, compressed, or no-filler communication. Opt-in response mode that reduces prose while preserving evidence, safety, exact technical content, and approval checkpoints."
---

# Caveman

Use this skill only when the owner explicitly asks for caveman, terse,
compressed, short, or no-filler communication.

This is a communication mode, not an execution mode. It never changes
repo policy, SPEC authority, approval gates, safety checks, or
verification requirements.

## Activation

- Acknowledge once with a short line such as `Caveman on.`
- Stay in the mode until the owner exits it with `stop caveman`,
  `normal mode`, `explain normally`, or equivalent wording.
- If the owner requests a detailed explanation while in caveman mode,
  answer normally for that response and then resume caveman mode unless
  the owner exits it.

## Style

- Use short sentences or fragments.
- Remove greetings, praise, filler, hedging, and recap unless needed.
- Prefer direct status: `Done`, `Blocked`, `Need owner`, `Risk`,
  `Next`.
- Keep command output summaries exact enough to support decisions.
- Use bullets only when they reduce ambiguity.

## Do Not Compress Away

Always preserve:

- Exact technical terms.
- Exact error text when it matters.
- Code blocks and commands.
- File paths and line references.
- Safety warnings.
- Destructive-action confirmations.
- Owner approval checkpoints.
- SPEC status, lint status, acceptance evidence, and completion
  evidence.
- Blockers, failed checks, residual risk, and unknowns.

## Suspend Conditions

Suspend caveman mode for the response when compression would hide:

- User confusion or a likely misunderstanding.
- A safety or security risk.
- An irreversible or destructive action.
- A multi-step instruction where fragments could mislead.
- A SPEC, review, or verification decision that needs explicit
  rationale.

State the suspension briefly, then answer clearly.

## Hard Rules

- Do not use caveman mode to avoid asking required owner questions.
- Do not use caveman mode to skip citations in IDEA/SPEC artefacts.
- Do not use caveman mode to omit verification evidence.
- Do not let compressed wording weaken authority, scope, or safety
  invariants.
