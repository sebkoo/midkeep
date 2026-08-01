#!/usr/bin/env bash
#
# plant-force-unwrap.sh — INV-4, against gate-hygiene.
#
# Plants one real force unwrap alongside each near-miss the check has to
# survive: `!=`, a prefix `!` on a boolean, and `\(x!)` inside a string
# literal. The case asserts exactly one finding rather than a non-zero exit, so
# the exclusions are proved on those forms and not merely asserted.
#
# What this does not prove is stated in the gate and in ROADMAP: a line-level
# check cannot find Swift's literal boundaries in general.

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

func plantedForceUnwrap() {
    let maybe: Int? = 1
    let notEqual = 1 != 2
    let negated = !notEqual
    let interpolated = "value \(maybe!)"
    let real = maybe!
    _ = (negated, interpolated, real)
}
SWIFT

# Assert all four shapes arrived: one real unwrap and three near-misses.
[ "$(grep -c 'let real = maybe!$' "$FILE")" -eq 1 ] || {
    echo 'plant-force-unwrap: the real force unwrap did not arrive' >&2
    exit 2
}
[ "$(grep -c '1 != 2' "$FILE")" -eq 1 ] || {
    echo 'plant-force-unwrap: the != near-miss did not arrive' >&2
    exit 2
}
[ "$(grep -c '= !notEqual' "$FILE")" -eq 1 ] || {
    echo 'plant-force-unwrap: the prefix ! near-miss did not arrive' >&2
    exit 2
}
[ "$(grep -cF 'value \(maybe!)' "$FILE")" -eq 1 ] || {
    echo 'plant-force-unwrap: the interpolation near-miss did not arrive' >&2
    exit 2
}
grep -q 'static let schemaVersion = 1' "$FILE" || {
    echo 'plant-force-unwrap: the original member was lost' >&2
    exit 2
}

echo 'planted: one force unwrap beside three near-misses'
