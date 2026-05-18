#!/usr/bin/env bash
# audit-entry-docs.sh — audit AGENTS.md / CLAUDE.md / GEMINI.md /
# WORKFLOW.md against the canonical fleet pattern declared in
# agents/OPERATING_MODEL.md §"Source Of Truth" and §"Public OSS posture".
#
# Run from the studio root to audit all 7 repos, or from any repo
# root to audit that one repo.
#
# Exit codes:
#   0 — all checks pass
#   1 — at least one blocking criterion failed
#
# Authority:
#   your-policy-repo entry-doc audit policy
#   file://agents/skills/agents-md-improver/SKILL.md (policy doc)

set -uo pipefail

# Repo posture classification — manifest-driven.
# Edit fleet-internal-repos.txt + fleet-oss-repos.txt to change topology.
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

read_manifest() {
    local file="$1"
    local -n out_array="$2"
    out_array=()
    [ -f "$file" ] || return 0
    while IFS= read -r line; do
        case "$line" in ''|'#'*) continue ;; esac
        out_array+=("$line")
    done < "$file"
}

read_manifest "$SCRIPT_DIR/fleet-internal-repos.txt" INTERNAL_REPOS
read_manifest "$SCRIPT_DIR/fleet-oss-repos.txt" PUBLIC_OSS_REPOS

fail=0
total_failures=0

# Detect run mode: studio root (sees all internal + OSS repos) or single
# repo. Studio root has at least the first two internal-manifest repos
# AND the first OSS-manifest repo as subdirectories.
detect_root() {
    if [ "${#INTERNAL_REPOS[@]}" -ge 2 ] && [ "${#PUBLIC_OSS_REPOS[@]}" -ge 1 ] \
        && [ -d "$PWD/${INTERNAL_REPOS[0]}" ] \
        && [ -d "$PWD/${INTERNAL_REPOS[1]}" ] \
        && [ -d "$PWD/${PUBLIC_OSS_REPOS[0]}" ]; then
        printf 'studio_root\n'
        return
    fi
    printf 'single_repo\n'
}

mode="$(detect_root)"

# --- Per-repo checks ---

