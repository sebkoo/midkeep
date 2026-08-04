#!/usr/bin/env bash
#
# plant-hostpath.sh — INV-14, against gate-hostpath.
#
# Writes a docs file carrying three lines: a real-shaped fabricated path
# that must fire, the bare `/Users/` form that must not — the negative
# case the record demands, because without it `+` and `*` are
# indistinguishable from a green run — and a `/Users/runner/` path that
# must not, which is the carve-out being exercised in the same commit that
# lands it. The expected finding count is exactly 1: a gate that fires on
# any of the quiet lines fails this case as surely as one that misses the
# control.
#
# The control is carried as a literal, the way plant-unchecked-sendable.sh
# carries its attribute, rather than assembled from fragments to dodge the
# pattern — the record rejects assembly by name. The account name in it is
# fabricated; scripts/gates/teeth/ is outside the gate's scope by
# construction, which is what makes the literal safe to commit.

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

FILE=docs/planted-hostpath.md
[ ! -e "$FILE" ] || {
    echo "plant-hostpath: $FILE already exists" >&2
    exit 2
}
[ -d docs ] || {
    echo 'plant-hostpath: docs/ missing from the worktree' >&2
    exit 2
}

cat > "$FILE" <<'MD'
A teeth fixture. It exists only inside a teeth worktree. One line below is
the planted defect; the other two must stay quiet, and staying quiet is
what they prove.

The control, real-shaped and fabricated: /Users/alice/dev/midkeep/run.log

The bare form, which the segment class must ignore: /Users/ and nothing.

The carve-out, exercised: /Users/runner/work/_temp/probe.log stays quiet.
MD

grep -q '/Users/alice/dev/midkeep/run.log' "$FILE" || {
    echo 'plant-hostpath: the control path was lost' >&2
    exit 2
}
grep -q '/Users/runner/work' "$FILE" || {
    echo 'plant-hostpath: the carve-out line was lost' >&2
    exit 2
}
grep -qE '/Users/ and nothing' "$FILE" || {
    echo 'plant-hostpath: the bare-form line was lost' >&2
    exit 2
}

echo 'planted: a docs file carries one real-shaped host path and two quiet forms'
