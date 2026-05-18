#!/usr/bin/env bash
# SessionStart hook: inject high-signal session-init context that Claude
# Code actually reads.
#
# Per https://code.claude.com/docs/en/hooks SessionStart is one of the
# three hooks (with UserPromptSubmit and UserPromptExpansion) whose
# stdout IS added to Claude's context — unlike PreCompact and Stop,
# whose stdout goes to the debug log only and is invisible to Claude.
#
# Replaces the earlier precompact-priorities.sh and
# session-end-learnings-reminder.sh hooks, which were misaligned with
# the contract and dropped their output into the debug log.
#
# Always exits 0. Stdout is emitted as Markdown for context injection.

set -uo pipefail

# Drain stdin defensively (Claude Code passes a JSON envelope).
cat >/dev/null 2>&1 || true

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
cd "$repo_root" 2>/dev/null || true

repo_name="$(basename "$repo_root")"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"

# Find the active SPEC if any (status: approved or in-execution).
active_spec=""
active_status=""
for d in specs; do
    [ -d "$d" ] || continue
    for f in "$d"/*/SPEC.md; do
        [ -f "$f" ] || continue
        st=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit} /^status:/{gsub(/^status:[[:space:]]*/,""); print; exit}' "$f")
        if [ "$st" = "approved" ] || [ "$st" = "in-execution" ]; then
            active_spec="$f"
            active_status="$st"
            break 2
        fi
    done
done

# Emit context as Markdown. Claude Code injects this on session start.
printf '## Session-init context (hooks/session-start-context.sh)\n\n'
printf 'Repo: `%s`  •  Branch: `%s`\n\n' "$repo_name" "$branch"

if [ -n "$active_spec" ]; then
    printf 'Active SPEC: `%s` (status: `%s`)\n\n' "$active_spec" "$active_status"
fi

# Recent commits (last 5) — helps understand what just happened.
if git rev-parse HEAD >/dev/null 2>&1; then
    printf 'Recent commits (last 5):\n\n'
    git log --oneline -5 2>/dev/null | sed 's/^/- /'
    printf '\n'
fi

# Working-tree state (modified + untracked files; capped to 8 each).
modified_count=$(git ls-files -m 2>/dev/null | wc -l | tr -d ' ')
untracked_count=$(git status --porcelain 2>/dev/null | grep -c '^??' || true)
if [ "$modified_count" -gt 0 ] || [ "$untracked_count" -gt 0 ]; then
    printf 'Working-tree state:\n\n'
    if [ "$modified_count" -gt 0 ]; then
        printf -- '- %d modified file(s):\n' "$modified_count"
        git ls-files -m 2>/dev/null | head -8 | sed 's/^/    - /'
        if [ "$modified_count" -gt 8 ]; then
            printf -- '    - ... and %d more\n' "$((modified_count - 8))"
        fi
    fi
    if [ "$untracked_count" -gt 0 ]; then
        printf -- '- %d untracked file(s):\n' "$untracked_count"
        git status --porcelain 2>/dev/null | grep '^??' | head -8 | sed 's/^?? /    - /'
        if [ "$untracked_count" -gt 8 ]; then
            printf -- '    - ... and %d more\n' "$((untracked_count - 8))"
        fi
    fi
    printf '\n'
fi

# Hint to read the full state if it changes the agent's plan.
printf 'For full state read `STATUS.md` and `AGENTS.md`. For active SPEC read its body and §17 Completion Report.\n'

exit 0
