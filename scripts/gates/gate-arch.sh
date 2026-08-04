#!/usr/bin/env bash
#
# gate-arch.sh — INV-1, INV-3, and the app project's readable settings.
#
# INV-1  Swift 6 language mode, strict concurrency complete, every target.
#        Two subjects: the manifest for the package targets, and the app
#        project's SWIFT_VERSION for the shim in App/, which compiles under
#        the project's settings and never sees the manifest.
# INV-3  MidkeepKit imports no UI framework and no third-party module;
#        MidkeepUI imports MidkeepKit and SwiftUI only; nothing in the
#        package imports MidkeepApp — only the app-shell layer (App/) may,
#        and App/'s own imports are allowlisted here.
# INV-5  The one readable clause of the xcodebuild path:
#        SWIFT_TREAT_WARNINGS_AS_ERRORS = YES in the committed project.
#        gate-build does not build the app target; this text is what stands
#        between a one-line settings deletion and an unguarded build.
#
# The pbxproj checks are greps over a settings serialization, and the header
# names what they cannot see: a setting present at one configuration level
# and omitted at another is invisible — the check knows presence and value,
# not inheritance.
#
# Needs nothing but a checkout and git, which is why this gate still reaches a
# verdict on a host with no Swift toolchain.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

MANIFEST=Package.swift
[ -f "$MANIFEST" ] || die_cannot_run "$MANIFEST not found"
[ -d Sources ] || die_cannot_run "Sources/ not found"

note "gate-arch: INV-1 against $MANIFEST and the app project, INV-3 across Sources/ and App/"

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
# The app-shell shim: the one sanctioned importer of MidkeepApp (INV-3 as
# amended in unit 03), allowed exactly that and the framework its App
# conformance needs.
scan_imports App \
    'SwiftUI|MidkeepApp' 'App shell'

# Nothing in the package imports the composition root. App/ is deliberately
# outside this scan: its import of MidkeepApp is the amendment's permission,
# and its own allowlist above is what constrains it.
grep -rnE '^[[:space:]]*(@[A-Za-z]+[[:space:]]+)?import[[:space:]]+MidkeepApp' \
    Sources Tests \
    | while IFS=: read -r f n _; do
        finding "$f" "$n" "INV-3: MidkeepApp is imported"
    done

# --- the app project ---------------------------------------------------------
#
# A missing subject is a finding, not a skip: a skip would let one `git rm`
# retire both clauses silently, the check-that-cannot-fail shape this
# repository keeps finding elsewhere.
PBXPROJ=Midkeep.xcodeproj/project.pbxproj
if [ ! -f "$PBXPROJ" ]; then
    finding "$PBXPROJ" 1 \
        "INV-1: app project missing; its Swift 6 and warnings-as-errors settings live here"
else
    grep -qE '^[[:space:]]*SWIFT_VERSION = 6\.[0-9]+;' "$PBXPROJ" \
        || finding "$PBXPROJ" 1 "INV-1: SWIFT_VERSION 6 not declared in the app project"
    grep -nE 'SWIFT_VERSION =' "$PBXPROJ" \
        | grep -vE 'SWIFT_VERSION = 6\.[0-9]+;' \
        | while IFS=: read -r n _; do
            finding "$PBXPROJ" "$n" "INV-1: SWIFT_VERSION set below 6 in the app project"
        done
    grep -qE '^[[:space:]]*SWIFT_TREAT_WARNINGS_AS_ERRORS = YES;' "$PBXPROJ" \
        || finding "$PBXPROJ" 1 \
            "INV-5: SWIFT_TREAT_WARNINGS_AS_ERRORS = YES not declared in the app project"
    grep -nE 'SWIFT_TREAT_WARNINGS_AS_ERRORS =' "$PBXPROJ" \
        | grep -vE 'SWIFT_TREAT_WARNINGS_AS_ERRORS = YES;' \
        | while IFS=: read -r n _; do
            finding "$PBXPROJ" "$n" "INV-5: SWIFT_TREAT_WARNINGS_AS_ERRORS switched off"
        done
fi

finish
