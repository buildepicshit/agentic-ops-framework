# Contributing to agentic-ops-framework

The framework eats its own dog food: contributions go through
the same lifecycle the framework documents. Non-trivial changes
require an IDEA → SPEC pair before code lands.

## Trivial changes

Typo fixes, single-line doc clarifications, single-file
fixes ≤ 50 lines: use the Fastpath SPEC pattern (see
`examples/fastpath-fix-readme-typo/SPEC.md`). Author a single
SPEC at `specs/<YYYY-MM-DD>-<slug>/SPEC.md`, status: closed,
in the same PR as the fix.

## Non-trivial changes

For anything else (a new skill, a schema change, a new
hook, a non-trivial bug fix touching multiple files):

1. **Read `OPERATING_MODEL.md`** — the lifecycle and posture
   you're contributing into.
2. **Read `spec-bundle/schema/SPEC.schema.md`** — the citation grammar
   and front-matter rules (v2.0 layout; v1.x consumers
   see `schema/SPEC.schema.md`).
3. **Open an issue first** with a one-paragraph problem
   statement. The framework maintainer will signal whether
   it's worth pursuing before you invest in a full SPEC.
4. **Author an IDEA** at `specs/<YYYY-MM-DD>-<slug>/IDEA.md`
   using `spec-bundle/templates/IDEA.template.md` (v2.0
   layout). The IDEA covers
   problem, substance, constraints, approaches considered,
   recommendation, owner-blocking questions.
5. **Author a SPEC** at `specs/<YYYY-MM-DD>-<slug>/SPEC.md`
   using the appropriate type template (task / contract /
   decision). The IDEA must reach `status: ready-for-spec`
   first.
6. **Run lint locally** before opening the PR:

   ```bash
   bash scripts/lint-spec.sh specs/<your-spec>/IDEA.md
   bash scripts/lint-spec.sh specs/<your-spec>/SPEC.md
   bash scripts/validate-skill-frontmatter.sh
   bash tests/hooks/run-tests.sh
   ```

   All MUST exit 0.
7. **Open the PR**. CI runs the four jobs. Address review
   feedback or post explicit pushback. A different-family
   reviewer ideally signs off (the framework's cross-family
   review pattern applies to its own development).
8. **Merge happens on owner approval**. The owner flips the
   SPEC `approved-pending-owner → approved → verified` and
   merges.

## Citation discipline

Every factual claim in every artefact MUST carry a citation
prefix from the grammar (`file://`, `cmd://`, `url://`,
`decision-authority://<role>:<date>`, `judgment://owner`,
`judgment://agent-synthesis`). Memory and training data are
inputs to your reasoning, not citable evidence. The lint
script enforces this.

## Commit messages

Conventional Commits 1.0.0:

```
<type>(<optional scope>): <subject>
```

Allowed types: `feat`, `fix`, `build`, `chore`, `ci`, `docs`,
`style`, `refactor`, `perf`, `test`, `spec`. Breaking changes
mark with `!` after the type or a `BREAKING CHANGE:` footer.

## No AI attribution

Per the `block-ai-attribution.sh` hook: do NOT include
`Co-Authored-By: Claude` / `Co-Authored-By: GPT-...` or
similar trailers. The hook will reject the commit. The
framework's posture: AI tools are inputs to your thinking,
not credited authors of the contribution.

## Testing

The framework ships its own test harness at
`tests/hooks/run-tests.sh`. If you add a hook, add tests for
its block path, allow path, and at least one false-positive
guard. The harness is hermetic — use the existing sandbox-
fixture pattern; don't depend on the framework repo's own
state.

## Posture

The framework is offered as honest experience, not as
prescription. Contributions should match that posture: name
what you tried, name what you found, name what didn't work.
Don't pretend certainty you don't have. The citation grammar
gives you a way to disclose where each claim comes from —
use it.

## Licence

By contributing, you agree your work is licensed under
Apache-2.0 (see LICENSE).
