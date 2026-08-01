#!/usr/bin/env bash
#
# gate-format.sh — the committed formatter configuration, enforced.
#
# Claims no numbered invariant, and is teeth-tested anyway: a decorative
# formatter is exactly the failure the --strict note below is about.
#
# Scope includes Package.swift. The path sweep found the manifest was read by
# no formatter at all, which is the one file a committed .swift-format most
# obviously ought to govern.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

need swift
CONFIG=.swift-format
[ -f "$CONFIG" ] || die_cannot_run "$CONFIG not found"

# $PWD is the logical path; the tool emits the physical one. Both prefixes have
# to come off or a finding keeps its absolute path. See gate-build.sh.
REPO_PHYSICAL="$(pwd -P)"

note "gate-format: swift format lint --strict over Package.swift Sources Tests"

# --strict is load-bearing. Without it lint exits 0 on warnings and the gate is
# decorative. Without --configuration the criterion is whatever the installed
# toolchain shipped with, so the same source passes on one machine and fails on
# another — which is why the configuration is committed rather than assumed.
#
# Diagnostics arrive on stderr as `path:line:col: error: [Rule] message`. The
# contract puts findings on stdout, so they are re-emitted through `finding`.
# stdout from the tool is discarded: it carries formatted source, not verdicts.
diagnostics="$(
    swift format lint --strict --configuration "$CONFIG" --recursive \
        Package.swift Sources Tests 2>&1 >/dev/null
)"
rc=$?

while IFS= read -r line; do
    [ -n "$line" ] || continue

    # path:line:col: severity: message
    case "$line" in
        /*:*:*:*|[A-Za-z]*:*:*:*) ;;
        *) continue ;;
    esac

    path="${line%%:*}"
    rest="${line#*:}"
    lineno="${rest%%:*}"
    rest="${rest#*:}"
    rest="${rest#*:}"

    case "$lineno" in
        ''|*[!0-9]*) continue ;;
    esac

    message="${rest# }"
    message="${message#error: }"
    message="${message#warning: }"
    path="${path#"$REPO_PHYSICAL"/}"
    path="${path#"$PWD"/}"

    finding "$path" "$lineno" "format: $message"
done <<< "$diagnostics"

# A non-zero status with nothing parsed is the tool failing rather than the
# source being wrong — an unreadable configuration, an unknown key, a broken
# install. Those are "no verdict", not "found something", and the contract
# keeps them apart. Two exit codes alone cannot: only the text can.
if [ "$rc" -ne 0 ] && [ "$(gate_finding_count)" -eq 0 ]; then
    die_cannot_run "swift format exited $rc with no diagnostics: $diagnostics"
fi

finish
