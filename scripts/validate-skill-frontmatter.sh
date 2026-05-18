#!/usr/bin/env bash
# validate-skill-frontmatter.sh — sanity-check SKILL.md YAML frontmatter
# across all skill directories present in the cwd repo.
#
# Scans whichever of these exist:
#   skills/         (framework source)
#   .claude/skills/ (Claude Code mirror)
#
# Catches the most common breakage: unquoted scalar values containing
# `: ` (colon-space), which strict YAML parsers reject.
#
# Exit: 0 clean, 1 issues found.

set -uo pipefail
fail=0

scan_dir() {
    local dir="$1"
    [ -d "$dir" ] || return 0
    while IFS= read -r -d '' f; do
        fm=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit; next} c==1' "$f")
        if [ -z "$fm" ]; then
            printf '%s: NO frontmatter\n' "$f" >&2
            fail=1; continue
        fi
        while IFS= read -r line; do
            case "$line" in
                ''|'#'*) continue ;;
            esac
            if [[ "$line" =~ ^([a-zA-Z_][a-zA-Z0-9_-]*):[[:space:]]*(.*)$ ]]; then
                key="${BASH_REMATCH[1]}"
                val="${BASH_REMATCH[2]}"
                val="${val#"${val%%[![:space:]]*}"}"
                val="${val%"${val##*[![:space:]]}"}"
                case "$val" in
                    '"'*|"'"*|'>'*|'|'*|'['*|'{'*) continue ;;
                    '') continue ;;
                esac
                if printf '%s' "$val" | grep -qE ': '; then
                    printf '%s: unquoted "%s:" value contains ": " (will break strict YAML)\n' "$f" "$key" >&2
                    fail=1
                fi
            fi
        done < <(printf '%s\n' "$fm")
    done < <(find "$dir" -name SKILL.md -type f -print0)
}

scan_dir skills/
scan_dir .claude/skills

if [ "$fail" = "0" ]; then
    echo "skill frontmatter: clean"
fi
exit "$fail"
