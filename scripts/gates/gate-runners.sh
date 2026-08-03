#!/usr/bin/env bash
#
# gate-runners.sh — INV-13's two readable clauses.
#
# Clause 1  every `runs-on` in every workflow names a label on the allowlist
#           below — the standard GitHub-hosted labels this tree actually
#           uses, each entry dated. A label not on the list is a finding and
#           therefore a ratification stop before it can land, which is the
#           intended behaviour. Any `${{ }}` expression in runs-on is a
#           finding for the same reason: what cannot be analysed can never
#           match an allow rule.
#
# Clause 2  `runs-on: macos-*` carries a build declaration in a fixed
#           grammar, as a trailing comment on the same line:
#
#               runs-on: macos-15 # INV-13: needs a Swift build
#
#           The marker declares the need; it does not prove it. This gate is
#           declaration-checked, not need-checked — whether the job truly
#           needs the Swift toolchain is a hand-review question, INV-11
#           style. A SwiftUI build is a Swift build for this marker's
#           purpose.
#
# Pure grep over .github/workflows/. Needs nothing but a checkout, which is
# why this gate reaches a verdict on every clone — actionlint and the schema
# question stay in gate-workflow, a different tool with a different failure
# mode.
#
# What this gate cannot see, named rather than implied. A job that calls a
# reusable workflow (`uses:` at job level) has no runs-on here and its
# runner is chosen in the called file, which may live in another repository;
# grep cannot follow it. And a literal `runs-on:` line inside a `run:` block
# scalar would be read as a real one — a false positive, the conservative
# direction. So would a commented-out `# runs-on:` line, for the same reason:
# the scan is unanchored, because GitHub honours flow-style mappings
# (`planted: {runs-on: macos-latest-xlarge, ...}`) and an anchored scan was
# measured passing one clean. Unanchored, the flow form reaches the label
# ladder with the rest of the mapping still attached and fails the allowlist
# as junk — a finding, which is the conservative direction again. All of this
# is the cost of a gate with no YAML parser, and the INV-13 mark stays
# PARTIAL partly for this reason.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

WORKFLOWS_DIR=.github/workflows
[ -d "$WORKFLOWS_DIR" ] || die_cannot_run "$WORKFLOWS_DIR not found"

# The allowlist is the set the tree uses, nothing more. Growing it is a
# ratification stop by construction: the new label fails this gate until the
# line below changes, and scripts/gates/** is ask-gated.
#
#   macos-15       allowed 2026-08-02 — gates.yml gates job, ci.yml build job
#   ubuntu-latest  allowed 2026-08-02 — gates.yml pull-request-body job
#
# The set is written once, in the case pattern inside scan_file. These two
# comment lines date the entries and are not a second copy of the list.
MARKER='INV-13: needs a Swift build'

# GitHub reads workflows from the top level of .github/workflows only, and
# accepts both extensions. gate-workflow globs *.yml alone; this gate globs
# both so a .yaml workflow cannot sit outside the allowlist unseen.
#
# No array: expanding an empty array under `set -u` is an unbound-variable
# error on the bash 3.2 that /bin/bash still is on macOS, and an empty
# workflows directory must produce a verdict, not a crash. An unmatched glob
# stays literal and the -f test drops it.
scanned=0
for f in "$WORKFLOWS_DIR"/*.yml "$WORKFLOWS_DIR"/*.yaml; do
    [ -f "$f" ] && scanned=$((scanned + 1))
done

# Zero files scanned is an empty measurement, not a clean one — the
# meta.captured shape. The directory existing was checked above; both
# reserved-2s are named so a 2 here always says which it was.
[ "$scanned" -gt 0 ] || die_cannot_run "no workflow files in $WORKFLOWS_DIR"

note "gate-runners: INV-13 over $scanned workflow files"

scan_file() {  # scan_file FILE
    local f="$1"
    local match lineno line rest comment value

    # The key match allows optional quoting and space before the colon —
    # both are YAML-legal spellings of the same key, and a gate that matched
    # only the plain form would hand anyone a one-character bypass. It is
    # deliberately not anchored to the start of the line: a flow-style
    # mapping puts `runs-on` mid-line, and an anchored scan was measured
    # letting `{runs-on: macos-latest-xlarge, ...}` pass clean. The header
    # names the false positives this costs.
    grep -nE '["'\'']?runs-on["'\'']?[[:space:]]*:' "$f" \
        | while IFS= read -r match; do
            lineno="${match%%:*}"
            line="${match#*:}"

            rest="${line#*runs-on}"
            rest="${rest#*:}"

            comment=""
            case "$rest" in
                *"#"*)
                    comment="${rest#*"#"}"
                    rest="${rest%%"#"*}"
                    ;;
            esac

            value="${rest#"${rest%%[![:space:]]*}"}"
            value="${value%"${value##*[![:space:]]}"}"

            case "$value" in
                *'${{'*)
                    finding "$f" "$lineno" \
                        "INV-13: runs-on is an expression, which can never match an allow rule"
                    continue
                    ;;
            esac

            if [ -z "$value" ]; then
                finding "$f" "$lineno" \
                    "INV-13: runs-on carries no inline label (block, sequence or group form)"
                continue
            fi

            case "$value" in
                \[* | \{*)
                    finding "$f" "$lineno" \
                        "INV-13: runs-on is not a single label"
                    continue
                    ;;
            esac

            case "$value" in
                '"'*'"') value="${value#\"}"; value="${value%\"}" ;;
                "'"*"'") value="${value#\'}"; value="${value%\'}" ;;
            esac

            # Clause 1. The allowlist, written exactly once.
            case "$value" in
                macos-15 | ubuntu-latest) ;;
                *)
                    finding "$f" "$lineno" \
                        "INV-13: runner label '$value' is not in the allowlist"
                    continue
                    ;;
            esac

            # Clause 2, reached only by allowlisted labels: a label that
            # already failed clause 1 gets one finding, not two, and the
            # marker requirement binds the labels the tree is allowed to use.
            case "$value" in
                macos-*)
                    case "$comment" in
                        *"$MARKER"*) ;;
                        *)
                            finding "$f" "$lineno" \
                                "INV-13: macos runner carries no build declaration (# $MARKER)"
                            ;;
                    esac
                    ;;
            esac
        done
}

for f in "$WORKFLOWS_DIR"/*.yml "$WORKFLOWS_DIR"/*.yaml; do
    [ -f "$f" ] || continue
    scan_file "$f"
    rc=$?
    # Under pipefail scan_file's status is grep's. 1 is a legitimate
    # no-match — a workflow with no runs-on line at all — and anything
    # above it means grep could not read the file, where a silent 0 would
    # be a clean verdict the tool never earned.
    [ "$rc" -le 1 ] || die_cannot_run "grep failed ($rc) reading $f"
done

finish
