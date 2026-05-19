#!/usr/bin/env bash
# fleet-sync.sh — propagate the fleet baseline from the source policy
# repo to a target repo. UNIFORM mode: settings.json, statusline.sh,
# hooks/ are overwritten to fleet baseline. Per-repo permissions live
# in .claude/settings.local.json (gitignored).
#
# IMPORTANT: this script was written for the bes-fleet-policy source
# layout where fleet content lives under `<source>/agents/...`. The
# agentic-ops-framework v2.0 layout (this repo) does NOT have an
# `agents/` directory at the top level — its content lives under
# `spec-bundle/...`. Running this script with FLEET_SOURCE pointing
# at agentic-ops-framework v2.0 WILL FAIL: file copies of the form
# `$SOURCE/agents/$f` resolve to non-existent paths.
#
# Adopters of agentic-ops-framework v2.0 who want to operate a fleet
# should EITHER:
#   1. Establish a separate source-policy repo (bes-fleet-policy
#      style) with `agents/` layout, and use this script from there,
#      OR
#   2. Author their own v2.0-layout-aware propagation script that
#      reads from `<source>/spec-bundle/skills/`, `<source>/scripts/`,
#      etc. (a follow-on Task SPEC under v2.x will produce this
#      v2.0-native fleet-sync; not yet authored).
#
# This script is bundled in v2.0 as the reference implementation of
# the bes-fleet-policy-layout propagation pattern. It is intentionally
# preserved unchanged in its source-layout assumptions; the v2.0
# fleet-sync replacement is queued as a v2.x slice.
#
# Topology is manifest-driven. The manifest files (with the prefix
# determined at runtime per below):
#   fleet-files.txt          — .agents/ content paths
#   fleet-skills.txt         — skill names (mirrored to .claude/skills/)
#   fleet-commands.txt       — slash-command names
#   fleet-hooks.txt          — hook script names
#   fleet-hook-fixtures.txt  — hook test fixtures
#   fleet-oss-gitignore.txt  — OSS-posture .gitignore entries
#
# Usage: fleet-sync.sh <target-repo-absolute-path> <internal|oss>
#   internal: full fleet baseline; .agents/ + .claude/ committed.
#   oss:      .agents/ and .claude/ are gitignored (public OSS posture);
#             content lays in working tree only.
#
# Source location: auto-derived from script path. Override with FLEET_SOURCE env.
# Manifest dir:    auto-detected from FLEET_MANIFEST_DIR env, or
#                  agents/scripts/ if present, else scripts/.

set -eu

SCRIPT_DIR="$(cd "$(dirname "$(readlink -f "$0")")" && pwd)"
SOURCE="${FLEET_SOURCE:-$(cd "$SCRIPT_DIR/../.." && pwd)}"
TARGET="${1:?target repo path required}"
POSTURE="${2:?posture required (internal|oss)}"
case "$POSTURE" in internal|oss) ;; *) echo "posture must be internal|oss" >&2; exit 64 ;; esac

# Refuse to run against a source that does not have the expected
# bes-fleet-policy-style `agents/` layout. This refusal is the
# v2.0-layout-detection guard the codex review (finding 3.4) flagged
# was missing: previously the script would silently fail mid-copy.
if [ ! -d "$SOURCE/agents/scripts" ] || [ ! -f "$SOURCE/agents/scripts/fleet-skills.txt" ]; then
    echo "fleet-sync: source layout not recognised." >&2
    echo "  Expected: \$SOURCE/agents/scripts/fleet-skills.txt at $SOURCE/agents/scripts/fleet-skills.txt" >&2
    echo "  This script propagates from a bes-fleet-policy-style source." >&2
    echo "  If you are running it against an agentic-ops-framework v2.0" >&2
    echo "  source, switch to a separate source-policy repo (see script" >&2
    echo "  header) or wait for the v2.0-native propagation slice." >&2
    exit 65
fi
MANIFEST_DIR="$SOURCE/agents/scripts"

# Read a manifest file into a bash array.
# Strips blank lines and comments (# prefix).
read_manifest() {
    local file="$1"
    local -n out_array="$2"
    out_array=()
    [ -f "$file" ] || { echo "manifest not found: $file" >&2; exit 65; }
    while IFS= read -r line; do
        # skip blanks + comments
        case "$line" in ''|'#'*) continue ;; esac
        out_array+=("$line")
    done < "$file"
}

read_manifest "$MANIFEST_DIR/fleet-skills.txt" SKILLS
read_manifest "$MANIFEST_DIR/fleet-commands.txt" COMMANDS
read_manifest "$MANIFEST_DIR/fleet-hooks.txt" HOOKS
read_manifest "$MANIFEST_DIR/fleet-hook-fixtures.txt" HOOK_FIXTURES
read_manifest "$MANIFEST_DIR/fleet-oss-gitignore.txt" OSS_GITIGNORE

echo "=== fleet-sync to $TARGET (posture=$POSTURE) ==="

