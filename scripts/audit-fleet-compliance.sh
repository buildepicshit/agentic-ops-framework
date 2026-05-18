#!/usr/bin/env bash
# audit-fleet-compliance.sh — audit each fleet directive's compliance check
# against its target repos. Also surfaces unaddressed AGENT_FEEDBACK.md entries
# across the fleet.
#
# Usage:
#   bash scripts/audit-fleet-compliance.sh                    audit all `applied` and `pending` directives
#   bash scripts/audit-fleet-compliance.sh --validate <id>    validate directive format (no apply)
#   bash scripts/audit-fleet-compliance.sh --feedback         report only AGENT_FEEDBACK entries
#
# Authority:
#   file://skills/cross-repo-policy-enforcement/SKILL.md
#   file://docs/fleet-directives.md

set -uo pipefail

SOURCE_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../.." && pwd)"
DIRECTIVES_DIR="$SOURCE_DIR/agents/fleet-directives"
STUDIO_ROOT="$(dirname "$SOURCE_DIR")"
SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"

# Repo posture classification — manifest-driven.
# Edit fleet-{internal,oss,local-only}-repos.txt to change topology.
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
read_manifest "$SCRIPT_DIR/fleet-local-only-repos.txt" LOCAL_ONLY_REPOS
# The audit-fleet-compliance.sh script's INTERNAL_REPOS list intentionally
# excludes your-policy-repo (the policy repo audits itself separately).
# Strip it from the in-memory copy here:
INTERNAL_REPOS=("${INTERNAL_REPOS[@]/your-policy-repo/}")
INTERNAL_REPOS=("${INTERNAL_REPOS[@]/your-policy-repo/}")
# Filter empties:
TMP=("${INTERNAL_REPOS[@]}"); INTERNAL_REPOS=()
for r in "${TMP[@]}"; do [ -n "$r" ] && INTERNAL_REPOS+=("$r"); done

ALL_REPOS=("${INTERNAL_REPOS[@]}" "${PUBLIC_OSS_REPOS[@]}" "${LOCAL_ONLY_REPOS[@]}")

get_field() {
    local field="$1" file="$2"
    awk -v field="$field" '
        BEGIN { in_fm = 0 }
        /^---$/ { in_fm = !in_fm; next }
        in_fm && $1 == field":" { sub("^" field ":[[:space:]]*", ""); print; exit }
    ' "$file"
}

resolve_targets() {
    local field_val="$1"
    field_val=$(printf '%s' "$field_val" | tr -d '[]')
    case "$field_val" in
        all) printf '%s\n' "${ALL_REPOS[@]}" ;;
        all-internal) printf '%s\n' "${INTERNAL_REPOS[@]}" ;;
        all-oss) printf '%s\n' "${PUBLIC_OSS_REPOS[@]}" ;;
        *) printf '%s\n' "$field_val" | tr ',' '\n' | awk '{$1=$1; print}' ;;
    esac
}

extract_compliance_check() {
    awk '
        BEGIN { in_check = 0; in_block = 0 }
        /^## 3\. Compliance check/ { in_check = 1; next }
        /^## [0-9]+\./ && in_check { exit }
        in_check && /^```bash$/ { in_block = 1; next }
        in_check && /^```$/ && in_block { exit }
        in_check && in_block { print }
    ' "$1"
}

validate_directive() {
    local id="$1"
    local file="$DIRECTIVES_DIR/$id.md"
    [ -f "$file" ] || { echo "ERROR: directive not found: $file" >&2; return 1; }
    bash "$(dirname "$(readlink -f "$0")")/fleet-enforce.sh" --validate "$id"
}

audit_directives() {
    [ -d "$DIRECTIVES_DIR" ] || { echo "no directives dir"; return 0; }
    local total=0 compliant=0 drift=0 unknown=0
    local fail_lines=()
    for file in "$DIRECTIVES_DIR"/*.md; do
        [ -f "$file" ] || continue
        [ "$(basename "$file")" = README.md ] && continue
        total=$((total+1))
        local id status; id=$(get_field id "$file"); status=$(get_field status "$file")
        case "$status" in
            applied|pending) ;;
            *) printf '%-12s  %-30s  %s\n' "$status" "$id" "(skipped — not actively enforced)"; continue ;;
        esac

        local targets_raw; targets_raw=$(get_field target_repos "$file")
        local check; check=$(extract_compliance_check "$file")
        [ -n "$check" ] || { echo "ERROR: $id missing compliance check block" >&2; fail_lines+=("$id: missing check"); drift=$((drift+1)); continue; }

        local mapfile_tmp; mapfile_tmp=$(resolve_targets "$targets_raw")
        local any_fail=0
        while IFS= read -r repo; do
            [ -n "$repo" ] || continue
            local target_path="$STUDIO_ROOT/$repo"
            [ -d "$target_path" ] || { fail_lines+=("$id/$repo: directory absent"); any_fail=1; continue; }
            local rendered; rendered=$(printf '%s' "$check" | sed -e "s|\$TARGET|$target_path|g" -e "s|<target>|$target_path|g")
            if ! TARGET="$target_path" bash -c "$rendered" >/dev/null 2>&1; then
                fail_lines+=("$id/$repo: compliance check failed")
                any_fail=1
            fi
        done <<< "$mapfile_tmp"

        if [ "$any_fail" -eq 0 ]; then
            compliant=$((compliant+1))
            printf '%-12s  %-30s  all targets compliant\n' "$status" "$id"
        else
            drift=$((drift+1))
            printf '%-12s  %-30s  DRIFT — see failures below\n' "$status" "$id"
        fi
    done

    echo ""
    echo "summary: $total directives, $compliant compliant, $drift drift"
    if [ ${#fail_lines[@]} -gt 0 ]; then
        echo ""
        echo "FAILURES:"
        for line in "${fail_lines[@]}"; do echo "  - $line"; done
        return 1
    fi
    return 0
}

audit_feedback() {
    local total=0 surfaced=0 triaged=0 resolved=0 won_t=0
    echo "=== AGENT_FEEDBACK.md scan across fleet ==="
    for repo in "${ALL_REPOS[@]}" your-policy-repo; do
        local feedback_path
        if [ "$repo" = your-policy-repo ]; then
            feedback_path="$SOURCE_DIR/AGENT_FEEDBACK.md"
        else
            feedback_path="$STUDIO_ROOT/$repo/AGENT_FEEDBACK.md"
        fi
        [ -f "$feedback_path" ] || continue
        local entries
        entries=$(grep -c '^## 20[0-9][0-9]-' "$feedback_path" 2>/dev/null)
        # `grep -c` always prints a single number; default to 0 if file empty/missing.
        entries="${entries:-0}"
        [ "$entries" -gt 0 ] 2>/dev/null || continue
        printf '  %-20s %3d entries  (%s)\n' "$repo" "$entries" "$feedback_path"
        total=$((total + entries))
    done
    if [ "$total" -eq 0 ]; then
        echo "  (no feedback entries fleet-wide)"
    fi
}

case "${1:-}" in
    --validate)
        [ -n "${2:-}" ] || { echo "usage: $0 --validate <directive_id>"; exit 64; }
        validate_directive "$2"
        ;;
    --feedback)
        audit_feedback
        ;;
    --help|-h)
        cat <<EOF
audit-fleet-compliance.sh

  $0                       audit all applied/pending directives
  $0 --validate <id>       validate directive format
  $0 --feedback            scan AGENT_FEEDBACK.md across fleet
EOF
        ;;
    "")
        audit_directives && audit_feedback
        ;;
    *)
        echo "unknown arg: $1" >&2
        exit 64
        ;;
esac
