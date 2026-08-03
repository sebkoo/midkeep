#!/usr/bin/env bash
#
# teeth.sh — INV-9: prove each gate fails on a planted defect.
#
# Three assertions per case, in a git worktree under a temp directory and never
# in the checkout:
#
#   1. the clean tree exits 0
#   2. the planted defect exits exactly 1 — a 2 means the gate broke, not that
#      it caught something — and stdout carries the expected findings
#   3. the worktree is removed either way
#
# Assertion 1 runs per case, not once per gate. A gate that fires on everything
# and a gate that fires on the defect are indistinguishable without it.
#
# Two groups, reported separately: ten plant cases — at least one per
# invariant a gate claims, two of them for INV-13's two clauses, plus the one
# gate-format case that claims none — and one contract case, which tests a
# behaviour of a script rather than a property of a tree. Neither number
# implies the other's coverage.
#
# This does not source lib/contract.sh. teeth.sh needs its own EXIT trap for
# worktree cleanup, and contract.sh documents that a gate installing its own
# trap replaces the one cleaning up the findings tally.

set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && cd .. && pwd)" || exit 2
cd "$REPO" || exit 2

TEETH_WORKTREE=""
FAILURES=0
PLANT_CASES=0
CONTRACT_CASES=0

# Installed before any worktree exists, so a plant that fails, a gate that
# dies, an assertion that aborts and a Ctrl-C all land in the same cleanup.
cleanup() {
    cd "$REPO" 2>/dev/null || true
    if [ -n "${TEETH_WORKTREE:-}" ] && [ -d "$TEETH_WORKTREE" ]; then
        git worktree remove --force "$TEETH_WORKTREE" > /dev/null 2>&1
    fi
    git worktree prune > /dev/null 2>&1
    TEETH_WORKTREE=""
}
trap cleanup EXIT

fail() {
    printf '  FAIL  %s\n' "$*"
    FAILURES=$((FAILURES + 1))
}

pass() {
    printf '  ok    %s\n' "$*"
}

# Detached, never a branch name: plant-ai-trailer.sh commits inside the
# worktree, and on a branch that either fails as already checked out or moves
# main. Detached leaves a dangling commit that remove --force and prune drop.
make_worktree() {
    TEETH_WORKTREE="$(mktemp -d "${TMPDIR:-/tmp}/teeth.XXXXXX")" || return 1
    rmdir "$TEETH_WORKTREE" || return 1
    git worktree add --detach "$TEETH_WORKTREE" HEAD > /dev/null 2>&1 || return 1
    # macOS resolves /var/folders to /private/var/folders, so mktemp's answer
    # and the worktree's own pwd are two spellings of one directory. Resolved
    # once here rather than in each plant, so nothing downstream compares them.
    TEETH_WORKTREE="$(cd "$TEETH_WORKTREE" && pwd -P)" || return 1
    # Only teeth.sh writes this. Every plant requires it, so a worktree of this
    # repository that someone is working in is refused like the main tree.
    : > "$TEETH_WORKTREE/.teeth-worktree"
}

