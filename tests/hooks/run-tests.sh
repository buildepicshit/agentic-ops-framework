#!/usr/bin/env bash
# Hook test harness. Exits 0 if all pass, 1 on failure.
#
# Each test feeds a synthesized PreToolUse(Bash | Edit) JSON envelope to a
# hook and asserts the exit code (and optionally stderr / stdout content).
#
# All "should block" tests for branch-aware hooks run from a sandbox git
# repo with no main-direct SPEC, so the hook's SPEC walk falls through to
# the block. "Should allow" tests use a sandbox repo that DOES declare
# main-direct, exercising the allow path.

set -u
HOOK_DIR="$(cd "$(dirname "$(readlink -f "$0")")/../../hooks" && pwd)"
FIXTURES="$(cd "$(dirname "$(readlink -f "$0")")/fixtures" && pwd)"
PASS=0; FAIL=0; FAILURES=()

run() {
    local name="$1" hook="$2" expected_exit="$3" json="$4" cwd="${5:-}"
    local actual stderr
    if [ -n "$cwd" ]; then
        stderr=$(cd "$cwd" && printf '%s' "$json" | "$HOOK_DIR/$hook" 2>&1 >/dev/null)
    else
        stderr=$(printf '%s' "$json" | "$HOOK_DIR/$hook" 2>&1 >/dev/null)
    fi
    actual=$?
    if [ "$actual" = "$expected_exit" ]; then
        PASS=$((PASS+1))
        printf 'PASS %-55s [%s]\n' "$name" "$hook"
    else
        FAIL=$((FAIL+1))
        FAILURES+=("$name [$hook]: expected exit $expected_exit, got $actual; stderr=$stderr")
        printf 'FAIL %-55s [%s]: expected %s got %s\n' "$name" "$hook" "$expected_exit" "$actual"
    fi
}

run_stdout() {
    local name="$1" hook="$2" expected_exit="$3" expected_substr="$4" json="$5"
    local actual stdout
    stdout=$(printf '%s' "$json" | "$HOOK_DIR/$hook" 2>/dev/null)
    actual=$?
    if [ "$actual" = "$expected_exit" ] && printf '%s' "$stdout" | grep -qF "$expected_substr"; then
        PASS=$((PASS+1))
        printf 'PASS %-55s [%s]\n' "$name" "$hook"
    else
        FAIL=$((FAIL+1))
        FAILURES+=("$name [$hook]: expected exit $expected_exit + stdout containing '$expected_substr'; got exit $actual")
        printf 'FAIL %-55s [%s]\n' "$name" "$hook"
    fi
}

# --- sandbox repos ---

# SANDBOX_NO_SPEC: git repo on main, no SPEC declaring main-direct.
# Used for "should block" tests of branch-aware hooks.
SANDBOX_NO_SPEC="$(mktemp -d)"
( cd "$SANDBOX_NO_SPEC" \
    && git init -q \
    && git symbolic-ref HEAD refs/heads/main \
    && git -c user.email=t@t -c user.name=t commit -q --allow-empty -m init )

# SANDBOX_MAIN_DIRECT: git repo on main WITH a main-direct SPEC.
# Used for "should allow" tests of branch-aware hooks.
SANDBOX_MAIN_DIRECT="$(mktemp -d)"
( cd "$SANDBOX_MAIN_DIRECT" \
    && git init -q \
    && git symbolic-ref HEAD refs/heads/main \
    && mkdir -p specs/fixture \
    && printf -- '---\nid: fixture\ntype: contract\nstatus: closed\nbranch_policy: main-direct\n---\n' > specs/fixture/SPEC.md \
    && git -c user.email=t@t -c user.name=t add specs/fixture/SPEC.md \
    && git -c user.email=t@t -c user.name=t commit -q -m init )

# NON_GIT: a non-git tmpdir for hooks that bail out when not in a git repo.
NON_GIT="$(mktemp -d)"

trap 'rm -rf "$SANDBOX_NO_SPEC" "$SANDBOX_MAIN_DIRECT" "$NON_GIT"' EXIT

# --- helpers ---

JB() {
    # PreToolUse(Bash) envelope.
    local cmd="$1"
    printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | jq -Rs .)"
}

JE() {
    # PreToolUse(Edit) envelope.
    local file_path="$1"
    printf '{"tool_input":{"file_path":"%s"}}' "$file_path"
}