audit_internal_repo() {
    local repo_dir="$1" repo_name="$2"
    local repo_failures=0

    # AGENTS.md: REQUIRED. Section-naming is repo-local discretion (each
    # repo titles its sections as fits its content); the auditor enforces
    # only the fleet-level requirements: presence, and a reference to
    # the Policy Origination policy so agents working in the repo
    # know fleet rules originate in your-policy-repo.
    if [ ! -f "$repo_dir/AGENTS.md" ]; then
        printf '%s/AGENTS.md:1: BLOCKING — missing AGENTS.md (canonical entry doc per OPERATING_MODEL Source Of Truth)\n' "$repo_name" >&2
        repo_failures=$((repo_failures + 1))
    else
        if ! grep -qE 'Policy Origination' "$repo_dir/AGENTS.md"; then
            printf '%s/AGENTS.md:1: ADVISORY — does not reference "Policy Origination" (codified policy in OPERATING_MODEL); add a brief reference so agents in this repo know fleet rules originate in your-policy-repo\n' "$repo_name" >&2
            # Advisory only — does not increment repo_failures.
        fi
    fi

    # SESSION_JOURNAL.md ADVISORY — bootstrap on next fleet-sync if absent.
    if [ ! -f "$repo_dir/SESSION_JOURNAL.md" ]; then
        printf '%s/SESSION_JOURNAL.md:1: ADVISORY — missing SESSION_JOURNAL.md (universal workpad; auto-bootstrapped on next fleet-sync from .agents/templates/SESSION_JOURNAL.template.md)\n' "$repo_name" >&2
    fi

    # AGENT_FEEDBACK.md ADVISORY — bootstrap on next fleet-sync if absent.
    if [ ! -f "$repo_dir/AGENT_FEEDBACK.md" ]; then
        printf '%s/AGENT_FEEDBACK.md:1: ADVISORY — missing AGENT_FEEDBACK.md (feedback channel; auto-bootstrapped on next fleet-sync from .agents/templates/AGENT_FEEDBACK.template.md)\n' "$repo_name" >&2
    fi

    # AGENT_INBOX.md ADVISORY — bootstrap on next fleet-sync if absent.
    if [ ! -f "$repo_dir/AGENT_INBOX.md" ]; then
        printf '%s/AGENT_INBOX.md:1: ADVISORY — missing AGENT_INBOX.md (incoming message channel; auto-bootstrapped on next fleet-sync from .agents/templates/AGENT_INBOX.template.md)\n' "$repo_name" >&2
    fi

    # WORKFLOW.md ADVISORY for internal repos (issue-tracker-dispatch contract).
    # Recommended by OPERATING_MODEL §"Dispatch Readiness" for active product
    # repos; the source policy repo is policy infrastructure and may
    # legitimately lack one. Auditor reports absence as advisory, not blocking.
    if [ ! -f "$repo_dir/WORKFLOW.md" ]; then
        printf '%s/WORKFLOW.md:1: ADVISORY — missing WORKFLOW.md (issue-tracker-dispatch contract; recommended for active product repos per OPERATING_MODEL §Dispatch Readiness)\n' "$repo_name" >&2
    elif [ "$repo_name" != "your-policy-repo" ]; then
        # WORKFLOW.body drift check: each repo's WORKFLOW.md MUST contain
        # the fleet-baseline prompt body from agents/templates/WORKFLOW.body.md
        # (under the per-repo intro paragraph). Detected via two stable
        # marker lines that appear verbatim in the body but not in any
        # legitimate per-repo intro: the Step 0 header and the Step 4
        # decomposition-gap-recovery header. Both must be present.
        local missing_markers=""
        if ! grep -qE "^## Step 0 — Orient" "$repo_dir/WORKFLOW.md"; then
            missing_markers="${missing_markers} 'Step 0 — Orient'"
        fi
        if ! grep -qE "^## Step 4 — Decomposition gap recovery" "$repo_dir/WORKFLOW.md"; then
            missing_markers="${missing_markers} 'Step 4 — Decomposition gap recovery'"
        fi
        if ! grep -qF "cross_validation_lane" "$repo_dir/WORKFLOW.md"; then
            missing_markers="${missing_markers} 'cross_validation_lane'"
        fi
        if ! grep -qE "^## Applicability" "$repo_dir/WORKFLOW.md"; then
            missing_markers="${missing_markers} 'Applicability preamble'"
        fi
        if [ -n "$missing_markers" ]; then
            printf '%s/WORKFLOW.md:1: BLOCKING — fleet-baseline body drift; missing marker(s):%s. Body source: agents/templates/WORKFLOW.body.md (or .agents/templates/WORKFLOW.body.md). Recompose: per-repo YAML + intro + fleet body verbatim.\n' "$repo_name" "$missing_markers" >&2
            repo_failures=$((repo_failures + 1))
        fi
    fi

    # If CLAUDE.md exists, first non-empty line MUST be "@AGENTS.md".
    if [ -f "$repo_dir/CLAUDE.md" ]; then
        first_meaningful=$(grep -m1 -vE '^[[:space:]]*$' "$repo_dir/CLAUDE.md" | head -1)
        # Strip leading "# Title" — common pattern is title-then-import,
        # so accept if line 1 is "# ..." OR if "@AGENTS.md" appears in
        # the first 5 non-empty lines.
        if ! head -10 "$repo_dir/CLAUDE.md" | grep -qE '^[[:space:]]*@AGENTS\.md\b'; then
            printf '%s/CLAUDE.md:1: BLOCKING — does not import @AGENTS.md (must in first 10 lines)\n' "$repo_name" >&2
            repo_failures=$((repo_failures + 1))
        fi
    fi

    # GEMINI.md (if present) MUST also import @AGENTS.md.
    if [ -f "$repo_dir/GEMINI.md" ]; then
        if ! head -10 "$repo_dir/GEMINI.md" | grep -qE '^[[:space:]]*@AGENTS\.md\b'; then
            printf '%s/GEMINI.md:1: BLOCKING — does not import @AGENTS.md (must in first 10 lines)\n' "$repo_name" >&2
            repo_failures=$((repo_failures + 1))
        fi
    fi

    if [ "$repo_failures" -eq 0 ]; then
        printf 'PASS  %-20s  internal  (AGENTS.md + WORKFLOW.md present, sections + Policy Origination present, agent-specific imports correct)\n' "$repo_name"
    else
        printf 'FAIL  %-20s  internal  (%d blocking failure(s) — see stderr)\n' "$repo_name" "$repo_failures"
        total_failures=$((total_failures + repo_failures))
        fail=1
    fi
}

