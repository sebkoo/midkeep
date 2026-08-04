#!/usr/bin/env bash
#
# gate-hostpath.sh — INV-14: no absolute host path in committed text.
#
# Pattern: /(Users|home)/[A-Za-z0-9._-]+ — the segment class with `+`,
# never `*`. The two candidates differ by one character and were measured
# disagreeing completely (ROADMAP → Known holes): `+` matched a real-path
# control and none of the placeholder forms then in the tree; `*` matched
# every placeholder as well and would go red on the document recording the
# measurement. The class is the mechanism: `<name>`, `<redacted>` and `…`
# fall outside it, so there is no exemption list to rot, and the gate
# searches for a shape rather than a string — it carries no secret.
#
# One carve-out, which is not an exemption list: /(Users|home)/runner/ is
# the GitHub-hosted runner's home directory, quoted whenever CI output
# enters the record (one occurrence in scope at ROADMAP:424 when this gate
# landed). Each occurrence is removed from the line before the line is
# judged — removed, not skipped, so a line carrying both a runner path and
# a real one still fires on the real one. It requires the trailing slash:
# a bare /Users/runner with nothing after it still fires, the conservative
# direction. The carve-out lands with a plant line exercising it; see
# scripts/gates/teeth/plant-hostpath.sh.
#
# Scope: docs/, CLAUDE.md, README.md, .claude/ — the prose surface where
# the leak class lives, as named directories, the same convention as every
# gate. Files are enumerated with `git ls-files -co --exclude-standard`
# rather than a bare recursive grep, because the invariant governs text
# that can reach a commit: .gitignore documents .claude/settings.local.json
# as a per-machine file, and a finding on an ignored file would be a red
# verdict about text that git will never record. A new untracked docs file
# is still seen — untracked-and-unignored is exactly the pre-commit case.
#
# What this grep cannot see, named rather than implied. A path inside
# scripts/, Sources/ or .github/ — outside the scope, the cost the record
# states. A path wrapped across two lines mid-segment — quoted output is
# pasted at its own length here, which keeps the risk low, not zero. A
# doubled slash — /Users//alice — found by review: the class demands a
# segment character immediately after the slash, so the form passes; the
# same family of hole as the wrapped line, named on the same grounds. A
# Windows path (C:\Users\name). A tilde path (~/...), which is out by
# design: the record uses that form deliberately as the safe spelling. And
# an account name outside ASCII — /Users/한글 does not match the class;
# widening the class is the exemption's return trigger (ROADMAP → Known
# holes) and is not done silently here. Matched text is never printed:
# findings carry path and line only, because gate output gets quoted into
# prose and a gate that echoes the leak becomes the leak.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need git

CLASS='/(Users|home)/[A-Za-z0-9._-]+'
CARVE='s;/(Users|home)/runner/;/;g'

FILES="$(git ls-files -co --exclude-standard -- docs CLAUDE.md README.md .claude 2>/dev/null)"

scanned=0
while IFS= read -r f; do
    [ -f "$f" ] && scanned=$((scanned + 1))   # tracked but deleted: no text
done <<< "$FILES"

# Zero files scanned is an empty measurement, not a clean one. CLAUDE.md is
# tracked, so on any checkout of this repository this fires only when the
# enumeration itself failed.
[ "$scanned" -gt 0 ] || die_cannot_run "no committed text found in scope"

note "gate-hostpath: INV-14 over $scanned files in scope"

scan_file() {  # scan_file FILE
    local f="$1" m n line stripped

    # -a treats a binary as text: a match inside one still comes out as
    # path:line rather than grep's "Binary file matches" banner, which
    # would break the findings shape teeth counts.
    grep -naE "$CLASS" "$f" \
        | while IFS= read -r m; do
            n="${m%%:*}"
            line="${m#*:}"
            stripped="$(printf '%s\n' "$line" | sed -E "$CARVE")"
            printf '%s\n' "$stripped" | grep -qE "$CLASS" || continue
            finding "$f" "$n" "INV-14: absolute host path"
        done
}

while IFS= read -r f; do
    [ -f "$f" ] || continue
    scan_file "$f"
    rc=$?
    # Under pipefail scan_file's status is grep's. 1 is a legitimate
    # no-match; anything above it means grep could not read the file, and
    # a silent 0 there would be a clean verdict the tool never earned.
    [ "$rc" -le 1 ] || die_cannot_run "grep failed ($rc) reading $f"
done <<< "$FILES"

finish
