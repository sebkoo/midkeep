#!/usr/bin/env bash
#
# plant-app-import.sh — INV-3's App-shell clause, against gate-arch.
#
# Writes an App/ file importing UIKit, which the App allowlist
# (SwiftUI|MidkeepApp) does not admit. UIKit rather than a nonsense module
# on purpose: it is the import someone would actually reach for, and the
# file's SwiftUI-adjacent shape makes the allowed imports the near-miss —
# the same convention plant-force-unwrap.sh uses.
#
# The import is carried as a literal, the way plant-unchecked-sendable.sh
# carries its attribute. scripts/gates/teeth/ is outside every gate's scan
# by construction, so the literal cannot trip the gate in the checkout.

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

FILE=App/Planted.swift
[ -d App ] || {
    echo 'plant-app-import: App/ missing from the worktree' >&2
    exit 2
}
[ ! -e "$FILE" ] || {
    echo "plant-app-import: $FILE already exists" >&2
    exit 2
}

cat > "$FILE" <<'SWIFT'
// A teeth fixture. It exists only inside a teeth worktree; the UIKit import
// is the planted defect, and the SwiftUI import beside it is the allowed
// near-miss that must stay quiet.
import SwiftUI
import UIKit

struct Planted {}
SWIFT

[ "$(grep -c '^import ' "$FILE")" -eq 2 ] || {
    echo 'plant-app-import: expected exactly two import lines' >&2
    exit 2
}
grep -q '^import UIKit$' "$FILE" || {
    echo 'plant-app-import: the UIKit import was lost' >&2
    exit 2
}

echo 'planted: an App/ file imports UIKit'
