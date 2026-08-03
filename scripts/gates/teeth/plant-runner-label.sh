#!/usr/bin/env bash
#
# plant-runner-label.sh — INV-13 clause 1, against gate-runners.
#
# Writes a schema-valid workflow whose one job claims a large-runner label.
# The label is ubuntu-flavoured on purpose: a macos-flavoured one was
# measured surviving a gate with the allowlist deleted, because the marker
# clause fired on `macos-*` at the same path and the case counts findings
# by path — a plant that passes either way proves neither clause. An
# ubuntu large label is invisible to the marker clause, so this plant
# lands only while the allowlist is alive.
#
# The label is carried as a literal, the way plant-unchecked-sendable.sh
# carries its attribute: a plant whose defect the gate cannot match lands
# something other than what it names. scripts/gates/teeth/ is outside every
# gate's scan by construction, so the literal cannot trip the gate in the
# checkout.

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

FILE=.github/workflows/planted-large.yml
[ ! -e "$FILE" ] || {
    echo "plant-runner-label: $FILE already exists" >&2
    exit 2
}
[ -f .github/workflows/gates.yml ] || {
    echo 'plant-runner-label: gates.yml missing from the worktree' >&2
    exit 2
}

cat > "$FILE" <<'YAML'
# A teeth fixture. It exists only inside a teeth worktree; the workflow is
# schema-valid on purpose and its runs-on label is the planted defect.
name: planted-large
on: workflow_dispatch
jobs:
  planted:
    runs-on: ubuntu-latest-xlarge
    steps:
      - run: echo planted
YAML

[ "$(grep -c 'runs-on:' "$FILE")" -eq 1 ] || {
    echo 'plant-runner-label: expected exactly one runs-on line' >&2
    exit 2
}
grep -q 'ubuntu-latest-xlarge' "$FILE" || {
    echo 'plant-runner-label: the large-runner label was lost' >&2
    exit 2
}

echo 'planted: a workflow claims a large-runner label'
