#!/usr/bin/env bash
#
# plant-unchecked-sendable.sh — INV-2, against gate-hygiene.
#
# Self-contained since 2026-08-04: writes its own planted file instead of
# appending to a feature file, whose rename had silenced six plants at once.
# The mechanism and the repair are in ROADMAP → Findings; the old
# original-member tripwire retired with the append hazard it guarded.

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

FILE=Sources/MidkeepKit/PlantedDefect.swift
[ ! -e "$FILE" ] || {
    echo "plant-unchecked-sendable: $FILE already exists" >&2
    exit 2
}

cat > "$FILE" <<'SWIFT'
/// Planted by the teeth harness. Never present in a checkout.
struct PlantedOptOut: @unchecked Sendable {}
SWIFT

[ "$(grep -c '@unchecked Sendable' "$FILE")" -eq 1 ] || {
    echo 'plant-unchecked-sendable: expected exactly one opt-out' >&2
    exit 2
}

echo 'planted: MidkeepKit declares an @unchecked Sendable conformance'
