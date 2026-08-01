#!/usr/bin/env bash
#
# plant-bad-format.sh — against gate-format, which claims no numbered
# invariant.
#
# Breaks the `indentation` rule this repository chose and nothing else, so a
# finding means the committed criterion was enforced rather than that the
# formatter happened to dislike something. A plant that violates whatever the
# toolchain objects to proves the formatter runs, which was never in doubt.

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

FILE=Sources/MidkeepKit/Placeholder.swift
ORIGINAL='    static let schemaVersion = 1'
PLANTED='  static let schemaVersion = 1'

grep -qxF "$ORIGINAL" "$FILE" || {
    echo "plant-bad-format: the four-space line is not in $FILE" >&2
    exit 2
}

awk -v o="$ORIGINAL" -v p="$PLANTED" '{ if ($0 == o) print p; else print }' \
    "$FILE" > "$FILE.planted" && mv "$FILE.planted" "$FILE"

grep -qxF "$PLANTED" "$FILE" || {
    echo 'plant-bad-format: the two-space indent did not arrive' >&2
    exit 2
}
grep -qxF "$ORIGINAL" "$FILE" && {
    echo 'plant-bad-format: the four-space line is still present' >&2
    exit 2
}

echo 'planted: schemaVersion indented two spaces against a four-space rule'
