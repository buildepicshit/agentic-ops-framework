---
name: cross-repo-policy-enforcement
description: "Use to author + apply structured policy directives that propagate from one source-of-truth policy repo to N child repos in a fleet. Each directive carries a verbatim compliance check; the audit script scans each target repo and reports pass / fail. Counterpart to cross-repo-informational-channel (the informational sibling). Authoring this skill ONLY from the source policy repo; child repos receive and comply, they do not issue."
---

# Cross-Repo Policy Enforcement

Use this skill when a fleet rule changes in your source-of-truth
policy repo and the change MUST be applied + verified across the
N child repos that consume the policy. The pattern is the
enforced sibling to the informational `agent-inbox` / `cross-repo-
informational-channel` pattern: informational channels notify;
enforcement channels require compliance.

## When to use

- A fleet rule changes that requires every child repo to
  conform — e.g., a new hook ships, a schema field gains a
  required value, a deprecated path must be removed.
- The change is verifiable by a deterministic shell check
  (`grep`, `test -f`, file-presence, etc.). If the check
  requires human judgment, this skill is the wrong shape —
  use a SPEC + per-repo Task instead.
- The change applies to ≥2 child repos. Single-repo work
  belongs in the target repo's own SPEC pipeline.

Do not use this skill for:

- Informational handoffs ("hey, this changed, FYI"). Use
  `cross-repo-informational-channel` instead.
- Owner-judgment-required changes. Those need spec ceremony.
- Test data, fixtures, or generated content. The directive
  format is for policy, not content.

## Directive shape

Each directive lives at the source policy repo, typically
under `agents/fleet-directives/<YYYY-MM-DD>-<slug>.md`:

```markdown
---
id: <YYYY-MM-DD>-<slug>
status: pending | applied | verified | reverted
issued_by: <agent-id or owner-id>
issued_on: <YYYY-MM-DD>
targets: [all | all-internal | all-oss | <repo>,<repo>]
authority: <decision-authority://role:date or judgment://owner>
---

# Directive: <one-line title>

## 1. What changed

<one paragraph stating the new fleet rule>

## 2. Why

<one paragraph stating the rationale; cite the source
authority>

## 3. Compliance check

```bash
# Shell check that exits 0 iff the target repo conforms.
# Hermetic; runs from each target repo's root.
test -f .agents/templates/AGENT_INBOX.template.md && \
    grep -q "decision-authority://" .agents/specs/SPEC.schema.md
```

## 4. Remediation

<one paragraph stating what each non-compliant target repo
should do to come into compliance>
```

The compliance check section's shell block IS the audit
script's input. The script `audit-fleet-compliance.sh` reads
all directives at the source repo and runs each directive's
compliance block against each named target.

## Procedure

1. **Author the directive** at the source policy repo under
   `agents/fleet-directives/`. The id matches the file name
   slug.
2. **Author the compliance check** as a single shell block in
   §3. The block MUST exit 0 iff the target repo conforms.
3. **Set initial status: pending**.
4. **Run the audit script**:

   ```bash
   bash agents/scripts/audit-fleet-compliance.sh
   ```

   It walks every directive at `pending` or `applied`, runs
   each compliance check against each target repo, and reports
   pass/fail per (directive × repo) pair.

5. **For non-compliant targets**, apply the remediation from
   §4. This is the manual step — the directive does not
   auto-apply changes to target repos.
6. **Flip directive status: applied** once the change has
   been propagated to the targets. The directive remains in
   the audit loop.
7. **Owner alone flips status: verified** after manual review
   confirms the audit has been clean for a stabilization
   window (default 7 days).
8. **Archive verified directives** older than 90 days to
   `agents/fleet-directives/archive/`.

## Audit script

The `audit-fleet-compliance.sh` script:

- Reads every `*.md` in `agents/fleet-directives/` with
  `status: pending` or `status: applied`.
- For each, reads the `targets:` front-matter field and
  resolves it to a concrete repo list via the
  `fleet-internal-repos.txt` / `fleet-oss-repos.txt` /
  `fleet-local-only-repos.txt` manifests (per `all`,
  `all-internal`, `all-oss`, or explicit list).
- For each (directive × target) pair, executes the
  directive's §3 compliance shell block from the target
  repo's root.
- Reports `PASS` or `FAIL` per pair with directive id +
  target repo name.

Exit code: 0 iff every (directive × target) pair passes.

## Safety invariants

- Directives MUST be authored only at the source policy
  repo. Child repos that receive a directive MUST NOT
  author their own.
- The compliance check shell block MUST be hermetic. No
  network calls, no time-dependent comparisons, no
  side-effects (no writes).
- The compliance check MUST exit non-zero on failure with a
  diagnostic message on stderr so the audit can report what
  failed.
- Directives MUST be append-only once status: applied. New
  policy supersedes old policy via a new directive that
  cites the old one's id in its §2 Why.

## Hard rules

- Do not edit a directive's compliance check after status:
  applied. If the check was wrong, author a follow-on
  directive.
- Do not flip status: verified from a skill. Owner-only.
- Do not run the audit script as part of a target repo's
  CI — the directive is the source repo's authority; child
  repos comply with whatever directives are live, not with a
  versioned snapshot.
- Do not use this skill for informational notices. Those
  belong on `cross-repo-informational-channel`.

## Counterpart

The informational sibling pattern is
`cross-repo-informational-channel` (an inbox at each child
repo's root receiving structured handoffs). Both channels can
operate side-by-side: a directive may also be announced via
the informational channel as a courtesy, but the audit script
operates only against the directive corpus.
