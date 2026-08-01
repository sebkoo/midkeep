#!/usr/bin/env bash
#
# plant-ai-trailer.sh — INV-8, against gate-hygiene.
#
# Written and watched first, before any other plant existed. The commit
# sequence lands all eight together and preserves no evidence of that order, so
# Results records it.

# An identity check, not a presence check. A guard that only tests whether the
# variable is set would happily plant a defect in the live repository if
# TEETH_WORKTREE pointed at it. A linked worktree's --absolute-git-dir sits
# under .git/worktrees/; the main working tree's equals --git-common-dir.
[ -n "${TEETH_WORKTREE:-}" ] || {
    echo 'refusing to plant: TEETH_WORKTREE is not set' >&2
    exit 2
}
_gitdir="$(git -C "$TEETH_WORKTREE" rev-parse --absolute-git-dir 2>/dev/null)" || {
    echo "refusing to plant: $TEETH_WORKTREE is not a git worktree" >&2
    exit 2
}
# Only teeth.sh writes this marker, so a worktree of this repository that
# someone is actually working in is refused as firmly as the main tree.
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

before="$(git rev-list --count HEAD)"

# core.hooksPath is repository configuration and a worktree shares it, so the
# commit-msg hook fires here and would reject the very trailer this plant
# exists to create.
#
# Bypassed for exactly one invocation with `-c core.hooksPath=/dev/null`. Not
# `--no-verify`, which settings.json denies. Not by unsetting the config, which
# would silently disarm the hook for everything afterwards. This is also the
# clearest demonstration of why settings.json is not the enforcement: a deny
# rule stops an agent typing a command, and nothing stops a script doing the
# same thing another way.
git -c core.hooksPath=/dev/null commit -q --allow-empty -F - <<'MSG' || exit 2
chore: planted commit for the INV-8 teeth case

Co-Authored-By: Claude <noreply@anthropic.com>
MSG

# Assert the plant landed and is the defect it claims to be, not merely that
# something changed. A plant that plants the wrong thing makes the harness
# report that a gate has teeth it does not have.
after="$(git rev-list --count HEAD)"
[ "$after" -eq "$((before + 1))" ] || {
    echo "plant-ai-trailer: commit did not land ($before -> $after)" >&2
    exit 2
}

git log -1 --format='%B' | grep -qiE '^co-authored-by:.*claude' || {
    echo 'plant-ai-trailer: the trailer is not in the recorded message' >&2
    exit 2
}

# And that the hook was bypassed for this one command only.
[ "$(git config --get core.hooksPath)" = ".githooks" ] || {
    echo 'plant-ai-trailer: core.hooksPath was left disarmed' >&2
    exit 2
}

echo "planted: commit $(git rev-parse --short HEAD) carries an attribution trailer"
