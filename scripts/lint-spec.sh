#!/usr/bin/env bash
# lint-spec.sh — v1 lint for IDEA.md and SPEC.md artefacts.
#
# Authority: file://specs/2026-01-15-example-procedure-v1/SPEC.md
#   §10.5 (lint requirements), §17.5 (reference algorithm), §9.1–§9.4
#   (per-type required sections), §8 / templates/SPEC.schema.md
#   (citation grammar, RFC 2119 rules, front-matter schema).
#
# Behavior is non-mutating and offline. The script reads the target
# file, prints a summary to stdout, prints diagnostics to stderr, and
# exits with one of:
#   0 — clean
#   1 — blocking errors
#   2 — advisory-only warnings
#   64 — usage error
#
# Suppression markers (per SPEC.schema §2.5):
#   <!-- lint-ok: no-citation --> on a paragraph silences the citation audit.
#   <!-- lint-ok: no-rfc        --> on a line silences the lowercase RFC 2119 warning.

set -eu

PROG="$(basename "$0")"

usage() {
    printf 'usage: %s <path-to-IDEA.md-or-SPEC.md>\n' "$PROG" >&2
    exit 64
}

[[ $# -eq 1 ]] || usage
TARGET="$1"
[[ -f "$TARGET" ]] || { printf '%s: not a file: %s\n' "$PROG" "$TARGET" >&2; exit 64; }

BASENAME="$(basename "$TARGET")"

errors=()
warnings=()

emit_err()  { errors+=("$1");  printf '%s:%s: %s\n' "$TARGET" "$2" "$3" >&2; }
emit_warn() { warnings+=("$1"); printf '%s:%s: warning: %s\n' "$TARGET" "$2" "$3" >&2; }

# ---------- Front-matter parse ----------
fm_start=0; fm_end=0
mapfile -t LINES < "$TARGET"
total_lines=${#LINES[@]}

if [[ $total_lines -gt 0 && "${LINES[0]}" == "---" ]]; then
    fm_start=1
    for ((i=1; i<total_lines; i++)); do
        if [[ "${LINES[$i]}" == "---" ]]; then
            fm_end=$((i+1))
            break
        fi
    done
fi

if [[ $fm_start -eq 0 || $fm_end -eq 0 ]]; then
    emit_err "front-matter" 1 "missing or unterminated YAML front-matter block"
fi

declare -A FM
if [[ $fm_end -gt 0 ]]; then
    for ((i=1; i<fm_end-1; i++)); do
        line="${LINES[$i]}"
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]] && continue
        if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*):[[:space:]]*(.*)$ ]]; then
            key="${BASH_REMATCH[1]}"
            val="${BASH_REMATCH[2]}"
            val="${val%%[[:space:]]#*}"
            FM[$key]="$val"
        fi
    done
fi

# ---------- Type detection ----------
ARTEFACT="spec"
[[ "$BASENAME" == "IDEA.md" ]] && ARTEFACT="idea"

if [[ "$ARTEFACT" == "idea" ]]; then
    TYPE="${FM[implies_spec_type]:-}"
else
    TYPE="${FM[type]:-}"
fi
case "$TYPE" in
    task|contract|decision|fastpath) ;;
    "") emit_err "front-matter" "$fm_end" "missing type/implies_spec_type field" ;;
    *)  emit_err "front-matter" "$fm_end" "unknown type: $TYPE" ;;
esac

