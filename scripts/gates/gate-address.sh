#!/usr/bin/env bash
#
# gate-address.sh — INV-15: no personal email shape in committed text.
#
# Shape rather than string, for the reason the record gives (ROADMAP →
# Findings, 2026-08-01): a gate that looks for a specific address has to
# contain the address, and this repository's method is to never quote the
# leak in the machinery that hunts it. The shape is
# [A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}, and what survives the
# exclusions below is a finding.
#
# The exclusions are load-bearing rather than defensive — the tree's own
# evidence quotes addresses on purpose — and every one is matched as a
# suffix or a prefix, never as `example.*`:
#
#   *@users.noreply.github.com      GitHub's attribution address
#   noreply@*                       role addresses quoted as evidence
#   *.example *.invalid *.test *.localhost
#                                   RFC 2606 reserved TLDs, as suffixes,
#                                   because sam@opencodex.example ends in
#                                   .example rather than beginning with it
#   *@example.com *.example.com     the reserved domain and its subdomains,
#                                   never bare *example.com, which would
#                                   also excuse notexample.com
#
# When this gate landed the scope held twelve distinct email-shaped tokens
# and the exclusions covered all twelve; the clean-tree half of its teeth
# case re-measures that on every run. The exclusions are case-sensitive
# and the shape is not, so NoReply@… fires — the conservative direction.
#
# Scope: docs/, CLAUDE.md, README.md, .claude/, .githooks/ — the hostpath
# scope plus the hook, which is the one script whose text discusses
# addresses. Enumerated with `git ls-files -co --exclude-standard` for the
# reason gate-hostpath states: the invariant governs text that can reach a
# commit, and .claude/settings.local.json is documented per-machine.
#
# What this grep cannot see, named rather than implied. An address inside
# scripts/, Sources/ or .github/ — outside the scope. An address wrapped
# across two lines. An obfuscated one — `alice at gmail dot com` is not
# email-shaped. An RFC quoted-string local part ("a b"@host). A non-ASCII
# local part or raw IDN domain; punycode (xn--) does match. Matched text
# is never printed: findings carry path and line only, because gate output
# gets quoted into prose and a gate that echoes the leak becomes the leak.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need git

SHAPE='[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'

FILES="$(git ls-files -co --exclude-standard -- docs CLAUDE.md README.md .claude .githooks 2>/dev/null)"

scanned=0
while IFS= read -r f; do
    [ -f "$f" ] && scanned=$((scanned + 1))   # tracked but deleted: no text
done <<< "$FILES"

[ "$scanned" -gt 0 ] || die_cannot_run "no committed text found in scope"

note "gate-address: INV-15 over $scanned files in scope"

scan_file() {  # scan_file FILE
    local f="$1" n tok

    # -o so a line carrying two addresses yields two verdicts, judged one
    # token at a time; -a for the reason gate-hostpath gives. The token
    # cannot contain a colon, so splitting on the first two is safe.
    grep -naoE "$SHAPE" "$f" \
        | while IFS=: read -r n tok; do
            case "$tok" in
                *@users.noreply.github.com) continue ;;
                noreply@*) continue ;;
                *.example | *.invalid | *.test | *.localhost) continue ;;
                *@example.com | *.example.com) continue ;;
            esac
            finding "$f" "$n" "INV-15: personal email shape"
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
