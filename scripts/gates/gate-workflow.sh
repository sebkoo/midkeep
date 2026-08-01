#!/usr/bin/env bash
#
# gate-workflow.sh — the GitHub workflow files, checked when a checker exists.
#
# The path sweep found `.github/workflows/*.yml` among the paths something
# other than a human acts on and nothing in the tree reads. GitHub executes
# them; until this gate they were the only executables here with no check of
# any kind.
#
# actionlint is optional rather than a precondition. When it is absent this
# gate returns 2 with a reason, which is what the contract's third code is for
# and is how the three Swift gates already behave on a host with no toolchain.
# The ratified Preconditions — a Swift 6 toolchain and `swift format` — stay as
# they are.
#
# What a green here does and does not mean. actionlint validates the workflow
# schema, and runs shellcheck over `run:` blocks when shellcheck is on PATH.
# It does not run the workflow, so it cannot tell you that `gates.yml` really
# invokes all.sh and teeth.sh against a real checkout. Only a push does that.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

cd "$(dirname "${BASH_SOURCE[0]}")/../.." \
    || die_cannot_run "cannot reach the repository root"

[ -d .github/workflows ] || die_cannot_run ".github/workflows not found"

command -v actionlint > /dev/null 2>&1 \
    || die_cannot_run "actionlint not installed; workflow files unchecked"

# Reported rather than assumed. actionlint skips its shellcheck rule silently
# when shellcheck is absent — same exit code, no warning — so a green run
# without it means the schema was validated and the shell never looked at.
if command -v shellcheck > /dev/null 2>&1; then
    note "gate-workflow: actionlint over .github/workflows, shell blocks included"
else
    note "gate-workflow: actionlint over .github/workflows, shell blocks NOT checked (no shellcheck)"
fi

REPO_PHYSICAL="$(pwd -P)"

# actionlint writes `path:line:col: message [rule]` to stdout. The contract puts
# findings on stdout in its own shape, so they are re-emitted through `finding`.
diagnostics="$(actionlint .github/workflows/*.yml 2>&1)"
rc=$?

while IFS= read -r line; do
    [ -n "$line" ] || continue

    case "$line" in
        *:[0-9]*:[0-9]*:*) ;;
        *) continue ;;
    esac

    path="${line%%:*}"
    rest="${line#*:}"
    lineno="${rest%%:*}"
    rest="${rest#*:}"
    rest="${rest#*:}"

    case "$lineno" in
        '' | *[!0-9]*) continue ;;
    esac

    message="${rest# }"
    path="${path#"$REPO_PHYSICAL"/}"
    path="${path#"$PWD"/}"

    finding "$path" "$lineno" "workflow: $message"
done <<< "$diagnostics"

# Non-zero with nothing parsed is the tool failing rather than a workflow being
# wrong — the same boundary gate-build, gate-format and gate-test draw.
if [ "$rc" -ne 0 ] && [ "$(gate_finding_count)" -eq 0 ]; then
    die_cannot_run "actionlint exited $rc with no parsable diagnostics: $diagnostics"
fi

finish
