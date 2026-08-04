#!/usr/bin/env bash
#
# plant-skipped-test.sh — INV-7, against gate-test.
#
# Exercises the scanning half of gate-test. The running half — a failing
# assertion — has no plant, and is recorded in ROADMAP under Known holes beside
# INV-1's positive direction.
#
# The trait follows the display name. `@Test(.disabled("..."), "name")` does
# not compile, and an uncompilable plant makes the gate fire off a compile
# error rather than off the skip scan, passing the case for the wrong reason.
#
# Self-contained since 2026-08-04: writes its own planted test file instead
# of editing a feature test, whose rename had silenced six plants at once.
# The mechanism and the repair are in ROADMAP → Findings.

[ -n "${TEETH_WORKTREE:-}" ] || {
    echo 'refusing to plant: TEETH_WORKTREE is not set' >&2
    exit 2
}
_gitdir="$(git -C "$TEETH_WORKTREE" rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "refusing to plant: $TEETH_WORKTREE is not a git worktree" >&2
    exit 2
}
[ -f "$TEETH_WORKTREE/.teeth-worktree" ] || {
    echo "refusing to plant: $TEETH_WORKTREE carries no teeth marker" >&2
    exit 2
}
_common="$(git -C "$TEETH_WORKTREE" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)"
[ "$_gitdir" != "$_common" ] || {
    echo "refusing to plant: $TEETH_WORKTREE is the main working tree" >&2
    exit 2
}

set -uo pipefail
cd "$TEETH_WORKTREE" || exit 2

FILE=Tests/MidkeepKitTests/PlantedDefectTests.swift
[ ! -e "$FILE" ] || {
    echo "plant-skipped-test: $FILE already exists" >&2
    exit 2
}

cat > "$FILE" <<'SWIFT'
import Testing

/// Planted by the teeth harness. Never present in a checkout.
@Test("planted disabled test", .disabled("planted"))
func plantedDisabledTest() {
    #expect(Bool(true))
}
SWIFT

[ "$(grep -c '\.disabled(' "$FILE")" -eq 1 ] || {
    echo 'plant-skipped-test: the disabled trait did not arrive' >&2
    exit 2
}

echo 'planted: a disabled test'
