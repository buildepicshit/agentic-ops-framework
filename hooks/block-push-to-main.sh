#!/usr/bin/env bash
# PreToolUse(Bash): block real `git push` invocations targeting the protected
# branch UNLESS any SPEC (approved/in-execution/verified/closed) declares
# branch_policy: main-direct. A closed SPEC represents settled policy that
# persists until superseded. Mirrors block-edit-on-main.sh policy.
set -uo pipefail

# extract_real_commands: emit one logical command per line, with quoted strings
# and heredoc bodies stripped, so we only see the verb-position tokens.
extract_real_commands() {
    awk '
    BEGIN { in_heredoc = 0; tag = "" }
    {
        line = $0
        if (in_heredoc) {
            if (line ~ ("^" tag "$") || line ~ ("^[[:space:]]*" tag "$")) {
                in_heredoc = 0; tag = ""
            }
            next
        }
        if (match(line, /<<-?[[:space:]]*['\''"]?[A-Za-z_][A-Za-z0-9_]*['\''"]?/)) {
            t = substr(line, RSTART, RLENGTH)
            sub(/^<<-?[[:space:]]*/, "", t)
            gsub(/['\''"]/, "", t)
            in_heredoc = 1; tag = t
        }
        gsub(/'\''[^'\'']*'\''/, "", line)
        gsub(/"[^"]*"/, "", line)
        n = split(line, parts, /(&&|\|\||;|\||&)/)
        for (i = 1; i <= n; i++) {
            sub(/^[[:space:]]+/, "", parts[i])
            sub(/[[:space:]]+$/, "", parts[i])
            if (parts[i] != "") print parts[i]
        }
    }'
}

read_command() {
    local input
    input="$(cat)"
    if command -v jq >/dev/null 2>&1; then
        printf '%s' "$input" | jq -r '.tool_input.command // empty' 2>/dev/null || true
    else
        printf '%s' "$input" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/^"command"[[:space:]]*:[[:space:]]*"(.*)"$/\1/'
    fi
}

command="$(read_command)"
fired=0; matched=""
while IFS= read -r real_cmd; do
    [ -z "$real_cmd" ] && continue
    if printf '%s' "$real_cmd" | grep -qE '^git[[:space:]]+push\b'; then
        if printf '%s' "$real_cmd" | grep -qE '(^|[[:space:]])(\+?(HEAD|[A-Za-z0-9_./-]+):)?(refs/heads/)?main([[:space:]]|$)'; then
            fired=1; matched="$real_cmd"; break
        fi
    fi
done < <(printf '%s' "$command" | extract_real_commands)

[ "$fired" = "1" ] || exit 0

# Push-to-main detected. Honour `branch_policy: main-direct` if any SPEC at
# approved/in-execution/verified/closed declares it.
repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -n "$repo_root" ]; then
    allow_main_direct=0
    for d in "$repo_root/specs"; do
        [ -d "$d" ] || continue
        for f in "$d"/*/SPEC.md; do
            [ -f "$f" ] || continue
            st=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit} /^status:/{gsub(/^status:[[:space:]]*/,""); print; exit}' "$f")
            case "$st" in
                approved|in-execution|verified|closed)
                    bp=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit} /^branch_policy:/{gsub(/^branch_policy:[[:space:]]*/,""); print; exit}' "$f")
                    if [ "$bp" = "main-direct" ]; then
                        allow_main_direct=1; break 2
                    fi
                    ;;
            esac
        done
    done
    [ "$allow_main_direct" = "1" ] && exit 0
fi

printf 'block-push-to-main: protected branch is non-pushable. Open a PR. (matched: %s)\n' "$matched" >&2
exit 2
