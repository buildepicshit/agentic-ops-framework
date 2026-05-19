# Deployment — Requirements

Per 12-factor's Factor II "Dependencies" framing
(`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/12-factor.md` §3):
declare and isolate dependencies explicitly.

## Runtime dependencies

The framework itself is not a runtime service. The scripts
it ships have these dependencies:

| Tool | Min version | Used by |
|---|---|---|
| `bash` | 4.0+ | All scripts (lint, hooks, hook tests, validate-manifest) |
| `grep`, `sed`, `awk`, `find` | POSIX | All scripts |
| `git` | 2.25+ | Hooks (block-edit-on-main detects branch; block-git-add-all etc.) |
| `node` | 18+ | Only `scripts/preflight.mjs` |
| `gh` (GitHub CLI) | 2.0+ | Release workflows (optional) |
| `jq` | 1.6+ | Hook test harness (parses session-start-context JSON) |

## Tooling dependencies for adopters

The framework assumes the adopter uses one or more of:

- A git host (GitHub, GitLab, Bitbucket, self-hosted).
- An AI coding assistant that reads `AGENTS.md` or
  `CLAUDE.md` (per `url://agents.md` and
  `url://code.claude.com/docs/en/memory`).
- Optionally: an issue tracker and an
  autonomous-issue-dispatch runner for the Symphony-style
  patterns
  (`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/symphony-spec.md` §3).

## What the framework does NOT require

- No specific programming language for the adopter's
  product.
- No specific cloud or hosting provider.
- No paid SaaS dependency.
- No vendor lock-in to one AI assistant; the framework
  is AGENTS-aware-tool-agnostic.

## Reproducibility posture

The framework itself is reproducible-by-construction: a
fresh clone at a given tag is byte-identical to any other
clone at that tag. The framework does NOT yet adopt
Nix-style content-hash reproducibility for adopter
products (`url://github.com/buildepicshit/agentic-installation-methodology/blob/main/research/primary-sources/nix-flakes.md`
§3); that's an open methodology question per the
`non-goals/INDEX.md` entry on reproducibility-of-product.
