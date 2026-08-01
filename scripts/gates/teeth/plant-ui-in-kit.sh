#!/usr/bin/env bash
#
# plant-ui-in-kit.sh — INV-3, against gate-arch.

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
before="$(wc -l < "$FILE" | tr -d ' ')"

grep -q '^import ' "$FILE" && {
    echo "plant-ui-in-kit: $FILE already imports something" >&2
    exit 2
}

printf 'import SwiftUI\n\n' | cat - "$FILE" > "$FILE.planted" \
    && mv "$FILE.planted" "$FILE"

after="$(wc -l < "$FILE" | tr -d ' ')"

grep -qE '^import SwiftUI$' "$FILE" || {
    echo 'plant-ui-in-kit: the import did not arrive' >&2
    exit 2
}
[ "$after" -eq "$((before + 2))" ] || {
    echo "plant-ui-in-kit: unexpected line count ($before -> $after)" >&2
    exit 2
}
grep -q 'static let schemaVersion = 1' "$FILE" || {
    echo 'plant-ui-in-kit: the original member was lost' >&2
    exit 2
}

echo 'planted: MidkeepKit imports SwiftUI'
