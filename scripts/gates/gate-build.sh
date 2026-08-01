#!/usr/bin/env bash
#
# gate-build.sh — INV-5: warning-free debug and release build, no suppression.
#
# The debug pass adds --build-tests. `swift build` does not build test targets,
# and gate-test's invocation passes no -warnings-as-errors, so without this a
# warning in a test was invisible to the invariant that forbids warnings. The
# release pass does not add it: a release build of test targets is not a
# configuration anything ships.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need swift
[ -f Package.swift ] || die_cannot_run "Package.swift not found"

# On macOS $PWD holds the logical path while the compiler emits the physical
# one — /var/folders versus /private/var/folders under a temp directory — so
# both prefixes have to come off. Strip only $PWD and a finding keeps its
# absolute path, and anything counting findings by repo-relative path sees
# none. Found by the teeth harness, which is what it is for.
REPO_PHYSICAL="$(pwd -P)"

note "gate-build: debug --build-tests and release, -Xswiftc -warnings-as-errors"

# -warnings-as-errors is the whole mechanism: it is what makes a warning fail
# the build rather than scroll past. There is no suppression flag anywhere in
# this repository, which is the second half of INV-5.
debug_out="$(swift build --build-tests -Xswiftc -warnings-as-errors 2>&1)"
debug_rc=$?
release_out="$(swift build -c release -Xswiftc -warnings-as-errors 2>&1)"
release_rc=$?

# Both passes are parsed together and deduplicated. The same diagnostic
# reported once per configuration is one defect, not two, and a teeth case
# asserting a single finding would otherwise see two.
diagnostics="$(
    printf '%s\n%s\n' "$debug_out" "$release_out" \
        | grep -E '^[^[:space:]]+:[0-9]+:[0-9]+: (error|warning):' \
        | sort -u
)"

while IFS= read -r line; do
    [ -n "$line" ] || continue

    path="${line%%:*}"
    rest="${line#*:}"
    lineno="${rest%%:*}"
    rest="${rest#*:}"
    rest="${rest#*:}"

    message="${rest# }"
    message="${message#error: }"
    message="${message#warning: }"
    path="${path#"$REPO_PHYSICAL"/}"
    path="${path#"$PWD"/}"

    finding "$path" "$lineno" "INV-5: $message"
done <<< "$diagnostics"

# A failed build with nothing parsed is the toolchain failing rather than the
# source being wrong — a broken install, an unresolvable dependency, a manifest
# that will not evaluate. That is "no verdict", not "found something".
if { [ "$debug_rc" -ne 0 ] || [ "$release_rc" -ne 0 ]; } \
    && [ "$(gate_finding_count)" -eq 0 ]; then
    die_cannot_run "swift build failed with no parsable diagnostics (debug $debug_rc, release $release_rc)"
fi

finish
