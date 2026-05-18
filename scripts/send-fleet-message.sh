#!/usr/bin/env bash
# send-fleet-message.sh — append a structured message to a target repo's
# AGENT_INBOX.md, commit, and push.
#
# Usage:
#   bash send-fleet-message.sh <target-repo> <type> "<summary>" [< body.md]
#   bash send-fleet-message.sh --list                            # list inbox state per repo
#
# Types: fleet-update | directive-notice | handoff | request | ack
#
# Body is read from stdin if provided (heredoc-friendly), else the script
# uses minimal scaffolding. Run interactively to fill body fields one at a
# time.
#
# Authority:
#   file://skills/cross-repo-informational-channel/SKILL.md
#   file://skills/cross-repo-informational-channel/SKILL.md
#   file://workpads/AGENT_INBOX.template.md

set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
STUDIO_ROOT="$(dirname "$SOURCE_DIR")"
TEMPLATE_PATH="$SOURCE_DIR/agents/templates/AGENT_INBOX.template.md"

KNOWN_REPOS_FILE="${FLEET_KNOWN_REPOS_FILE:-$SOURCE_DIR/scripts/fleet-known-repos.txt}"
if [ -f "$KNOWN_REPOS_FILE" ]; then
    mapfile -t KNOWN_REPOS < <(grep -vE '^\s*(#|$)' "$KNOWN_REPOS_FILE")
else
    KNOWN_REPOS=()
fi
VALID_TYPES=(fleet-update directive-notice handoff request ack)

usage() {
    cat <<EOF
send-fleet-message.sh — append a structured message to a fleet repo's AGENT_INBOX.md

Usage:
  $0 <target-repo> <type> "<summary>" [< body-stdin]
  $0 --list                              show inbox entry counts per repo

target-repo: ${KNOWN_REPOS[*]}
type:        ${VALID_TYPES[*]}

When body is read from stdin (heredoc-friendly), the script expects:

  Authority: your-policy-repo@<sha> | file://... | owner://transcript-<date>
  Expects ack: true | false
  Relates to: <ref or "none">

  <one or more paragraphs of "What changed / what to pick up" content>

  Action required:
  - [ ] step 1
  - [ ] step 2

If no stdin body is provided, the script prompts interactively
for these fields.
EOF
}

is_known_repo() {
    local repo="$1"
    for r in "${KNOWN_REPOS[@]}"; do [ "$r" = "$repo" ] && return 0; done
    return 1
}

is_valid_type() {
    local t="$1"
    for v in "${VALID_TYPES[@]}"; do [ "$v" = "$t" ] && return 0; done
    return 1
}

resolve_target_path() {
    local repo="$1"
    if [ "$repo" = "your-policy-repo" ]; then
        printf '%s\n' "$SOURCE_DIR"
    else
        printf '%s\n' "$STUDIO_ROOT/$repo"
    fi
}

current_sender() {
    # Heuristic: identify which fleet repo this script is running from.
    local pwd_basename; pwd_basename="$(basename "$(pwd)")"
    if [ "$pwd_basename" = "your-policy-repo" ]; then
        printf '%s\n' "your-policy-repo"
        return
    fi
    for r in "${KNOWN_REPOS[@]}"; do
        if [ "$pwd_basename" = "$r" ]; then printf '%s\n' "$r"; return; fi
    done
    printf '%s\n' "your-policy-repo"  # default
}

list_inboxes() {
    printf '%-22s %s\n' "repo" "inbox-state"
    printf '%s\n' '----'
    for repo in "${KNOWN_REPOS[@]}"; do
        local path; path="$(resolve_target_path "$repo")"
        local inbox="$path/AGENT_INBOX.md"
        if [ ! -d "$path" ]; then
            printf '%-22s %s\n' "$repo" "(repo dir missing)"
        elif [ ! -f "$inbox" ]; then
            printf '%-22s %s\n' "$repo" "(no inbox — will bootstrap on first message)"
        else
            local count; count=$(grep -c '^## 20[0-9][0-9]-' "$inbox" 2>/dev/null || echo 0)
            count="${count:-0}"
            local unacked; unacked=$(grep -c '^\*\*Expects ack:\*\* true' "$inbox" 2>/dev/null || echo 0)
            unacked="${unacked:-0}"
            printf '%-22s %3d entries  (%d expect ack)  %s\n' "$repo" "$count" "$unacked" "$inbox"
        fi
    done
}

bootstrap_inbox() {
    local target_path="$1"
    [ -f "$target_path/AGENT_INBOX.md" ] && return 0
    [ -f "$TEMPLATE_PATH" ] || { echo "ERROR: template missing at $TEMPLATE_PATH" >&2; return 1; }
    cp "$TEMPLATE_PATH" "$target_path/AGENT_INBOX.md"
    echo "  (bootstrapped AGENT_INBOX.md from template)"
}

