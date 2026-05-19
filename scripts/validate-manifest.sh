#!/usr/bin/env bash
# validate-manifest.sh — mechanical gate for spec-bundle/manifest.yaml.
#
# Authority: file://specs/2026-05-19-v2-manifest-catalog-repack/SPEC.md
#   §6.1 (manifest schema), §8 (formal schema), §9.1 (validation
#   algorithm pseudocode).
#
# Checks:
# 1. spec-bundle/manifest.yaml exists and parses.
# 2. spec_version matches the schema version in this script
#    (currently 2.0.0).
# 3. conformance_profile is one of {core, extension, real-integration}.
# 4. Every facet listed has its directory and primary file.
# 5. Every directory under spec-bundle/ (except resource dirs) is
#    listed in facets.
# 6. intent.product_name matches the repo identifier.
#
# Exit 0 iff valid; non-zero with diagnostics to stderr.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUNDLE_DIR="$REPO_ROOT/spec-bundle"
MANIFEST="$BUNDLE_DIR/manifest.yaml"

EXPECTED_SPEC_VERSION="2.1.0"
EXPECTED_PRODUCT_NAME="agentic-ops-framework"
VALID_PROFILES="core extension real-integration"

# Directories under spec-bundle/ that are resources, not facets.
RESOURCE_DIRS=("schema" "templates" "skills" "conformance")

errors=()

err() {
    errors+=("$1")
}

if [ ! -f "$MANIFEST" ]; then
    printf 'validate-manifest: FAIL — manifest not found at %s\n' "$MANIFEST" >&2
    exit 1
fi

# Extract scalar fields via grep + sed (no yq dependency).
get_field() {
    local field="$1"
    grep -E "^${field}:" "$MANIFEST" | head -1 | sed -E "s/^${field}:[[:space:]]*//;s/^\"//;s/\"$//"
}

actual_spec_version="$(get_field 'spec_version')"
actual_conformance="$(get_field 'conformance_profile')"

# 2. spec_version match.
if [ "$actual_spec_version" != "$EXPECTED_SPEC_VERSION" ]; then
    err "spec_version mismatch: expected $EXPECTED_SPEC_VERSION, got '$actual_spec_version'"
fi

# 3. conformance_profile valid.
if ! printf '%s\n' $VALID_PROFILES | grep -qFx "$actual_conformance"; then
    err "conformance_profile invalid: got '$actual_conformance'; expected one of {$VALID_PROFILES}"
fi

# 6. product_name match (search for product_name under intent).
actual_product_name="$(grep -E '^[[:space:]]+product_name:' "$MANIFEST" | head -1 | sed -E 's/^[[:space:]]+product_name:[[:space:]]*//;s/^"//;s/"$//')"
if [ "$actual_product_name" != "$EXPECTED_PRODUCT_NAME" ]; then
    err "intent.product_name mismatch: expected $EXPECTED_PRODUCT_NAME, got '$actual_product_name'"
fi

# 4 + 5. Parse facets block; extract slugs.
# Match lines indented two spaces under "facets:" that end with ":".
declare -a facet_slugs=()
in_facets=0
in_facets_record=""
while IFS= read -r line; do
    if [[ "$line" =~ ^facets: ]]; then
        in_facets=1
        continue
    fi
    if [ $in_facets -eq 1 ]; then
        # Top-level key (no indent) ends facets block.
        if [[ "$line" =~ ^[a-z_-] ]]; then
            in_facets=0
            continue
        fi
        # Two-space-indented key with no further indent is a facet name.
        if [[ "$line" =~ ^[[:space:]]{2}[a-z_-]+:[[:space:]]*$ ]]; then
            slug="${line//[[:space:]]/}"
            slug="${slug%:}"
            facet_slugs+=("$slug")
        fi
    fi
done < "$MANIFEST"

if [ ${#facet_slugs[@]} -eq 0 ]; then
    err "facets block empty or unparseable"
fi

# Build set of fs facet dirs.
declare -a fs_dirs=()
if [ -d "$BUNDLE_DIR" ]; then
    while IFS= read -r dir; do
        base="$(basename "$dir")"
        # Skip resource dirs.
        is_resource=0
        for r in "${RESOURCE_DIRS[@]}"; do
            if [ "$base" = "$r" ]; then
                is_resource=1
                break
            fi
        done
        if [ $is_resource -eq 0 ]; then
            fs_dirs+=("$base")
        fi
    done < <(find "$BUNDLE_DIR" -mindepth 1 -maxdepth 1 -type d | sort)
fi

# Compare facet slugs vs fs dirs.
for slug in "${facet_slugs[@]}"; do
    found=0
    for d in "${fs_dirs[@]}"; do
        [ "$d" = "$slug" ] && found=1 && break
    done
    if [ $found -eq 0 ]; then
        err "facet '$slug' listed in manifest but no directory at spec-bundle/$slug/"
    fi
done

for d in "${fs_dirs[@]}"; do
    found=0
    for slug in "${facet_slugs[@]}"; do
        [ "$slug" = "$d" ] && found=1 && break
    done
    if [ $found -eq 0 ]; then
        err "directory spec-bundle/$d/ exists but not listed in manifest facets"
    fi
done

# Check each facet's primary file exists.
# Parse primary field per facet — look for two-space-indented "primary:".
current_facet=""
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]{2}([a-z_-]+):[[:space:]]*$ ]]; then
        current_facet="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]{4}primary:[[:space:]]*\"?([^\"]*)\"?$ ]] && [ -n "$current_facet" ]; then
        primary="${BASH_REMATCH[1]}"
        # Strip trailing quote if any.
        primary="${primary%\"}"
        # Primary may be a file or a directory (e.g., behavior/features/).
        if [[ "$primary" == */ ]]; then
            if [ ! -d "$BUNDLE_DIR/$primary" ]; then
                err "facet '$current_facet' primary directory missing: $primary"
            fi
        else
            if [ ! -f "$BUNDLE_DIR/$primary" ]; then
                err "facet '$current_facet' primary file missing: $primary"
            fi
        fi
    elif [[ "$line" =~ ^[a-z_-] ]]; then
        current_facet=""
    fi
done < "$MANIFEST"

if [ ${#errors[@]} -gt 0 ]; then
    printf 'validate-manifest: %d issue(s) found:\n' "${#errors[@]}" >&2
    for e in "${errors[@]}"; do
        printf '  - %s\n' "$e" >&2
    done
    exit 1
fi

printf 'validate-manifest: PASS — manifest schema %s, conformance %s, %d facets\n' \
    "$actual_spec_version" "$actual_conformance" "${#facet_slugs[@]}"
exit 0
