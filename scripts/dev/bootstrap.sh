#!/usr/bin/env bash
#
# bootstrap.sh — developer and CI setup.
#
# One thing at this stage: point git at the repository's own hook directory,
# idempotently. It gains steps as later units need them; it does not become a
# place where unrelated setup accumulates.
#
# CI calls this for the same reason a developer does, so that any commit a
# workflow makes passes through the commit-msg hook.

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$repo_root"

current="$(git config --get core.hooksPath || true)"

if [ "$current" = ".githooks" ]; then
    printf 'bootstrap: core.hooksPath already .githooks\n'
else
    git config core.hooksPath .githooks
    printf 'bootstrap: core.hooksPath set to .githooks\n'
fi

# git preserves the executable bit, so this matters only for a tree that
# arrived some other way.
chmod +x .githooks/* 2>/dev/null || true

printf 'bootstrap: done\n'