# Ensure target dirs
mkdir -p "$TARGET/.agents/skills" "$TARGET/.agents/workflows" "$TARGET/.agents/scripts/lint-spec-fixtures" "$TARGET/.agents/scripts/audit-entry-docs-fixtures/good-internal" "$TARGET/.agents/scripts/audit-entry-docs-fixtures/bad-no-agents-md" "$TARGET/.agents/scripts/audit-entry-docs-fixtures/bad-claude-md-no-import" "$TARGET/.agents/scripts/audit-entry-docs-fixtures/edge-leading-whitespace-import" "$TARGET/.agents/specs" "$TARGET/.agents/mcp" "$TARGET/.agents/templates" "$TARGET/.agents/githooks" "$TARGET/.agents/fleet-directives" "$TARGET/.githooks"
for skill in "${SKILLS[@]}"; do
    mkdir -p "$TARGET/.agents/skills/$skill"
done
mkdir -p "$TARGET/.claude/commands" "$TARGET/.claude/scripts" "$TARGET/.claude/skills" "$TARGET/.claude/hooks/tests"
for skill in "${SKILLS[@]}"; do
    mkdir -p "$TARGET/.claude/skills/$skill"
done

# .agents/ (canonical fleet content list — manifest-driven). Auto-create
# parent directories so skill-local references/ subdirs propagate without
# extra mkdir loops.
while IFS= read -r f; do
    [ -z "$f" ] && continue
    case "$f" in '#'*) continue ;; esac
    mkdir -p "$(dirname "$TARGET/.agents/$f")"
    cp "$SOURCE/agents/$f" "$TARGET/.agents/$f"
done < "$SOURCE/agents/scripts/fleet-files.txt"
# chmod +x every .sh propagated to .agents/scripts/ (idempotent).
find "$TARGET/.agents/scripts" -maxdepth 1 -name '*.sh' -type f -exec chmod +x {} +

# If a fleet-baseline commit-msg hook is part of your propagated content
# (under .agents/githooks/commit-msg), deploy it to the repo's .githooks/
# and set core.hooksPath. Skip silently when not present.
if [ -f "$TARGET/.agents/githooks/commit-msg" ]; then
    chmod +x "$TARGET/.agents/githooks/commit-msg"
    cp "$TARGET/.agents/githooks/commit-msg" "$TARGET/.githooks/commit-msg"
    chmod +x "$TARGET/.githooks/commit-msg"
    git -C "$TARGET" config core.hooksPath .githooks
fi

# If a per-tool config template is propagated under .agents/templates/
# (e.g., a parallel-worktree tool's project config), deploy it to the
# repo's .config/ directory. Skip silently when not present.
mkdir -p "$TARGET/.config"
if [ -f "$TARGET/.agents/templates/wt.toml.template" ]; then
    cp "$TARGET/.agents/templates/wt.toml.template" "$TARGET/.config/wt.toml"
fi

# Bootstrap SESSION_JOURNAL.md and AGENT_FEEDBACK.md from templates if absent.
# Never overwrite — these accumulate per-repo content that is owner+agent
# history, not fleet content. fleet-sync only seeds the empty file.
if [ ! -f "$TARGET/SESSION_JOURNAL.md" ]; then
    cp "$TARGET/.agents/templates/SESSION_JOURNAL.template.md" "$TARGET/SESSION_JOURNAL.md"
fi
if [ ! -f "$TARGET/AGENT_FEEDBACK.md" ]; then
    cp "$TARGET/.agents/templates/AGENT_FEEDBACK.template.md" "$TARGET/AGENT_FEEDBACK.md"
fi
if [ ! -f "$TARGET/AGENT_INBOX.md" ]; then
    cp "$TARGET/.agents/templates/AGENT_INBOX.template.md" "$TARGET/AGENT_INBOX.md"
fi

