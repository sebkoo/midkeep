#!/usr/bin/env bash
#
# plant-warning.sh — INV-5, against gate-build.
#
# An unused immutable binding. Under -Xswiftc -warnings-as-errors this is a
# build failure, which is the mechanism INV-5 rests on.

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

cat >> "$FILE" <<'SWIFT'

func plantedUnusedLocal() {
    let unused = 1
}
SWIFT

[ "$(grep -c 'let unused = 1' "$FILE")" -eq 1 ] || {
    echo 'plant-warning: the unused binding did not arrive' >&2
    exit 2
}
grep -q 'static let schemaVersion = 1' "$FILE" || {
    echo 'plant-warning: the original member was lost' >&2
    exit 2
}

echo 'planted: an unused immutable binding in MidkeepKit'