# ---------- Required-section presence ----------
# Per SPEC.schema §4.1, section IDENTITY is its title; section number is
# informational. We strip leading "<digits>. " from both required and
# observed before comparing.
required_sections=()
case "$ARTEFACT-$TYPE" in
    idea-*)
        required_sections=(
            "Normative Language"
            "Problem Seed"
            "Substance Citations"
            "Constraints & Non-Negotiables"
            "Approaches Considered"
            "Recommendation"
            "Open Questions for Owner"
            "Owner Judgments"
        ) ;;
    spec-task)
        required_sections=(
            "Normative Language"
            "Problem" "North Star / Product Promise" "Goals" "Non-Goals"
            "Current System Facts" "Authority Map" "Code/Docs Reality Check"
            "Desired Behavior" "Domain Model / Contract" "Interfaces and Files"
            "Execution Plan" "Safety / Scope Invariants" "Test Plan"
            "Acceptance Criteria" "Rollback Plan" "Open Questions"
            "Completion Report"
        ) ;;
    spec-contract)
        # Per 2026-01-15 ceremony-weight-refactor Decision SPEC §7,
        # "Open Questions" is OPTIONAL when empty — removed from the
        # required list. Authors MAY omit the heading entirely when no
        # open questions remain. Existing Contracts that retain §17
        # with substantive content remain unaffected (existing
        # per-section citation checks still apply when present).
        required_sections=(
            "Normative Language"
            "Problem Statement" "Goals and Non-Goals" "System Overview"
            "Authority Map" "Code/Docs Reality Check" "Domain Model"
            "Schema Specification" "Reference Algorithms" "Failure Model"
            "Trust Boundary / Security" "Observability"
            "Test and Validation Matrix" "Implementation Checklist"
            "Acceptance Criteria" "Rollback Plan"
            "Completion Report"
        )
        # Per Decision SPEC §7 (d), capture-after defer-shorthand for §1
        # Problem Statement and §13 Test and Validation Matrix is
        # PERMITTED only when front-matter status: verified AND the
        # producing IDEA is cited. Enforcement note: the existing §2
        # citation-grammar rule already requires every fact-bearing
        # paragraph to carry a cite, so a single-paragraph
        # file://specs/<id>/IDEA.md cite in §1 or §13 passes lint by
        # construction. The "shorthand requires verified" check lives
        # in the spec-review skill (per-type gate), not in this lint,
        # to keep the script's conditional logic small.
        ;;
    spec-decision)
        required_sections=(
            "Problem" "Substance Citations" "Authority Map"
            "Decision Criteria" "Candidate Options" "Trade-off Comparison"
            "Decision Statement" "Decision Rationale" "Locks"
            "Reversal Plan" "Validation Plan" "Acceptance Criteria"
            "Open Questions" "Completion Report"
        ) ;;
    spec-fastpath)
        # Fastpath SPECs are intentionally minimal. Required sections only.
        required_sections=(
            "Normative Language"
            "Problem" "Files changed" "Owner directive"
            "Acceptance commands" "Completion Report"
        ) ;;
esac

# Strip "<digits or digits.digits>. " prefix from a section title.
strip_section_number() {
    local t="$1"
    if [[ "$t" =~ ^[0-9]+(\.[0-9]+)*[.][[:space:]]+(.*)$ ]]; then
        printf '%s' "${BASH_REMATCH[2]}"
    else
        printf '%s' "$t"
    fi
}

# Collect observed top-level (## ) section titles, with line numbers.
observed_titles=()
observed_title_lines=()
for ((i=fm_end; i<total_lines; i++)); do
    line="${LINES[$i]}"
    if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
        title="${BASH_REMATCH[1]}"
        observed_titles+=("$title")
        observed_title_lines+=($((i+1)))
    fi
done

section_present() {
    local needle="$1" t bare_needle bare_t
    bare_needle="$(strip_section_number "$needle")"
    for t in "${observed_titles[@]:-}"; do
        bare_t="$(strip_section_number "$t")"
        # Title-only prefix match: handles "Implementation Checklist
        # (Definition of Done)" matching "Implementation Checklist" and
        # similar parenthetical extensions.
        [[ "$bare_t" == "$bare_needle" || "$bare_t" == "$bare_needle "* || "$bare_t" == "$bare_needle("* ]] && return 0
    done
    return 1
}

for s in "${required_sections[@]:-}"; do
    if ! section_present "$s"; then
        emit_err "section" "$fm_end" "missing required section: ## $s"
    fi
