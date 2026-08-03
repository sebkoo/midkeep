#!/usr/bin/env bash
#
# plant-macos-no-marker.sh — INV-13 clause 2, against gate-runners.
#
# Writes a schema-valid workflow whose one job claims macos-15 — an
# allowlisted label — with no build declaration beside it. Clause 1 passes
# and clause 2 is the single expected finding, which is what proves the two
# clauses fire independently.

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
_common="$(git -C "$TEETH_WORKTREE" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)" || {
    echo "refusing to plant: cannot resolve the common git dir under $TEETH_WORKTREE" >&2
    exit 2
}
# The guard must positively prove worktree-ness; any doubt is a refusal.
# rev-parse hands an option it does not recognise back on stdout with
# status 0, so on a git too old for --path-format either answer would open
# with the flag itself, never equal the other, and wave the main tree
# through. Both answers must be a path, or the plant refuses.
case "$_gitdir" in /*) ;; *)
    echo "refusing to plant: git dir did not resolve to an absolute path" >&2
    exit 2 ;;
esac
case "$_common" in /*) ;; *)
    echo "refusing to plant: common git dir did not resolve to an absolute path" >&2
    exit 2 ;;
esac
[ "$_gitdir" != "$_common" ] || {
    echo "refusing to plant: $TEETH_WORKTREE is the main working tree" >&2
    exit 2
}

set -uo pipefail
cd "$TEETH_WORKTREE" || exit 2

FILE=.github/workflows/planted-macos.yml
[ ! -e "$FILE" ] || {
    echo "plant-macos-no-marker: $FILE already exists" >&2
    exit 2
}
[ -f .github/workflows/gates.yml ] || {
    echo 'plant-macos-no-marker: gates.yml missing from the worktree' >&2
    exit 2
}

cat > "$FILE" <<'YAML'
# A teeth fixture. It exists only inside a teeth worktree; the workflow is
# schema-valid on purpose, its label is allowlisted, and the absent build
# declaration is the planted defect.
name: planted-macos
on: workflow_dispatch
jobs:
  planted:
    runs-on: macos-15
    steps:
      - run: echo planted
YAML

[ "$(grep -c 'runs-on:' "$FILE")" -eq 1 ] || {
    echo 'plant-macos-no-marker: expected exactly one runs-on line' >&2
    exit 2
}
# A finding of absence needs a positive control: the same pattern must be
# watched finding the marker where it is known to exist — the worktree's own
# copy of the gate under test — before its silence on the fixture counts.
grep -q 'INV-13: needs a Swift build' scripts/gates/gate-runners.sh || {
    echo 'plant-macos-no-marker: positive control failed — the marker pattern matches nothing in the gate' >&2
    exit 2
}
! grep -q 'INV-13: needs a Swift build' "$FILE" || {
    echo 'plant-macos-no-marker: the fixture carries the marker it must lack' >&2
    exit 2
}

echo 'planted: a macos job carries no build declaration'