# The gate under test is the committed copy, run from inside the worktree. The
# plant is invoked from the checkout, because a plant is the instrument rather
# than the subject.
run_plant_case() {  # NAME INVARIANT GATE PLANT PATH_PATTERN [EXPECTED]
    local name="$1" inv="$2" gate="$3" plant="$4" pattern="$5"
    local expected="${6:-1}"
    local out rc got

    PLANT_CASES=$((PLANT_CASES + 1))

    make_worktree || {
        fail "$name [$inv]: could not create a worktree"
        return
    }

    out="$(cd "$TEETH_WORKTREE" && bash "$TEETH_WORKTREE/scripts/gates/$gate" 2>/dev/null)"
    rc=$?
    if [ "$rc" -ne 0 ]; then
        fail "$name [$inv]: clean tree gave $gate exit $rc, expected 0"
        cleanup
        return
    fi

    if ! TEETH_WORKTREE="$TEETH_WORKTREE" bash "$REPO/scripts/gates/teeth/$plant" > /dev/null 2>&1; then
        fail "$name [$inv]: $plant refused or failed to plant"
        cleanup
        return
    fi

    out="$(cd "$TEETH_WORKTREE" && bash "$TEETH_WORKTREE/scripts/gates/$gate" 2>/dev/null)"
    rc=$?

    if [ "$pattern" = '*' ]; then
        got="$(printf '%s\n' "$out" | grep -c .)"
    else
        got="$(printf '%s\n' "$out" | grep -c "^$pattern:")"
    fi

    if [ "$rc" -ne 1 ]; then
        fail "$name [$inv]: planted tree gave $gate exit $rc, expected exactly 1"
    elif [ "$got" -ne "$expected" ]; then
        fail "$name [$inv]: $got finding(s) matching $pattern, expected $expected"
    else
        pass "$name [$inv]: $gate quiet when clean, $got finding(s) when planted"
    fi

    cleanup
}

# Not a defect anyone can plant, because it is a behaviour of a script rather
# than a property of a tree. A range that resolves and contains nothing is not
# a clean history: on a push to the default branch HEAD and origin/main are the
# same commit, so a gate that trusts its range inspects nothing and reports
# green.
run_contract_case() {
    local err first
    CONTRACT_CASES=$((CONTRACT_CASES + 1))

    make_worktree || {
        fail "empty-range fallback: could not create a worktree"
        return
    }

    err="$(cd "$TEETH_WORKTREE" \
        && GATE_RANGE=HEAD..HEAD bash "$TEETH_WORKTREE/scripts/gates/gate-hygiene.sh" 2>&1 > /dev/null)"
    first="$(printf '%s\n' "$err" | head -1)"

    if printf '%s' "$first" | grep -q 'resolved empty, fell back to all of HEAD' \
        && printf '%s' "$first" | grep -qE 'over HEAD, [1-9][0-9]* commits'; then
        pass "empty-range fallback: $first"
    else
        fail "empty-range fallback: first line did not show the fallback: $first"
    fi

    cleanup
}

printf 'teeth: plant cases\n'
run_plant_case plant-lang-mode           INV-1  gate-arch.sh     plant-lang-mode.sh           Package.swift
run_plant_case plant-unchecked-sendable  INV-2  gate-hygiene.sh  plant-unchecked-sendable.sh  Sources/MidkeepKit/Placeholder.swift
run_plant_case plant-ui-in-kit           INV-3  gate-arch.sh     plant-ui-in-kit.sh           Sources/MidkeepKit/Placeholder.swift
run_plant_case plant-force-unwrap        INV-4  gate-hygiene.sh  plant-force-unwrap.sh        Sources/MidkeepKit/Placeholder.swift
run_plant_case plant-warning             INV-5  gate-build.sh    plant-warning.sh             Sources/MidkeepKit/Placeholder.swift
run_plant_case plant-skipped-test        INV-7  gate-test.sh     plant-skipped-test.sh        Tests/MidkeepKitTests/PlaceholderTests.swift
# The INV-8 finding is keyed by commit sha rather than a file path, so this
# case counts every finding instead of those matching one path.
run_plant_case plant-ai-trailer          INV-8  gate-hygiene.sh  plant-ai-trailer.sh          '*'
run_plant_case plant-runner-label        INV-13 gate-runners.sh  plant-runner-label.sh        .github/workflows/planted-large.yml
run_plant_case plant-macos-no-marker     INV-13 gate-runners.sh  plant-macos-no-marker.sh     .github/workflows/planted-macos.yml
run_plant_case plant-bad-format          format gate-format.sh   plant-bad-format.sh          Sources/MidkeepKit/Placeholder.swift

printf '\nteeth: contract case\n'
run_contract_case

printf '\nplant cases %s, contract cases %s, failures %s\n' \
    "$PLANT_CASES" "$CONTRACT_CASES" "$FAILURES"

[ "$FAILURES" -eq 0 ] || exit 1
exit 0