done

# ---------- Build per-section line ranges ----------
section_starts=()
section_ends=()
section_titles_all=()
for ((idx=0; idx<${#observed_titles[@]}; idx++)); do
    section_titles_all+=("${observed_titles[$idx]}")
    section_starts+=($((observed_title_lines[$idx]-1)))
done
for ((idx=0; idx<${#section_starts[@]}; idx++)); do
    if (( idx+1 < ${#section_starts[@]} )); then
        section_ends+=($((section_starts[idx+1]-1)))
    else
        section_ends+=($((total_lines-1)))
    fi
done

is_normative_title() {
    local t="$1"
    case "$t" in
        *"Desired Behavior"*|*"Acceptance Criteria"*|*"Test Plan"*|*"Test and Validation Matrix"*|\
        *"Decision Statement"*|*"Constraints"*|*"Safety"*|*"Goals"*|*"Non-Goals"*|\
        *"Implementation Checklist"*|"Normative Language") return 0 ;;
    esac
    return 1
}

strip_code() {
    awk 'BEGIN{ORS=""} {
        s=$0; out="";
        while ((p=index(s,"`"))>0) {
            out=out substr(s,1,p-1);
            s=substr(s,p+1);
            q=index(s,"`");
            if (q>0) { s=substr(s,q+1); } else { out=out s; s=""; break; }
        }
        print out s;
    }' <<< "$1"
}

# Find the body H1 title region (the first `# ` heading after front-matter
# and the immediately-following paragraph). Citation audit skips these.
h1_para_start=-1; h1_para_end=-1
for ((i=fm_end; i<total_lines; i++)); do
    line="${LINES[$i]}"
    if [[ "$line" =~ ^#[[:space:]](.+)$ && ! "$line" =~ ^## ]]; then
        # Found body H1. Title region = from line after H1 through next blank
        # line (or first ## section header, whichever is first).
        for ((j=i+1; j<total_lines; j++)); do
            jline="${LINES[$j]}"
            [[ "$jline" =~ ^## ]] && break
            if [[ -z "${jline// }" ]]; then
                # Skip leading blank, then the next paragraph IS the title region.
                k=$j
                while (( k<total_lines )) && [[ -z "${LINES[$k]// }" ]]; do k=$((k+1)); done
                h1_para_start=$k
                while (( k<total_lines )) && [[ -n "${LINES[$k]// }" ]]; do
                    [[ "${LINES[$k]}" =~ ^## ]] && break
                    h1_para_end=$k
                    k=$((k+1))
                done
                break
            fi
        done
        break
    fi
done

# ---------- RFC 2119 lowercase scan ----------
RFC_RE='\b(must not|should not|shall not|must|should|may|required|recommended|optional|shall)\b'
SUPPRESS_RFC='<!-- lint-ok: no-rfc -->'

# Heuristic: only flag lowercase keywords when they appear in imperative
# position — i.e. the line begins with the keyword, or with "- " then the
# keyword, or with the keyword preceded only by markdown emphasis tokens
# ("**must**: ..."). This eliminates ordinary English usage in the
# middle of clauses ("specs may complete", "in-flight specs may
# complete") while still catching genuine missed-uppercase normative
# sentences.
is_imperative_lc_line() {
    local line="$1"
    # Strip leading list markers, blockquote markers, emphasis.
    local stripped
    stripped="${line#"${line%%[![:space:]]*}"}"     # ltrim
    stripped="${stripped#- }"
    stripped="${stripped#> }"
    stripped="${stripped#\*\*}"
    case "$stripped" in
        "must "*|"must:"*|"must,"*|"must not "*|"must not:"*|\
        "should "*|"should:"*|"should not "*|"should not:"*|\
        "shall "*|"shall:"*|"shall not "*|\
        "may "*|"may:"*|\
        "required "*|"required:"*|\
        "recommended "*|"recommended:"*|\
        "optional "*|"optional:"*) return 0 ;;
    esac
    return 1
}

in_fence=0
for ((i=fm_end; i<total_lines; i++)); do
    line="${LINES[$i]}"
    if [[ "$line" =~ ^\`\`\` ]]; then
        in_fence=$((1 - in_fence)); continue
    fi
    (( in_fence )) && continue
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^\| ]] && continue
    [[ "$line" == *"$SUPPRESS_RFC"* ]] && continue
    sec_idx=-1
    for ((s=0; s<${#section_starts[@]}; s++)); do
        if (( i >= section_starts[s] && i <= section_ends[s] )); then
            sec_idx=$s; break
        fi
    done
    (( sec_idx < 0 )) && continue
    sec_title="${section_titles_all[$sec_idx]}"
    if is_normative_title "$sec_title"; then
        clean="$(strip_code "$line")"
        if [[ "$clean" =~ $RFC_RE ]]; then
            kw="${BASH_REMATCH[1]}"
            [[ "$clean" == *'`MUST`'* || "$clean" == *'`SHOULD`'* || "$clean" == *'`MAY`'* ]] && continue
            # Imperative-position heuristic: only warn if the line BEGINS
            # with the keyword (or list-marker + keyword). Otherwise treat
            # as ordinary English usage.
            is_imperative_lc_line "$clean" || continue
            emit_warn "rfc2119" $((i+1)) "lowercase RFC 2119 keyword '$kw' in normative section ($sec_title)"
        fi
    fi
done

# ---------- Decision SPEC scope rule ----------
if [[ "$ARTEFACT" == "spec" && "$TYPE" == "decision" ]]; then
    UPPER_RE='\b(MUST NOT|SHOULD NOT|SHALL NOT|MUST|SHOULD|MAY|REQUIRED|RECOMMENDED|OPTIONAL|SHALL)\b'
    in_fence=0
    for ((i=fm_end; i<total_lines; i++)); do
        line="${LINES[$i]}"
        if [[ "$line" =~ ^\`\`\` ]]; then in_fence=$((1-in_fence)); continue; fi
        (( in_fence )) && continue
        [[ "$line" =~ ^# ]] && continue
        sec_idx=-1
        for ((s=0; s<${#section_starts[@]}; s++)); do
            if (( i >= section_starts[s] && i <= section_ends[s] )); then sec_idx=$s; break; fi
        done
        (( sec_idx < 0 )) && continue
        title="${section_titles_all[$sec_idx]}"
        case "$title" in *"Decision Statement"*|"Normative Language") continue ;; esac
        clean="$(strip_code "$line")"
        if [[ "$clean" =~ $UPPER_RE ]]; then
            kw="${BASH_REMATCH[1]}"
            emit_err "decision-scope" $((i+1)) "RFC 2119 keyword '$kw' outside Decision Statement (Decision SPEC)"
        fi
    done
fi

# ---------- Citation-prefix audit ----------
content_heavy_title() {
    local t="$1"
    case "$t" in
        *"Problem"*|*"Substance Citations"*|*"Authority Map"*|*"Code/Docs Reality Check"*|\
        *"Domain Model"*|*"Acceptance Criteria"*|*"Constraints"*|*"Current System Facts"*|\
        *"Decision Criteria"*|*"Candidate Options"*|*"Failure Model"*|*"Trust Boundary"*|\
        *"Observability"*|*"Test Plan"*|*"Test and Validation Matrix"*|*"Migration"*) return 0 ;;
    esac
    return 1
}

CITE_RE='(file://|cmd://|url://|owner://|judgment://owner|judgment://agent-synthesis)'
SUPPRESS_CITE='<!-- lint-ok: no-citation -->'

# Pre-scan: count citation prefixes per section (for inheritance).
declare -a section_cite_counts
for ((idx=0; idx<${#section_starts[@]}; idx++)); do
    cnt=0
    for ((j=section_starts[idx]; j<=section_ends[idx]; j++)); do
        local_line="${LINES[$j]}"
        # Count each prefix occurrence (rough — duplicates within a line
        # count once per regex match limit; sufficient for the >=2 gate).
        if [[ "$local_line" =~ $CITE_RE ]]; then
            cnt=$((cnt + 1))
        fi
    done
    section_cite_counts+=("$cnt")
done

# Editorial cross-reference detection.
# Per SPEC.schema §2.3: section cross-references and editorial framing
# do not require citation. Patterns recognised here are conservative —
# we look for paragraphs whose primary content is an internal section
# reference or a list/table-intro phrase.
is_pure_xref() {
    local buf="$1"
    local trimmed="${buf#"${buf%%[![:space:]]*}"}"
    trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
    # Single-line pure cross-reference patterns (case-insensitive starts).
    case "$trimmed" in
        [Ss]ee\ §*|\
        [Pp]er\ §*|\
        [Mm]irrors\ §*|\
        [Mm]aps\ to\ §*|\
        [Pp]er\ §[0-9]*|\
        "Per the table above"*|\
        "The following sections"*|"The following entities"*|\
        "Each criterion"*|"Each row"*|"Each Acceptance Criterion"*|\
        "Each box maps to"*) return 0 ;;
    esac
    # Short paragraph that contains "§<number>" as a clear cross-reference
    # and otherwise lacks unique fact markers (no quotes, no path).
    if [[ "$trimmed" =~ §[0-9]+ ]]; then
        # Length heuristic: ≤ 200 chars, no quotes, no /-path.
        if (( ${#trimmed} <= 220 )) && [[ "$trimmed" != *'"'* ]] && [[ ! "$trimmed" =~ /[A-Za-z0-9._-]+/ ]]; then
            # Phrase-level imperative detector — only treat as xref when the
            # paragraph "is about" the cross-reference, not when it asserts
            # an external fact AND happens to mention §N.
            case "$trimmed" in
                *"is specified in §"*|*"specified in §"*|\
                *"defined in §"*|*"defined per §"*|\
                *"per §"*|*"Per §"*|\
                *"see §"*|*"See §"*|\
                *"in §"*"Test"*|*"in §"*"Matrix"*|\
                *"§"*"MUST have"*|*"§"*"MUST be"*|\
                "Mirrors §"*|"Maps to §"*|\
                *"of §"*|\
                *"states "*"§"*|\
                *"listed in §"*|*"described in §"*|\
                *"applies to §"*|*"automate "*"§"*|\
                *"verified manually"*"§"*) return 0 ;;
            esac
        fi
    fi
    return 1
}

# Checkbox / list-item detection.
is_checkbox_item() {
    local buf="$1"
    [[ "$buf" =~ ^[[:space:]]*-[[:space:]]\[[\ x]\] ]]
}

flush_paragraph() {
    local first_line="$1"; shift
    local sec_title="$1"; shift
    local sec_idx="$1"; shift
    local buf="$*"
    [[ -z "${buf// }" ]] && return 0
    # Skip if paragraph contains a citation prefix.
    [[ "$buf" =~ $CITE_RE ]] && return 0
    # Explicit suppression marker.
    [[ "$buf" == *"$SUPPRESS_CITE"* ]] && return 0
    # H1-title region: skip the document title paragraph (e.g. SPEC.md
    # lines 29-36 "Status: Draft v1 / Type: Contract / Purpose: ...").
    if (( h1_para_start >= 0 && first_line-1 >= h1_para_start && first_line-1 <= h1_para_end+1 )); then
        return 0
    fi
    # Block quotes: paragraph begins with `>` — citation lives in the
    # preceding prose.
    [[ "$buf" =~ ^[[:space:]]*\> ]] && return 0
    # Pure cross-references / editorial framing.
    is_pure_xref "$buf" && return 0
    # Whitelisted-by-section sections (per SPEC.schema §2.3 internal-
    # definition / restatement allowances).
    # Sections whose content IS the spec's own design (not external
    # claims) are exempt from per-paragraph citation. The schema doc
    # explicitly lists "Definitions internal to the spec" as exempt.
    case "$sec_title" in
        "Normative Language"|*"Domain Model"*|*"Open Questions"*|*"Completion Report"*|\
        *"Reference Algorithms"*|*"Reversal Plan"*|*"Locks"*|\
        *"Approaches Considered"*|*"Recommendation"*|*"Owner Judgments"*|\
        *"Failure Model"*|*"Observability"*|*"Trust Boundary"*|\
        *"Schema Specification"*|*"Template Specifications"*|\
        *"Skills and Slash Commands"*|*"OPERATING_MODEL"*|\
        *"Pipeline Specification"*|*"Propagation Specification"*) return 0 ;;
    esac
    # Checkbox / criterion items inherit citation from the section's intro
    # (which carries the test-matrix or design citation).
    is_checkbox_item "$buf" && return 0
    local stripped
    stripped="$(strip_code "$buf")"
    # Section-level inheritance (per SPEC.schema §2.3 "restatements" rule,
    # narrowly extended per SPEC §18 self-conformance). Inherit ONLY if:
    #   (a) section already has >= 2 citation prefixes elsewhere, AND
    #   (b) candidate has no UNIQUE fact markers — < 2 numerals AND no
    #       quoted strings AND no fully-qualified path AND no command-
    #       shaped tokens.
    local cite_count=0
    if (( sec_idx >= 0 )); then
        cite_count="${section_cite_counts[$sec_idx]:-0}"
    fi
    if (( cite_count >= 2 )); then
        local n_digits=0 has_quote=0 has_path=0 has_cmd=0
        # Count digit occurrences (cap at 3).
        local rest="$stripped"
        for ((d=0; d<3; d++)); do
            if [[ "$rest" =~ [0-9] ]]; then
                n_digits=$((n_digits+1))
                rest="${rest#*[0-9]}"
            else
                break
            fi
        done
        [[ "$stripped" == *'"'* ]] && has_quote=1
        # Path heuristic: fully-qualified or repo-relative path with /.
        if [[ "$stripped" =~ (^|[[:space:]])/[A-Za-z0-9._/-]+ ]]; then has_path=1; fi
        if [[ "$stripped" =~ (^|[[:space:]])(agents|specs|cmd|bash|grep|test|/|\\.)/[A-Za-z0-9._/-]+ ]]; then has_path=1; fi
        # Command-shaped: `git ...`, `bash ...`, `cmd://...` — note backticks
        # are stripped already, so look for bare verbs at imperative start.
        case "$stripped" in
            "git "*|"bash "*|"grep "*|"diff "*|"test "*) has_cmd=1 ;;
        esac
        if (( n_digits < 2 && has_quote == 0 && has_path == 0 && has_cmd == 0 )); then
            return 0
        fi
    fi
    # Heuristic: fact-bearing if (a) in content-heavy section, OR
    # (b) prose contains a SUBSTANTIAL double-quoted string (≥ 25 chars
    # of inner content) — short quoted strings are typically term
    # definitions ("subagent-executable", "verifiable"), not verbatim
    # citations. Digits alone are too noisy outside content-heavy
    # sections (numbered list markers, internal-§ refs, version
    # numbers in editorial prose).
    local is_fact=0
    content_heavy_title "$sec_title" && is_fact=1
    if [[ "$stripped" =~ \"([^\"]{25,})\" ]]; then is_fact=1; fi
    (( is_fact )) || return 0
    # Skip pseudocode-like lines.
    [[ "$buf" =~ ^[[:space:]]*(function|return|if|for|while|case|switch|=|\#) ]] && return 0
    emit_err "citation" "$first_line" "fact-bearing paragraph lacks citation prefix"
}

para_buf=""
para_first=0
in_fence=0
cur_sec="(preamble)"
cur_sec_idx=-1
for ((i=fm_end; i<total_lines; i++)); do
    line="${LINES[$i]}"
    if [[ "$line" =~ ^\`\`\` ]]; then
        if [[ -n "$para_buf" ]]; then
            flush_paragraph "$para_first" "$cur_sec" "$cur_sec_idx" "$para_buf"
            para_buf=""; para_first=0
        fi
        in_fence=$((1 - in_fence))
        continue
    fi
    (( in_fence )) && continue
    if [[ "$line" =~ ^##[[:space:]](.+)$ ]]; then
        if [[ -n "$para_buf" ]]; then
            flush_paragraph "$para_first" "$cur_sec" "$cur_sec_idx" "$para_buf"
            para_buf=""; para_first=0
        fi
        cur_sec="${BASH_REMATCH[1]}"
        # Update section index.
        cur_sec_idx=-1
        for ((s=0; s<${#section_starts[@]}; s++)); do
            if (( i == section_starts[s] )); then cur_sec_idx=$s; break; fi
        done
        continue
    fi
    [[ "$line" =~ ^# ]] && continue
    [[ "$line" =~ ^\| ]] && continue
    if [[ -z "${line// }" ]]; then
        if [[ -n "$para_buf" ]]; then
            flush_paragraph "$para_first" "$cur_sec" "$cur_sec_idx" "$para_buf"
            para_buf=""; para_first=0
        fi
        continue
    fi
    # List-item boundary: lines starting with "- ", "* ", or "<digit>+. "
    # at column 0 begin a new logical paragraph (markdown list semantics).
    # Indented continuations of the previous item still join.
    is_list_marker=0
    if [[ "$line" =~ ^(-[[:space:]]|\*[[:space:]]|[0-9]+\.[[:space:]]) ]]; then
        is_list_marker=1
    fi
    if (( is_list_marker )) && [[ -n "$para_buf" ]]; then
        flush_paragraph "$para_first" "$cur_sec" "$cur_sec_idx" "$para_buf"
        para_buf=""; para_first=0
    fi
    if [[ -z "$para_buf" ]]; then
        para_first=$((i+1))
        para_buf="$line"
    else
        para_buf="$para_buf $line"
    fi
done
[[ -n "$para_buf" ]] && flush_paragraph "$para_first" "$cur_sec" "$cur_sec_idx" "$para_buf"

# ---------- Summary ----------
n_sections=${#observed_titles[@]}
n_cites=0
for prefix in 'file://' 'cmd://' 'url://' 'owner://' 'judgment://owner' 'judgment://agent-synthesis'; do
    c=$(grep -c -F -- "$prefix" "$TARGET" || true)
    n_cites=$((n_cites + c))
done
n_lc=0
for kw in must should may shall required recommended optional; do
    c=$(grep -c -w -E -- "(^|[^A-Za-z\`])$kw([^A-Za-z\`]|\$)" "$TARGET" || true)
    n_lc=$((n_lc + c))
done

printf '== lint-spec.sh summary ==\n'
printf 'target:                %s\n' "$TARGET"
printf 'artefact / type:       %s / %s\n' "$ARTEFACT" "${TYPE:-<unset>}"
printf 'sections (top-level):  %d\n' "$n_sections"
printf 'citation-prefix hits:  %d\n' "$n_cites"
printf 'lowercase 2119 hits:   %d (advisory only)\n' "$n_lc"
printf 'errors:                %d\n' "${#errors[@]}"
printf 'warnings:              %d\n' "${#warnings[@]}"

if (( ${#errors[@]} > 0 )); then exit 1; fi
if (( ${#warnings[@]} > 0 )); then exit 2; fi
exit 0

# Expected:
#   lint-spec.sh good-task.md           -> exit 0
#   lint-spec.sh bad-uncited.md         -> exit 1
#   lint-spec.sh bad-missing-section.md -> exit 1
