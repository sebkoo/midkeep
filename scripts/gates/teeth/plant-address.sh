#!/usr/bin/env bash
#
# plant-address.sh — INV-15, against gate-address.
#
# Writes a docs file carrying one fabricated personal address that must
# fire — the gmail control the record names — and two reserved-TLD
# addresses that must not: `.test` and `.localhost`, the two exclusion
# suffixes with no coverage in the tree's own text, so this fixture is the
# one place they are ever watched excluding something. The other four
# exclusion classes are exercised by the clean-tree half of this very
# case: the scope holds twelve excluded tokens, and the gate exiting 0
# there is the positive control for all of them. Expected finding count
# is exactly 1.
#
# The control's local part names this harness, which makes the address
# self-describing and its registration vanishingly unlikely; it is carried
# as a literal because scripts/gates/teeth/ is outside the gate's scope by
# construction, the same argument as every plant since the first.

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

FILE=docs/planted-address.md
[ ! -e "$FILE" ] || {
    echo "plant-address: $FILE already exists" >&2
    exit 2
}
[ -d docs ] || {
    echo 'plant-address: docs/ missing from the worktree' >&2
    exit 2
}

cat > "$FILE" <<'MD'
A teeth fixture. It exists only inside a teeth worktree. One line below is
the planted defect; the reserved pair must stay quiet, and staying quiet
is what they prove.

The control, fabricated: midkeep.teeth.plant.control@gmail.com must fire.

Reserved and quiet: ci@harness.test and dev@box.localhost are excluded.
MD

grep -q 'midkeep.teeth.plant.control@gmail.com' "$FILE" || {
    echo 'plant-address: the control address was lost' >&2
    exit 2
}
grep -q 'ci@harness.test' "$FILE" || {
    echo 'plant-address: the .test line was lost' >&2
    exit 2
}
grep -q 'dev@box.localhost' "$FILE" || {
    echo 'plant-address: the .localhost line was lost' >&2
    exit 2
}

echo 'planted: a docs file carries one personal-shaped address and two reserved ones'
