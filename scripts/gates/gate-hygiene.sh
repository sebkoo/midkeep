#!/usr/bin/env bash
#
# gate-hygiene.sh — INV-2, INV-4 and INV-8.
#
# INV-2  No @unchecked Sendable, nonisolated(unsafe) or @preconcurrency import
#        in Sources/. Tests may, with `// INV-2-EXEMPT: <reason>`.
# INV-4  No force unwrap or `try!` in Sources/. Tests exempt. PARTIAL: this is
#        a line-level check and cannot see Swift's literal boundaries in the
#        general case. Named in ROADMAP under Known holes.
# INV-8  No AI-attribution trailer in any commit message.
#
# Needs nothing but a checkout and git.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need git
[ -d Sources ] || die_cannot_run "Sources/ not found"

# --- INV-2 -----------------------------------------------------------------
scan_inv2() {  # scan_inv2 DIR EXEMPTIONS_ALLOWED
    local dir="$1" allow="$2"
    [ -d "$dir" ] || return 0
    grep -rnE '@unchecked[[:space:]]+Sendable|nonisolated\(unsafe\)|@preconcurrency[[:space:]]+import' \
        "$dir" \
        | while IFS=: read -r f n rest; do
            if [ "$allow" = yes ]; then
                local prev=""
                [ "$n" -gt 1 ] && prev="$(sed -n "$((n - 1))p" "$f")"
                case "$rest$prev" in
                    *INV-2-EXEMPT:*) continue ;;
                esac
            fi
            finding "$f" "$n" "INV-2: concurrency safety opt-out"
        done
}

scan_inv2 Sources no
scan_inv2 Tests yes

# --- INV-4 -----------------------------------------------------------------
#
# A force unwrap is an identifier, `)` or `]` followed by `!` that is not `!=`.
# String literals and line comments are stripped first, so `\(x!)` inside a
# string and a `!` in prose do not register.
#
# What this cannot do is find Swift's literal boundaries in general: multiline
# strings, raw string delimiters and nested interpolation defeat it. The rule
# is absolute and binds anyone writing here; the check is a heuristic and says
# so. Do not soften the rule to match the tool.
if [ -d Sources ]; then
    find Sources -name '*.swift' -type f \
        | while read -r f; do
            # `]` must come first inside a bracket expression: backslash is not
            # an escape there, so [A-Za-z0-9_)\]] would parse as the set
            # `A-Za-z0-9_)\` followed by a literal `]`, and the check could
            # never fire. It was written that way once and caught by watching
            # it fail to catch a real force unwrap.
            sed -E -e 's/"[^"]*"//g' -e 's://.*::' "$f" \
                | grep -nE '[]A-Za-z0-9_)]!($|[^=])' \
                | while IFS=: read -r n _; do
                    finding "$f" "$n" "INV-4: force unwrap or try!"
                done
        done
fi

# --- INV-8 -----------------------------------------------------------------
#
# The family list is read from the committed hook rather than restated here, so
# a family added to the hook is checked automatically and a family dropped from
# it stops being claimed. It has been retyped wrongly before; it is not retyped
# again.
HOOK=.githooks/commit-msg
[ -f "$HOOK" ] || die_cannot_run "$HOOK not found"
family="$(sed -n "s/^family='\(.*\)'\$/\1/p" "$HOOK")"
[ -n "$family" ] || die_cannot_run "could not read the family list from $HOOK"

# ERE, not BRE. `\|` is a GNU extension and gates.yml runs on a macOS runner
# with BSD grep. The three branches mirror the hook exactly: a bare
# `co-authored` would flag a legitimate human co-author, and a bare
# `generated with` flags this repository's own prose.
AUDIT="^[[:space:]]*co-authored-by:.*(${family})|^[[:space:]]*claude-session:|generated with .*claude code"

if [ -n "${GATE_RANGE:-}" ]; then
    range="$GATE_RANGE"
    origin="GATE_RANGE"
elif git rev-parse --verify -q origin/main >/dev/null 2>&1; then
    range="origin/main..HEAD"
    origin="origin/main..HEAD"
else
    range="HEAD"
    origin="no origin/main, all of HEAD"
fi

count="$(git rev-list --count "$range" 2>/dev/null || printf '0')"

# A range that resolves and contains nothing is not a clean history. On a push
# to the default branch HEAD and origin/main are the same commit, so
# origin/main..HEAD resolves and is empty; without this the gate would inspect
# no message at all and report green.
if [ "$count" -eq 0 ]; then
    range="HEAD"
    origin="$origin resolved empty, fell back to all of HEAD"
    count="$(git rev-list --count HEAD 2>/dev/null || printf '0')"
fi

# First line of output, on stderr. A check whose scope is invisible cannot be
# audited — and stdout is findings only, so a banner there would break every
# teeth case at once.
note "gate-hygiene: INV-8 over $range, $count commits ($origin)"

git rev-list "$range" 2>/dev/null \
    | while read -r sha; do
        if git log -1 --format='%B' "$sha" | grep -qiE "$AUDIT"; then
            finding "$sha" 1 "INV-8: commit message carries an attribution trailer"
        fi
    done

# core.hooksPath is repository configuration a fresh actions/checkout does not
# have, so this would fail on a clean tree in CI. It is therefore verified in
# exactly one place anyone can observe — its own teeth case — and nowhere in
# CI. Recorded in ROADMAP under Known holes.
if [ -n "${CI:-}" ]; then
    note "gate-hygiene: core.hooksPath check skipped under CI"
else
    hooks_path="$(git config --get core.hooksPath || printf '')"
    if [ "$hooks_path" != ".githooks" ]; then
        finding "$HOOK" 1 \
            "INV-8: core.hooksPath is '${hooks_path:-unset}', not .githooks"
    fi
fi

finish