audit_public_oss_repo() {
    local repo_dir="$1" repo_name="$2"
    local repo_failures=0

    # Public OSS MUST NOT have any root-level agent doc OR fleet
    # workpad. Workpads (AGENT_INBOX / AGENT_FEEDBACK / SESSION_JOURNAL)
    # carry fleet-internal handoff content and MUST be gitignored at OSS
    # repos per OPERATING_MODEL "Public OSS posture" — fleet-sync.sh
    # adds them to .gitignore on each sync.
    for forbidden in AGENTS.md CLAUDE.md GEMINI.md WORKFLOW.md AGENT_INBOX.md AGENT_FEEDBACK.md SESSION_JOURNAL.md; do
        if [ -f "$repo_dir/$forbidden" ]; then
            # Could be present untracked locally — only flag if tracked.
            if git -C "$repo_dir" ls-files --error-unmatch "$forbidden" >/dev/null 2>&1; then
                printf '%s/%s:1: BLOCKING — public OSS repo MUST NOT have tracked %s (per OPERATING_MODEL Public OSS posture)\n' "$repo_name" "$forbidden" "$forbidden" >&2
                repo_failures=$((repo_failures + 1))
            fi
        fi
    done

    # .agents/ and .claude/ MUST be gitignored (NOT tracked).
    for forbidden_dir in .agents .claude; do
        if [ -d "$repo_dir/$forbidden_dir" ]; then
            # Confirm gitignored.
            if ! git -C "$repo_dir" check-ignore -q "$forbidden_dir" 2>/dev/null; then
                printf '%s/%s:1: BLOCKING — public OSS repo present but NOT gitignored (per OPERATING_MODEL Public OSS posture)\n' "$repo_name" "$forbidden_dir" >&2
                repo_failures=$((repo_failures + 1))
            fi
        fi
    done

    if [ "$repo_failures" -eq 0 ]; then
        printf 'PASS  %-20s  public-oss  (no root-level agent docs; .agents/ and .claude/ gitignored if present)\n' "$repo_name"
    else
        printf 'FAIL  %-20s  public-oss  (%d blocking failure(s) — see stderr)\n' "$repo_name" "$repo_failures"
        total_failures=$((total_failures + repo_failures))
        fail=1
    fi
}

# --- Main ---

if [ "$mode" = "studio_root" ]; then
    printf 'audit-entry-docs.sh — running from studio root, auditing %d repos\n' "$((${#INTERNAL_REPOS[@]} + ${#PUBLIC_OSS_REPOS[@]}))"
    printf '%s\n' '----'
    for repo in "${INTERNAL_REPOS[@]}"; do
        if [ -d "$PWD/$repo" ]; then
            audit_internal_repo "$PWD/$repo" "$repo"
        else
            printf 'SKIP  %-20s  internal  (directory not found)\n' "$repo"
        fi
    done
    for repo in "${PUBLIC_OSS_REPOS[@]}"; do
        if [ -d "$PWD/$repo" ]; then
            audit_public_oss_repo "$PWD/$repo" "$repo"
        else
            printf 'SKIP  %-20s  public-oss  (directory not found)\n' "$repo"
        fi
    done
else
    # Single-repo mode: classify by basename.
    repo_name="$(basename "$PWD")"
    is_oss=0
    for r in "${PUBLIC_OSS_REPOS[@]}"; do
        if [ "$r" = "$repo_name" ]; then is_oss=1; break; fi
    done
    is_internal=0
    for r in "${INTERNAL_REPOS[@]}"; do
        if [ "$r" = "$repo_name" ]; then is_internal=1; break; fi
    done
    printf 'audit-entry-docs.sh — single-repo mode: %s\n' "$repo_name"
    printf '%s\n' '----'
    if [ "$is_oss" = "1" ]; then
        audit_public_oss_repo "$PWD" "$repo_name"
    elif [ "$is_internal" = "1" ]; then
        audit_internal_repo "$PWD" "$repo_name"
    else
        printf 'WARN  %s is not a known fleet repo (not in INTERNAL_REPOS or PUBLIC_OSS_REPOS); auditing as INTERNAL\n' "$repo_name" >&2
        audit_internal_repo "$PWD" "$repo_name"
    fi
fi

printf '%s\n' '----'
if [ "$fail" -eq 0 ]; then
    printf 'audit-entry-docs.sh: ALL PASS\n'
else
    printf 'audit-entry-docs.sh: FAIL — %d blocking failure(s) across the fleet\n' "$total_failures" >&2
fi
exit "$fail"
