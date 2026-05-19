# Deployment — Install

How an adopter installs the framework into their own studio
/ team / fleet. The framework does not require a runtime
service; "install" here means: lay the framework's
artefacts into the adopter's repository tree (or fleet of
repositories) and adopt the lifecycle.

## Install modes

### Single-repo adoption

The simplest case. An adopter copies the relevant pieces
of the framework into their own repo:

```bash
# 1. Clone the framework.
git clone https://github.com/buildepicshit/agentic-ops-framework.git
cd agentic-ops-framework

# 2. From the target repo's root, copy the framework's
#    discipline artefacts.
TARGET=/path/to/your/repo
cp -r spec-bundle/schema     "$TARGET/"
cp -r spec-bundle/templates  "$TARGET/"
cp -r spec-bundle/skills     "$TARGET/.agents/skills/"
cp -r hooks                  "$TARGET/"
cp scripts/lint-spec.sh      "$TARGET/scripts/"
cp scripts/validate-skill-frontmatter.sh "$TARGET/scripts/"

# 3. Author the target repo's AGENTS.md / CLAUDE.md per
#    file://../skills/agents-md-improver/SKILL.md
#    conventions.
```

The exact paths under the target repo vary by adopter
convention; see the AGENTS.md guidance for the
recommended layout.

### Fleet adoption (multi-repo)

For studios operating a fleet of related repos, the
framework's `cross-repo-policy-enforcement` and
`cross-repo-informational-channel` skills
(`file://../skills/cross-repo-policy-enforcement/SKILL.md`,
`file://../skills/cross-repo-informational-channel/SKILL.md`)
describe the propagation pattern. A source policy repo
holds the canonical artefacts; child repos sync via a
`fleet-sync.sh`-style script driven by per-fleet manifests.

The example manifests at
`file://../../scripts/fleet-*.example.txt` show the shape.

### v0.1 scaffold-only adoption

For a new repo (no prior history), see the worked example
at the sibling
`url://github.com/buildepicshit/agentic-installation-methodology`
repo's `specs/2026-05-18-repo-standup/SPEC.md` — that
repo's v0.1 scaffold port is the canonical worked
example of fresh-repo adoption.

## Post-install verification

After installation, the adopter runs:

```bash
bash scripts/lint-spec.sh <path-to-your-first-IDEA-or-SPEC>
bash scripts/validate-skill-frontmatter.sh
bash tests/hooks/run-tests.sh
```

Each MUST exit 0 for the adoption to be considered
correctly seated.

## Customization knobs

What an adopter is expected to tailor:

- The set of skills they adopt (the full catalog of 20
  is opt-in by skill).
- The set of hooks they enable in their `.claude/`
  settings (the seven hooks are opt-in individually).
- The CI workflow's job set (the framework's
  `ci.yml` is a starting point, not a contract).
- The lint exit-2 (advisory) threshold (whether CI
  treats exit 2 as a failure or warning).

For the full deferral contract see `../customization/contract.md`.
