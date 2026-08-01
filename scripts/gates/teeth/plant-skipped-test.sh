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

FILE=Tests/MidkeepKitTests/PlaceholderTests.swift
ORIGINAL='@Test("Kit placeholder declares schema version 1")'
PLANTED='@Test("Kit placeholder declares schema version 1", .disabled("planted"))'

grep -qF "$ORIGINAL" "$FILE" || {
    echo "plant-skipped-test: the line to replace is not in $FILE" >&2
    exit 2
}

awk -v o="$ORIGINAL" -v p="$PLANTED" '{ if ($0 == o) print p; else print }' \
    "$FILE" > "$FILE.planted" && mv "$FILE.planted" "$FILE"

grep -qF "$PLANTED" "$FILE" || {
    echo 'plant-skipped-test: the disabled trait did not arrive' >&2
    exit 2
}
grep -qF "$ORIGINAL" "$FILE" && {
    echo 'plant-skipped-test: the original line is still present' >&2
    exit 2
}

echo 'planted: the one test is disabled'
