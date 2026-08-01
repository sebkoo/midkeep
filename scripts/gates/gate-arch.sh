#!/usr/bin/env bash
#
# gate-arch.sh — INV-1 and INV-3.
#
# INV-1  Swift 6 language mode, strict concurrency complete, every target.
# INV-3  MidkeepKit imports no UI framework and no third-party module;
#        MidkeepUI imports MidkeepKit and SwiftUI only; nothing imports
#        MidkeepApp.
#
# Needs nothing but a checkout and git, which is why this gate still reaches a
# verdict on a host with no Swift toolchain.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

MANIFEST=Package.swift
[ -f "$MANIFEST" ] || die_cannot_run "$MANIFEST not found"
[ -d Sources ] || die_cannot_run "Sources/ not found"

note "gate-arch: INV-1 against $MANIFEST, INV-3 across Sources/"

# --- INV-1, positive -------------------------------------------------------
#
# The swift-tools-version line is what actually puts every target in Swift 6
# mode. It is a comment by construction, so matching its text is exact.
#
# This direction has no teeth plant: the plant exercises the opt-down, which is
# what happens when somebody silences a concurrency error. Recorded in ROADMAP
# under Known holes as a gate with a direction no plant covers.
tools_line="$(grep -n -m1 -E '^//[[:space:]]*swift-tools-version:' "$MANIFEST")"
if [ -z "$tools_line" ]; then
    finding "$MANIFEST" 1 "INV-1: no swift-tools-version line"
else
    tools_n="${tools_line%%:*}"
    tools_major="$(printf '%s' "$tools_line" \
        | sed -E 's|.*swift-tools-version:[[:space:]]*([0-9]+).*|\1|')"
    case "$tools_major" in
        ''|*[!0-9]*)
            finding "$MANIFEST" "$tools_n" \
                "INV-1: swift-tools-version is not a number"
            ;;
        *)
            if [ "$tools_major" -lt 6 ]; then
                finding "$MANIFEST" "$tools_n" \
                    "INV-1: swift-tools-version $tools_major is below 6"
            fi
            ;;
    esac
fi

# --- INV-1, negative -------------------------------------------------------
#
# Under Swift 6 mode complete checking is implied and never appears in the
# manifest, so searching for opt-downs alone would pass a manifest that
# declares nothing at all. Both directions are needed.
#
# The `| while read` shape below is deliberate: it is the natural way to scan
# lines, and contract.sh tallies findings in a file precisely so that a finding
# raised inside a subshell still reaches the exit code.
grep -nE 'swiftLanguageMode\(' "$MANIFEST" \
    | grep -vE 'swiftLanguageMode\(\.v6\)' \
    | while IFS=: read -r n _; do
        finding "$MANIFEST" "$n" "INV-1: swiftLanguageMode opts out of .v6"
    done

grep -nE 'swiftLanguageVersions' "$MANIFEST" \
    | grep -vE '\.v6' \
    | while IFS=: read -r n _; do
        finding "$MANIFEST" "$n" "INV-1: swiftLanguageVersions below .v6"
    done

grep -nE 'strict-concurrency=(minimal|targeted)' "$MANIFEST" \
    | while IFS=: read -r n _; do
        finding "$MANIFEST" "$n" "INV-1: -strict-concurrency below complete"
    done

# --- INV-3 -----------------------------------------------------------------
#
# Imports sit at the top of a file and cannot appear inside an interpolation,
# so a line-level match is exact here in a way it is not for INV-4.
#
# The rule is stated as an allowlist rather than a list of banned frameworks,
# so a module nobody thought of is a finding rather than a silent pass.
scan_imports() {  # scan_imports MODULE_DIR ALLOWED_PATTERN LABEL
    local dir="$1" allowed="$2" label="$3"
    [ -d "$dir" ] || return 0
    grep -rnE '^[[:space:]]*import[[:space:]]+[A-Za-z_]' "$dir" \
        | while IFS=: read -r f n rest; do
            local mod
            mod="$(printf '%s' "$rest" \
                | sed -E 's|^[[:space:]]*import[[:space:]]+([A-Za-z_][A-Za-z0-9_]*).*|\1|')"
            printf '%s' "$mod" | grep -qE "^($allowed)$" \
                || finding "$f" "$n" "INV-3: $label imports $mod"
        done
}

scan_imports Sources/MidkeepKit \
    'Foundation|Dispatch|os|Observation' 'MidkeepKit'
scan_imports Sources/MidkeepUI \
    'Foundation|Dispatch|os|Observation|SwiftUI|MidkeepKit' 'MidkeepUI'

# Nothing imports the composition root.
grep -rnE '^[[:space:]]*(@[A-Za-z]+[[:space:]]+)?import[[:space:]]+MidkeepApp' \
    Sources Tests \
    | while IFS=: read -r f n _; do
        finding "$f" "$n" "INV-3: MidkeepApp is imported"
    done

finish
