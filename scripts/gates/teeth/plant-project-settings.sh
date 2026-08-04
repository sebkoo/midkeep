#!/usr/bin/env bash
#
# plant-project-settings.sh — INV-5's readable xcodebuild clause, against
# gate-arch.
#
# Deletes every SWIFT_TREAT_WARNINGS_AS_ERRORS line from the committed app
# project. Deletion rather than degradation, because deletion is the defect
# the clause exists for: one removed line unguards the entire xcodebuild
# path while CI stays green, and the gate's presence check is what makes
# that removal loud. The degraded form (= NO) is caught by the same gate's
# value check and stays covered by the clean-tree half of this case.

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

FILE=Midkeep.xcodeproj/project.pbxproj
[ -f "$FILE" ] || {
    echo "plant-project-settings: $FILE missing from the worktree" >&2
    exit 2
}

before="$(grep -c 'SWIFT_TREAT_WARNINGS_AS_ERRORS' "$FILE")"
[ "$before" -ge 1 ] || {
    echo 'plant-project-settings: nothing to delete — the setting is already absent' >&2
    exit 2
}

# awk rewrite, the same idiom the other in-place plants use — the tree's own
# note on plant-lang-mode.sh records why `sed -i ''` is avoided here.
awk '!/SWIFT_TREAT_WARNINGS_AS_ERRORS/' "$FILE" > "$FILE.planted" \
    && mv "$FILE.planted" "$FILE"

[ "$(grep -c 'SWIFT_TREAT_WARNINGS_AS_ERRORS' "$FILE")" -eq 0 ] || {
    echo 'plant-project-settings: the deletion did not take' >&2
    exit 2
}

echo "planted: SWIFT_TREAT_WARNINGS_AS_ERRORS deleted ($before line(s)) from the app project"