# Re-compose <repo>/WORKFLOW.md from existing YAML + per-repo intro + current
# fleet body. Skip when WORKFLOW.md lacks YAML front matter (studio root /
# policy repo use studio-shape docs, not the dispatcher template). The
# fleet body sentinel "Fleet-baseline WORKFLOW.md prompt body." marks where
# the per-repo intro ends and the canonical body begins.
if [ -f "$TARGET/WORKFLOW.md" ]; then
    if head -1 "$TARGET/WORKFLOW.md" | grep -q '^---$'; then
        SOURCE_BODY="$TARGET/.agents/templates/WORKFLOW.body.md"
        if [ -f "$SOURCE_BODY" ]; then
            yaml=$(awk 'BEGIN{c=0} /^---$/{c++; print; if(c==2) exit; next} c==1{print}' "$TARGET/WORKFLOW.md")
            intro=$(awk '
                BEGIN{c=0; past_yaml=0}
                /^---$/{c++; if(c==2){past_yaml=1; next}; next}
                past_yaml && /^<!--$/{
                    getline next_line
                    if (next_line ~ /^Fleet-baseline WORKFLOW\.md prompt body\./){
                        exit
                    }
                    print
                    print next_line
                    next
                }
                past_yaml{print}
            ' "$TARGET/WORKFLOW.md")
            {
                printf '%s\n\n' "$yaml"
                printf '%s' "$intro"
                printf '\n'
                cat "$SOURCE_BODY"
            } > "$TARGET/WORKFLOW.md.new"
            mv "$TARGET/WORKFLOW.md.new" "$TARGET/WORKFLOW.md"
        fi
    fi
fi

# Remove deprecated SPEC.template.md if present
if git -C "$TARGET" ls-files --error-unmatch .agents/specs/SPEC.template.md >/dev/null 2>&1; then
    git -C "$TARGET" rm -q .agents/specs/SPEC.template.md
elif [ -f "$TARGET/.agents/specs/SPEC.template.md" ]; then
    rm "$TARGET/.agents/specs/SPEC.template.md"
fi

# .claude/ commands
for cmd in "${COMMANDS[@]}"; do
    cp "$SOURCE/.claude/commands/$cmd.md" "$TARGET/.claude/commands/$cmd.md"
done

# .claude/ skills (mirrored from agents/skills/). Mirror SKILL.md plus
# any skill-local references/ subdir so progressive-disclosure references
# resolve correctly in the Claude harness.
for skill in "${SKILLS[@]}"; do
    cp "$SOURCE/agents/skills/$skill/SKILL.md" "$TARGET/.claude/skills/$skill/SKILL.md"
    if [ -d "$SOURCE/agents/skills/$skill/references" ]; then
        mkdir -p "$TARGET/.claude/skills/$skill/references"
        cp "$SOURCE/agents/skills/$skill/references/"*.md "$TARGET/.claude/skills/$skill/references/"
    fi
done

# .claude/ hooks + tests
for h in "${HOOKS[@]}"; do
    cp "$SOURCE/.claude/hooks/$h" "$TARGET/.claude/hooks/$h"
    chmod +x "$TARGET/.claude/hooks/$h"
done
cp "$SOURCE/.claude/hooks/tests/run-tests.sh" "$TARGET/.claude/hooks/tests/run-tests.sh"
chmod +x "$TARGET/.claude/hooks/tests/run-tests.sh"
mkdir -p "$TARGET/.claude/hooks/tests/fixtures"
for fixture in "${HOOK_FIXTURES[@]}"; do
    cp "$SOURCE/.claude/hooks/tests/fixtures/$fixture" "$TARGET/.claude/hooks/tests/fixtures/$fixture"
done

# .claude/ settings.json + statusline.sh (UNIFORM: overwrite)
cp "$SOURCE/.claude/settings.json" "$TARGET/.claude/settings.json"
cp "$SOURCE/.claude/scripts/statusline.sh" "$TARGET/.claude/scripts/statusline.sh"
chmod +x "$TARGET/.claude/scripts/statusline.sh"

# OSS posture: ensure .gitignore excludes the configured entries
# (agent-control content + root-level fleet workpads). Per OPERATING_MODEL
# "Public OSS posture".
if [ "$POSTURE" = "oss" ]; then
    for entry in "${OSS_GITIGNORE[@]}"; do
        if ! grep -qE "^${entry%/}/?\$" "$TARGET/.gitignore" 2>/dev/null; then
            printf '\n%s\n' "$entry" >> "$TARGET/.gitignore"
        fi
    done
fi

# Stage explicitly (internal repos only)
if [ "$POSTURE" = "internal" ]; then
    STAGE=()
    while IFS= read -r f; do
        [ -z "$f" ] && continue
        case "$f" in '#'*) continue ;; esac
        STAGE+=(".agents/$f")
    done < "$SOURCE/agents/scripts/fleet-files.txt"
    for cmd in "${COMMANDS[@]}"; do
        STAGE+=(".claude/commands/$cmd.md")
    done
    for skill in "${SKILLS[@]}"; do
        STAGE+=(".claude/skills/$skill/SKILL.md")
        if [ -d "$TARGET/.claude/skills/$skill/references" ]; then
            while IFS= read -r ref; do
                STAGE+=("$ref")
            done < <(cd "$TARGET" && find ".claude/skills/$skill/references" -type f -name '*.md')
        fi
    done
    for h in "${HOOKS[@]}"; do
        STAGE+=(".claude/hooks/$h")
    done
    STAGE+=(".claude/hooks/tests/run-tests.sh")
    for fixture in "${HOOK_FIXTURES[@]}"; do
        STAGE+=(".claude/hooks/tests/fixtures/$fixture")
    done
    STAGE+=(".claude/settings.json" ".claude/scripts/statusline.sh" ".githooks/commit-msg" ".config/wt.toml")
    # Stage WORKFLOW.md if the target uses the dispatcher YAML+body shape
    # (per-repo intro preserved, body re-composed above).
    if [ -f "$TARGET/WORKFLOW.md" ] && head -1 "$TARGET/WORKFLOW.md" | grep -q '^---$'; then
        STAGE+=("WORKFLOW.md")
    fi
    git -C "$TARGET" add -- "${STAGE[@]}"
fi
