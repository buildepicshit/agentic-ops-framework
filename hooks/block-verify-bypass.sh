#!/usr/bin/env bash
# PreToolUse(Bash): block real --no-verify / --no-gpg-sign on git ops.
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
    if printf '%s' "$real_cmd" | grep -qE '^git[[:space:]]+(commit|push|rebase|merge|revert|cherry-pick|am)\b' \
       && printf '%s' "$real_cmd" | grep -qE -- '(--no-verify|--no-gpg-sign)\b'; then
        fired=1; matched="$real_cmd"; break
    fi
done < <(printf '%s' "$command" | extract_real_commands)

if [ "$fired" = "1" ]; then
    printf 'block-verify-bypass: verify gate is non-negotiable. (matched: %s)\n' "$matched" >&2
    exit 2
fi
exit 0