send() {
    local target="$1" mtype="$2" summary="$3"
    is_known_repo "$target" || { echo "ERROR: unknown target repo: $target" >&2; return 64; }
    is_valid_type "$mtype" || { echo "ERROR: unknown type: $mtype (valid: ${VALID_TYPES[*]})" >&2; return 64; }
    [ ${#summary} -le 80 ] || { echo "WARN: summary > 80 chars (${#summary}); inbox conventions suggest ≤ 80" >&2; }

    local target_path; target_path="$(resolve_target_path "$target")"
    [ -d "$target_path" ] || { echo "ERROR: target repo dir not found: $target_path" >&2; return 1; }

    bootstrap_inbox "$target_path"

    local sender; sender="$(current_sender)"
    local agent_id; agent_id="${AGENT_ID:-${USER:-unknown-agent}}"
    local model_id; model_id="${MODEL_ID:-${CLAUDE_MODEL:-unspecified-model}}"
    local now; now="$(date -u '+%Y-%m-%d %H:%M')"

    # Read body fields. If stdin is piped (non-tty), parse it; else prompt.
    local authority="" what_changed="" action_required="" expects_ack="false" relates_to="none"
    if [ ! -t 0 ]; then
        # stdin body. Expected key:value preamble + free-text "What changed".
        local body; body="$(cat)"
        authority=$(printf '%s' "$body" | awk -F': ' '/^Authority:/{$1=""; sub(/^: /,""); print; exit}')
        expects_ack=$(printf '%s' "$body" | awk -F': ' '/^Expects ack:/{print $2; exit}')
        relates_to=$(printf '%s' "$body" | awk -F': ' '/^Relates to:/{print $2; exit}')
        # Extract "What changed" = everything after the key:value preamble until "Action required:"
        what_changed=$(printf '%s' "$body" | awk '
            /^Action required:/{exit}
            /^(Authority|Expects ack|Relates to):/{next}
            NF { found = 1; print }
            !NF && found { print }
        ')
        action_required=$(printf '%s' "$body" | awk '/^Action required:/{flag=1; next} flag{print}')
        [ -z "$expects_ack" ] && expects_ack="false"
        [ -z "$relates_to" ] && relates_to="none"
        [ -z "$action_required" ] && action_required="- [ ] (none specified)"
    else
        # Interactive prompts (best effort).
        printf 'Authority (your-policy-repo@<sha> | file://... | owner://transcript-<date>): ' >&2
        read -r authority
        printf 'Expects ack (true/false) [false]: ' >&2
        read -r expects_ack; [ -z "$expects_ack" ] && expects_ack="false"
        printf 'Relates to (id/url or "none") [none]: ' >&2
        read -r relates_to; [ -z "$relates_to" ] && relates_to="none"
        printf 'What changed / what to pick up (single line; for multi-line use stdin body): ' >&2
        read -r what_changed
        action_required="- [ ] (action required not specified; see Summary)"
    fi
    [ -z "$authority" ] && { echo "ERROR: Authority field required" >&2; return 1; }

    # Compose the entry.
    local entry
    entry=$(cat <<MSG
## $now — $sender/$agent_id ($model_id) — $mtype

**Summary:** $summary

**Authority:** $authority

**What changed / what to pick up:**

$what_changed

**Action required:**

$action_required

**Expects ack:** $expects_ack

**Relates to:** $relates_to

---

MSG
    )

    # Insert at the top of "## Inbox" section.
    local tmp; tmp=$(mktemp)
    awk -v entry="$entry" '
        BEGIN { inserted = 0 }
        /^## Inbox/ {
            print
            getline
            print
            if (!inserted) {
                print entry
                inserted = 1
            }
            next
        }
        { print }
        END {
            if (!inserted) {
                # No ## Inbox heading found — append at end.
                print ""
                print "## Inbox"
                print ""
                print entry
            }
        }
    ' "$target_path/AGENT_INBOX.md" > "$tmp"
    mv "$tmp" "$target_path/AGENT_INBOX.md"

    # Stage + commit.
    local commit_msg="chore(inbox): $mtype from $sender: $summary"
    if git -C "$target_path" rev-parse --git-dir >/dev/null 2>&1; then
        # Check if file is tracked/ignored. If gitignored (OSS posture), skip commit but report.
        if git -C "$target_path" check-ignore -q AGENT_INBOX.md 2>/dev/null; then
            echo "  $target/AGENT_INBOX.md updated (gitignored; not committed)"
        else
            git -C "$target_path" add AGENT_INBOX.md
            if git -C "$target_path" commit -m "$commit_msg" >/dev/null 2>&1; then
                echo "  $target/AGENT_INBOX.md updated + committed"
                if git -C "$target_path" remote get-url origin >/dev/null 2>&1; then
                    if git -C "$target_path" push 2>/dev/null; then
                        echo "  pushed to $target origin"
                    else
                        echo "  (push deferred; remote may need explicit configuration)"
                    fi
                fi
            else
                echo "  WARN: commit failed in $target (may need INSTRUCTION_APPROVED or similar)"
            fi
        fi
    else
        echo "  $target/AGENT_INBOX.md updated (not a git repo)"
    fi
}

case "${1:-}" in
    --list) list_inboxes ;;
    -h|--help|"") usage ;;
    *)
        [ $# -ge 3 ] || { usage; exit 64; }
        send "$1" "$2" "$3"
        ;;
esac
