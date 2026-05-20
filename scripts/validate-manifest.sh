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

# 3b. REQUIRED top-level field presence (codex Round-3 + Round-4).
# Per SPEC §8.1, the following are REQUIRED:
# - v2.0 baseline: spec_version, bundle_version, conformance_profile,
#   generated_on, generator (spec_version + conformance_profile
#   already validated above).
# - v2.1 additions: schema_uri, source_commit.
# Field values MAY be empty string at authoring time per the
# codex Round-2 honest-disclosure pattern; validator checks only
# presence of the key, not non-emptiness. source_tag stays OPTIONAL.
for required_key in bundle_version generated_on generator schema_uri source_commit; do
    if ! grep -qE "^${required_key}:" "$MANIFEST"; then
        err "REQUIRED top-level key missing: $required_key (per SPEC §8.1)"
    fi
done

# 3c. REQUIRED intent block fields (codex Round-4 finding).
# Per SPEC §8.2, intent MUST have product_name, product_purpose,
# developer_authority, installer_authority. product_name already
# validated above via actual_product_name check; here we verify
# the other three keys are declared inside the intent block.
for required_intent_key in product_purpose developer_authority installer_authority; do
    if ! grep -qE "^[[:space:]]+${required_intent_key}:" "$MANIFEST"; then
        err "REQUIRED intent key missing: $required_intent_key (per SPEC §8.2)"
    fi
done

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
# Parse primary + primary_index + media_type per facet per the v2.1
# schema (codex Round-2 BLOCKER finding closed: previously the script
# accepted directory primaries silently without verifying primary_index
# or media-type-extension conventions; this branch now enforces the
# v2.1 binding).
current_facet=""
declare -A facet_primary
declare -A facet_primary_index
declare -A facet_media_type
while IFS= read -r line; do
    if [[ "$line" =~ ^[[:space:]]{2}([a-z_-]+):[[:space:]]*$ ]]; then
        current_facet="${BASH_REMATCH[1]}"
    elif [[ "$line" =~ ^[[:space:]]{4}primary:[[:space:]]*\"?([^\"]*)\"?$ ]] && [ -n "$current_facet" ]; then
        primary="${BASH_REMATCH[1]}"
        primary="${primary%\"}"
        facet_primary["$current_facet"]="$primary"
    elif [[ "$line" =~ ^[[:space:]]{4}primary_index:[[:space:]]*\"?([^\"]*)\"?$ ]] && [ -n "$current_facet" ]; then
        pi="${BASH_REMATCH[1]}"
        pi="${pi%\"}"
        facet_primary_index["$current_facet"]="$pi"
    elif [[ "$line" =~ ^[[:space:]]{4}media_type:[[:space:]]*\"?([^\"]*)\"?$ ]] && [ -n "$current_facet" ]; then
        mt="${BASH_REMATCH[1]}"
        mt="${mt%\"}"
        facet_media_type["$current_facet"]="$mt"
    elif [[ "$line" =~ ^[a-z_-] ]]; then
        current_facet=""
    fi
done < "$MANIFEST"

# Media-type → file-extension expectations (v2.1 schema §8.3).
media_type_extension() {
    case "$1" in
        text/markdown) printf '.md' ;;
        text/x.gherkin) printf '.feature' ;;
        application/vnd.framework.conformance-suite) printf '' ;;  # any
        *) printf '' ;;
    esac
}

# Iterate every facet from the manifest, not just those that parsed a
# primary value. This closes the codex Round-3 BLOCKER where facets
# without a parsed primary silently escaped the check branch.
for facet in "${facet_slugs[@]}"; do
    primary="${facet_primary[$facet]:-}"
    if [ -z "$primary" ]; then
        err "facet '$facet' has no primary field in the manifest (per SPEC §8.3 primary is REQUIRED for every facet)"
        continue
    fi
    if [[ "$primary" == */ ]]; then
        # Directory primary — v2.1 requires primary_index.
        if [ ! -d "$BUNDLE_DIR/$primary" ]; then
            err "facet '$facet' primary directory missing: $primary"
            continue
        fi
        pi="${facet_primary_index[$facet]:-}"
        if [ -z "$pi" ]; then
            err "facet '$facet' primary is directory ($primary) but primary_index is missing (v2.1 schema §8.3 REQUIRED for directory primaries)"
            continue
        fi
        # primary_index MUST be INSIDE the primary directory
        # (codex Round-3 + Round-4: the string-prefix check was
        # fooled by path traversal like "behavior/features/../../
        # architecture/CONTEXT.md" which prefix-matched but
        # resolved outside the primary directory. Semantic
        # containment via canonicalised paths is the fix.)
        if [[ "$pi" != "$primary"* ]]; then
            err "facet '$facet' primary_index ($pi) is NOT inside primary directory ($primary); SPEC §8.3 requires containment (lexical prefix check)"
            continue
        fi
        # Semantic-containment check: canonicalise both paths and
        # verify the canonicalised primary_index sits inside the
        # canonicalised primary directory. Defeats ../ traversal.
        # Boundary fix (codex R5): use either equality OR "$path/"
        # prefix; bare "$path*" prefix-match would falsely accept
        # sibling dirs like "behavior/features-sibling/" when
        # primary is "behavior/features/".
        canon_primary="$(cd "$BUNDLE_DIR/$primary" 2>/dev/null && pwd)"
        canon_pi_dir="$(cd "$BUNDLE_DIR/$(dirname "$pi")" 2>/dev/null && pwd)"
        if [ -z "$canon_primary" ] || [ -z "$canon_pi_dir" ]; then
            err "facet '$facet' primary or primary_index cannot be canonicalised (primary=$primary, primary_index=$pi)"
            continue
        fi
        if [[ "$canon_pi_dir" != "$canon_primary" && "$canon_pi_dir" != "$canon_primary"/* ]]; then
            err "facet '$facet' primary_index ($pi) resolves OUTSIDE primary directory ($primary) after canonicalisation; SPEC §8.3 requires semantic containment"
            continue
        fi
        if [ ! -f "$BUNDLE_DIR/$pi" ]; then
            err "facet '$facet' primary_index file missing: $pi"
        fi
        # Media-type extension conformance (v2.1 §8.3).
        mt="${facet_media_type[$facet]:-}"
        ext="$(media_type_extension "$mt")"
        if [ -n "$ext" ]; then
            n_matching=$(find "$BUNDLE_DIR/$primary" -maxdepth 1 -name "*$ext" -type f 2>/dev/null | wc -l)
            if [ "$n_matching" -eq 0 ]; then
                err "facet '$facet' has media_type '$mt' (expects *$ext) but no matching files in $primary"
            fi
        fi
    else
        # File primary.
        if [ ! -f "$BUNDLE_DIR/$primary" ]; then
            err "facet '$facet' primary file missing: $primary"
        fi
    fi
done

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
