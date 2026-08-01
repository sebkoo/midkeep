#!/usr/bin/env bash
#
# plant-lang-mode.sh — INV-1, against gate-arch.
#
# Exercises the negative direction only: an opt-down, which is what happens
# when somebody silences a concurrency error. INV-1's positive direction has a
# gate and no plant, recorded in ROADMAP under Known holes.

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

FILE=Package.swift
ORIGINAL='        .target(name: "MidkeepKit"),'
PLANTED='        .target(name: "MidkeepKit", swiftSettings: [.swiftLanguageMode(.v5)]),'

grep -qF "$ORIGINAL" "$FILE" || {
    echo "plant-lang-mode: the line to replace is not in $FILE" >&2
    exit 2
}

# awk, not `sed -i ''`: BSD sed does not expand \n in a replacement, and a
# plant that mangles a line instead of replacing it still makes a gate fire,
# passing the case for the wrong reason.
awk -v o="$ORIGINAL" -v p="$PLANTED" '{ if ($0 == o) print p; else print }' \
    "$FILE" > "$FILE.planted" && mv "$FILE.planted" "$FILE"

grep -qF "$PLANTED" "$FILE" || {
    echo 'plant-lang-mode: the opt-down did not arrive' >&2
    exit 2
}
grep -qF "$ORIGINAL" "$FILE" && {
    echo 'plant-lang-mode: the original line is still present' >&2
    exit 2
}

echo 'planted: MidkeepKit opts down to .swiftLanguageMode(.v5)'
