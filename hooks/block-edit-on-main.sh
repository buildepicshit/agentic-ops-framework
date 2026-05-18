#!/usr/bin/env bash
set -euo pipefail
# PreToolUse(Edit|Write): block edits on the protected branch UNLESS any SPEC
# (approved/in-execution/verified/closed) declares branch_policy: main-direct.
# A closed SPEC represents settled policy that persists until superseded. Failsafe: allow on errors.

cat >/dev/null 2>&1 || true

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || true)"

[ "$branch" = "main" ] || exit 0

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

printf 'block-edit-on-main: on protected branch and no active SPEC declares branch_policy: main-direct. Create a feature branch first.\n' >&2
exit 2
