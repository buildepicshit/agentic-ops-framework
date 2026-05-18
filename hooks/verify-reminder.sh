#!/usr/bin/env bash
set -euo pipefail
# Stop hook: non-blocking reminder of the verify gate. Always exits 0.
cat >/dev/null 2>&1 || true

spec_dir=""
# only specs/ on the public framework
[ -z "$spec_dir" ] && [ -d specs ] && spec_dir=specs

active_spec=""
if [ -n "$spec_dir" ]; then
    for f in "$spec_dir"/*/SPEC.md; do
        [ -f "$f" ] || continue
        st=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit} /^status:/{gsub(/^status:[[:space:]]*/,""); print; exit}' "$f")
        if [ "$st" = "in-execution" ] || [ "$st" = "approved" ]; then
            active_spec="$f"; break
        fi
    done
fi

if [ -n "$active_spec" ]; then
    st=$(awk 'BEGIN{c=0} /^---/{c++; if(c==2)exit} /^status:/{gsub(/^status:[[:space:]]*/,""); print; exit}' "$active_spec")
    printf 'Reminder: SPEC %s is %s. Run its acceptance_commands and fill the Completion Report before claiming done. Do not bypass the verify gate.\n' "$active_spec" "$st" >&2
else
    printf 'Reminder: verify gate before claiming done. Run the SPEC acceptance_commands and any repo-specific tests. Stage explicitly. No AI attribution. No pushes to the protected branch.\n' >&2
fi
exit 0
