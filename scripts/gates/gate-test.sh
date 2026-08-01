#!/usr/bin/env bash
#
# gate-test.sh — INV-7: no test skipped, disabled or commented out on main.
#
# The skip scan covers both frameworks even though the tree uses only Swift
# Testing, so that a later drift to XCTest does not silently disarm INV-7.
#
# `swift test` builds the test targets and what they depend on, so MidkeepUI
# and MidkeepApp may never be compiled by it. That separation is intended:
# gate-test claims the tests pass, gate-build claims everything compiles
# warning-free in debug and release, and neither substitutes for the other.
# all.sh runs both. A gate that quietly does another gate's work is a gate
# whose green means something other than its name.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need swift
[ -d Tests ] || die_cannot_run "Tests/ not found"

# $PWD is the logical path; the toolchain emits the physical one. Both prefixes
# have to come off or a finding keeps its absolute path. See gate-build.sh.
REPO_PHYSICAL="$(pwd -P)"

note "gate-test: swift test --parallel, plus the INV-7 skip scan"

# --- the skip scan ---------------------------------------------------------
#
# Needs no toolchain and is exact: these markers sit on their own lines.
grep -rnE '\.disabled\(|@Test\(\.disabled|XCTSkip|withKnownIssue|^[[:space:]]*//[[:space:]]*(@Test|func[[:space:]]+test)' \
    Tests \
    | while IFS=: read -r f n _; do
        finding "$f" "$n" "INV-7: test skipped, disabled or commented out"
    done

# --- the run ---------------------------------------------------------------
#
# --parallel governs the XCTest half; Swift Testing parallelises on its own.
test_out="$(swift test --parallel 2>&1)"
test_rc=$?

# swift test reports in three shapes and the gate reads all three, because only
# one of them looks like a compiler diagnostic. Written from captured output
# rather than from memory: a failing Swift Testing expectation produces no line
# beginning with a path at all, so a parser anchored at the start of the line
# sees a failing suite as a toolchain failure and returns 2 for what is plainly
# a finding.
#
#   Swift Testing   ✘ Test "..." recorded an issue at File.swift:8:5: message
#   XCTest          /path/File.swift:8: error: -[Suite test] : message
#   compile error   /path/File.swift:8:5: error: message
#
# The Swift Testing form carries a bare basename, so it is resolved against
# Tests/ into a path a harness can count findings by.
{
    printf '%s\n' "$test_out" \
        | sed -nE 's/.*recorded an issue at ([^[:space:]:]+):([0-9]+):[0-9]+: (.*)/\1	\2	\3/p'
    printf '%s\n' "$test_out" \
        | sed -nE 's/^([^[:space:]:]+):([0-9]+):[0-9]+: (error|warning): (.*)/\1	\2	\4/p'
    printf '%s\n' "$test_out" \
        | sed -nE 's/^([^[:space:]:]+):([0-9]+): (error|warning): (.*)/\1	\2	\4/p'
} | sort -u | while IFS=$'\t' read -r path lineno message; do
    [ -n "$path" ] || continue
    case "$path" in
        /*)
            path="${path#"$REPO_PHYSICAL"/}"
            path="${path#"$PWD"/}"
            ;;
        */*) ;;
        *)
            resolved="$(find Tests -name "$path" -type f 2>/dev/null | head -1)"
            [ -n "$resolved" ] && path="$resolved"
            ;;
    esac
    finding "$path" "$lineno" "INV-7: $message"
done

# A run that failed with nothing parsable is the toolchain failing rather than
# a test failing — the same rule gate-build and gate-format follow, so the
# three agree on where the boundary between 1 and 2 sits.
if [ "$test_rc" -ne 0 ] && [ "$(gate_finding_count)" -eq 0 ]; then
    die_cannot_run "swift test exited $test_rc with no parsable diagnostics"
fi

finish
