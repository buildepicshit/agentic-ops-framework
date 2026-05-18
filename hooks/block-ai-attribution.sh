#!/usr/bin/env bash
# PreToolUse(Bash): block git commits whose message contains the AI co-author trailer.
# Reads message text from -m, --message=, -F file, or heredoc piped to git commit.
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

# Pass 1: real `git commit` invocation present?
real_commit=0
while IFS= read -r real_cmd; do
    [ -z "$real_cmd" ] && continue
    if printf '%s' "$real_cmd" | grep -qE '^git[[:space:]]+commit\b'; then
        real_commit=1; break
    fi
done < <(printf '%s' "$command" | extract_real_commands)

[ "$real_commit" = "0" ] && exit 0

# Pass 2: extract message text.
msg=""

m_arg=$(printf '%s' "$command" | grep -oE -- '(-m|--message=)[[:space:]]*("[^"]*"|'"'"'[^'"'"']*'"'"'|[^[:space:]"'"'"']+)' | head -1)
if [ -n "${m_arg:-}" ]; then
    val=$(printf '%s' "$m_arg" | sed -E 's/^(-m|--message=)[[:space:]]*//; s/^"//; s/"$//; s/^'"'"'//; s/'"'"'$//')
    msg="${msg}${val}
"
fi

f_arg=$(printf '%s' "$command" | grep -oE -- '-F[[:space:]]+[^[:space:]]+' | head -1 | sed -E 's/^-F[[:space:]]+//')
if [ -n "${f_arg:-}" ] && [ "$f_arg" != "-" ] && [ -f "$f_arg" ]; then
    msg="${msg}$(cat "$f_arg")
"
fi

if printf '%s' "$command" | grep -qE 'git[[:space:]]+commit[^|]*-F[[:space:]]+-' \
   || printf '%s' "$command" | grep -qE '\|[[:space:]]*git[[:space:]]+commit\b'; then
    body=$(printf '%s' "$command" | awk '
        BEGIN { in_heredoc = 0; tag = "" }
        {
            if (in_heredoc) {
                if ($0 ~ ("^" tag "$") || $0 ~ ("^[[:space:]]*" tag "$")) { in_heredoc = 0; tag = "" }
                else { print }
                next
            }
            if (match($0, /<<-?[[:space:]]*['"'"'"]?[A-Za-z_][A-Za-z0-9_]*['"'"'"]?/)) {
                t = substr($0, RSTART, RLENGTH)
                sub(/^<<-?[[:space:]]*/, "", t)
                gsub(/['"'"'"]/, "", t)
                in_heredoc = 1; tag = t
            }
        }')
    msg="${msg}${body}
"
fi

[ -z "${msg// }" ] && exit 0

if printf '%s' "$msg" | grep -qiE 'co[-_ ]?authored[-_ ]?by'; then
    printf 'block-ai-attribution: studio rule no AI attribution in commits.\n' >&2
    exit 2
fi
exit 0
