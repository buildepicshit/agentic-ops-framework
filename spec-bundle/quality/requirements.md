# Quality — Requirements

Per arc42 §10 Quality
(`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/arc42.md` §3) and
the top quality goals named in
`../architecture/solution-strategy.md`.

## Quality scenarios

### Q-1: Citation precision

**Quality attribute**: completeness + traceability.

**Scenario**: a reviewer skims any artefact in the
framework or any adopter's artefact authored under the
framework's discipline.

**Stimulus**: the reviewer asks "where does this claim
come from?"

**Response**: every factual claim resolves to a citation
prefix (`file://`, `cmd://`, `url://`, `owner://`,
`decision-authority://<role>:<date>`, `judgment://owner`,
or `judgment://agent-synthesis`).

**Response measure**: `scripts/lint-spec.sh` exits 0 on
the artefact; manual reviewer can follow every citation
to its source.

### Q-2: Mechanical verifiability

**Quality attribute**: reproducibility + automation.

**Scenario**: CI runs on a push.

**Stimulus**: a contributor opens a PR with new spec
content + skill changes + hook changes.

**Response**: four CI jobs run automatically (lint-spec,
validate-skill-frontmatter, test-hooks, validate-manifest)
and each reports pass/fail without human judgment.

**Response measure**: CI exit codes; no manual review
needed for mechanical conformance.

### Q-3: Hermetic test surface

**Quality attribute**: reliability + isolation.

**Scenario**: hook tests run in CI on a fresh
clone.

**Stimulus**: `bash tests/hooks/run-tests.sh`.

**Response**: every hook test creates an ephemeral git
sandbox; tests do not depend on the host repo's
branch state, working tree, or HEAD.

**Response measure**: 33 pass / 0 fail consistently
across local dev machine, CI runner, and forked
contributor environments.

### Q-4: Honest disclosure

**Quality attribute**: transparency + integrity.

**Scenario**: a reader consumes any framework artefact.

**Stimulus**: they want to know what the framework
does NOT cover, what failed, and what's unresolved.

**Response**: every artefact's `non-goals/`,
`Completion Report.residual_risk`, and `Open Questions`
sections explicitly enumerate gaps + failures + open
questions.

**Response measure**: reviewer can recover the
framework's intended scope from artefacts alone, without
needing access to authoring chat history.

### Q-5: Cross-family review robustness

**Quality attribute**: defect detection + decision
quality.

**Scenario**: a Contract SPEC is authored by a
Claude-family agent.

**Stimulus**: the SPEC enters spec-review.

**Response**: a different-family reviewer (Codex /
Gemini / etc.) runs the §10.3 Contract gate; same-
family proxy is acceptable with explicit caveat
recorded.

**Response measure**: same-family-proxy advisories are
visible in the Quality Gate Result; external review
runs at owner discretion.

### Q-6: No regressions on lifecycle gates

**Quality attribute**: stability + backward compatibility.

**Scenario**: a framework change lands (new skill,
schema change, hook change).

**Stimulus**: CI runs on the change.

**Response**: existing examples + hook tests + lint
on the inaugural SPEC continue to pass.

**Response measure**: zero example-lint regressions; 33
hook tests still pass.

## See also

- `12-factor-overlay.md` for the operating-system-
  boundary contract per
  `url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/12-factor.md` §3.
- `../operations/safety-invariants.md` for the MUST-
  numbered safety list.