# --- block-push-to-main.sh ---
run "real push to main blocked"               block-push-to-main.sh   2 "$(JB 'git push origin main')" "$SANDBOX_NO_SPEC"
run "real push to feature branch allowed"     block-push-to-main.sh   0 "$(JB 'git push origin feature/x')"
run "real push -u origin main blocked"        block-push-to-main.sh   2 "$(JB 'git push -u origin main')" "$SANDBOX_NO_SPEC"
run "real push to main-rework allowed"        block-push-to-main.sh   0 "$(JB 'git push origin feature/main-rework')"
run "no push (commit only) allowed"           block-push-to-main.sh   0 "$(JB 'git commit -m "fix bug"')"
run "commit msg mentions git push to main"    block-push-to-main.sh   0 "$(JB 'git commit -m "describe what git push to main does"')"
run "heredoc body mentions git push to main"  block-push-to-main.sh   0 "$(JB $'cat > /tmp/msg <<EOF\nrefuses git push to main\nEOF\ngit commit -F /tmp/msg')"
run "chain: cd && git push origin main"       block-push-to-main.sh   2 "$(JB 'cd /repo && git push origin main')" "$SANDBOX_NO_SPEC"
run "main-direct SPEC allows push to main"    block-push-to-main.sh   0 "$(JB 'git push origin main')" "$SANDBOX_MAIN_DIRECT"
run "main-direct SPEC allows push -u main"    block-push-to-main.sh   0 "$(JB 'git push -u origin main')" "$SANDBOX_MAIN_DIRECT"

# --- block-git-add-all.sh ---
run "real git add . blocked"                  block-git-add-all.sh    2 "$(JB 'git add .')"
run "real git add -A blocked"                 block-git-add-all.sh    2 "$(JB 'git add -A')"
run "git add --all blocked"                   block-git-add-all.sh    2 "$(JB 'git add --all')"
run "git add filename allowed"                block-git-add-all.sh    0 "$(JB 'git add foo.txt')"
run "msg mentions git add . allowed"          block-git-add-all.sh    0 "$(JB 'git commit -m "stop using git add ."')"
run "heredoc with git add ."                  block-git-add-all.sh    0 "$(JB $'cat > /tmp/msg <<EOF\ngit add . is banned\nEOF')"

# --- block-verify-bypass.sh ---
run "real --no-verify on commit blocked"      block-verify-bypass.sh  2 "$(JB 'git commit --no-verify -m "x"')"
run "real --no-gpg-sign on push blocked"      block-verify-bypass.sh  2 "$(JB 'git push --no-gpg-sign')"
run "git log --no-merges allowed"             block-verify-bypass.sh  0 "$(JB 'git log --no-merges')"
run "msg mentions --no-verify"                block-verify-bypass.sh  0 "$(JB 'git commit -m "this hook blocks --no-verify"')"
run "heredoc body with --no-verify"           block-verify-bypass.sh  0 "$(JB $'cat > /tmp/msg <<EOF\nrefuses --no-verify\nEOF\ngit commit -F /tmp/msg')"

# --- block-ai-attribution.sh ---
run "commit -m with Co-Authored-By blocked"   block-ai-attribution.sh 2 "$(JB 'git commit -m "fix\n\nCo-Authored-By: Claude <x>"')"
run "commit -m clean allowed"                 block-ai-attribution.sh 0 "$(JB 'git commit -m "clean message"')"
run "commit -F file with co-author blocked"   block-ai-attribution.sh 2 "$(JB "git commit -F $FIXTURES/msg-with-coauthor.txt")"
run "commit -F file clean allowed"            block-ai-attribution.sh 0 "$(JB "git commit -F $FIXTURES/msg-clean.txt")"
run "non-commit (push) allowed"               block-ai-attribution.sh 0 "$(JB 'git push origin feature/x')"

# --- block-edit-on-main.sh ---
run "edit on main blocked (no main-direct)"   block-edit-on-main.sh   2 "$(JE 'foo.md')" "$SANDBOX_NO_SPEC"
run "edit on main allowed (main-direct SPEC)" block-edit-on-main.sh   0 "$(JE 'foo.md')" "$SANDBOX_MAIN_DIRECT"
run "edit in non-git dir allowed"             block-edit-on-main.sh   0 "$(JE 'foo.md')" "$NON_GIT"

# --- session-start-context.sh (stdout-as-context per Claude Code docs) ---
run_stdout "session-start emits Session-init context header" \
    session-start-context.sh 0 "Session-init context" \
    '{"hook_event_name":"SessionStart"}'
run_stdout "session-start emits Repo: line" \
    session-start-context.sh 0 "Repo:" \
    '{"hook_event_name":"SessionStart"}'
run_stdout "session-start emits Recent commits section" \
    session-start-context.sh 0 "Recent commits" \
    '{"hook_event_name":"SessionStart"}'

# --- verify-reminder.sh ---
run "verify-reminder.sh emits 0 on Stop"      verify-reminder.sh      0 '{"hook_event_name":"Stop"}'

# --- summary ---
printf '\n=== %d pass / %d fail ===\n' "$PASS" "$FAIL"
if [ "$FAIL" -gt 0 ]; then
    printf '\nFailures:\n'
    for line in "${FAILURES[@]}"; do printf '  - %s\n' "$line"; done
    exit 1
fi
exit 0
