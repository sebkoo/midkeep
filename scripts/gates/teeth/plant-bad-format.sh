#!/usr/bin/env bash
#
# plant-bad-format.sh — against gate-format, which claims no numbered
# invariant.
#
# Breaks the `indentation` rule this repository chose and nothing else, so a
# finding means the committed criterion was enforced rather than that the
# formatter happened to dislike something. A plant that violates whatever the
# toolchain objects to proves the formatter runs, which was never in doubt.
#
# Self-contained since 2026-08-04: writes its own planted file instead of
# editing a feature file, whose rename had silenced six plants at once. The
# mechanism and the repair are in ROADMAP → Findings. The planted file is
# formatted to the committed rules except one two-space indent, so the
# case's expected count stays exactly 1.

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
    echo "plant-bad-format: $FILE already exists" >&2
    exit 2
}

cat > "$FILE" <<'SWIFT'
/// Planted by the teeth harness. Never present in a checkout.
enum PlantedBadFormat {
  static let plantedTwoSpaceIndent = 1
}
SWIFT

grep -qxF '  static let plantedTwoSpaceIndent = 1' "$FILE" || {
    echo 'plant-bad-format: the two-space indent did not arrive' >&2
    exit 2
}

echo 'planted: one member indented two spaces against a four-space rule'
