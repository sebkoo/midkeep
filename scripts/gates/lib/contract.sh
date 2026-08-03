#!/usr/bin/env bash
#
# contract.sh — the exit-code contract every gate obeys, and the helpers that
# make obeying it the path of least resistance.
#
#   0  ran, and found nothing
#   1  ran, and found something. Findings on stdout.
#   2  reached no verdict — missing toolchain, no simulator. Reason on stderr.
#
# Never 2 for findings. Argued in docs/adr/0005-gate-exit-code-contract.md.
#
# Everything a gate writes to stdout is a finding, and nothing else goes there.
# The reason is that findings have to be countable by path from outside the
# gate: a harness that plants a defect and asks whether the gate saw it needs
# stdout to carry findings and only findings. Commentary, banners and progress
# belong on stderr, and `note` exists so that is the default rather than
# something each gate has to remember.
#
# Sourced, not executed. Gates do:
#     . "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

# Deliberately not `-e`. A grep that legitimately matches nothing returns 1, and
# under `-e` that would kill the gate before it could report anything.
set -uo pipefail

# Findings are tallied in a file, not a shell variable.
#
# In bash the last element of a pipeline runs in a subshell, so a variable
# incremented there is lost when the subshell exits. A gate scanning with
#
#     grep -n "$pat" "$f" | while read -r line; do finding ...; done
#
# would print every finding and then report clean — the exact failure this
# repository exists to prevent, sitting in the primitive every gate is built on.
# A line-scanning gate is the natural place for that shape, so the tally has to
# survive it rather than depend on nobody writing it.
#
# A file survives any subshell, unconditionally: pipelines, explicit `( )`, and
# command substitution alike. `shopt -s lastpipe` would fix only the pipeline
# case and only with job control off, and a rule saying "do not call finding
# from a pipeline" is discipline, which this repository does not rely on.
# The tally is scoped to the shell that created it, which settles two boundary
# questions that a bare mktemp on every source would get wrong.
#
# Gates run in sequence — all.sh invokes each in turn — and every gate is a
# separate process. GATE_FINDINGS_FILE is deliberately not exported, and the PID guard
# means that even if it were, a different process would still create its own:
# a finding in one gate can never make the next gate exit 1.
#
# In the other direction, a gate that sources the preamble twice within one
# shell reuses the tally it already has rather than resetting its own count to
# zero. In bash `$$` is the parent's PID inside a subshell, so a subshell that
# re-sources is correctly treated as the same gate.
if [ "${GATE_FINDINGS_PID:-}" != "$$" ] || [ ! -f "${GATE_FINDINGS_FILE:-}" ]; then
    GATE_FINDINGS_FILE="$(mktemp "${TMPDIR:-/tmp}/gate-findings.XXXXXX")" || {
        printf 'cannot run: could not create the findings tally\n' >&2
        exit 2
    }
    GATE_FINDINGS_PID=$$

    # Covers every exit path, including die_cannot_run and an unhandled error,
    # not only finish. A gate that installs its own EXIT trap replaces this one
    # and leaks the tally file — a leak rather than a wrong verdict, but gates
    # should not do it.
    trap '[ -n "${GATE_FINDINGS_FILE:-}" ] && rm -f "$GATE_FINDINGS_FILE"' EXIT
fi

# gate_finding_count
# How many findings have been emitted, from any depth of subshell.
gate_finding_count() {
    if [ ! -f "${GATE_FINDINGS_FILE:-}" ]; then
        printf '0\n'
        return
    fi
    wc -l < "$GATE_FINDINGS_FILE" | tr -d ' '
}

# note MESSAGE...
# Commentary. Always stderr, never stdout.
note() {
    printf '%s\n' "$*" >&2
}

# finding PATH LINE MESSAGE
# One finding, on stdout, in the one shape teeth.sh knows how to count.
finding() {
    printf '%s:%s: %s\n' "$1" "$2" "$3"
    printf 'x\n' >> "$GATE_FINDINGS_FILE"
}

# die_cannot_run REASON...
# No verdict was reached. Exit 2 with the reason on stderr. This is never used
# for findings, however severe — "could not run" and "ran and found something"
# are different facts and the contract keeps them apart.
die_cannot_run() {
    printf 'cannot run: %s\n' "$*" >&2
    exit 2
}

# need COMMAND...
# Every named command must exist. A missing toolchain is not a finding, so this
# returns 2 rather than 1.
need() {
    local c
    for c in "$@"; do
        command -v "$c" >/dev/null 2>&1 || die_cannot_run "$c not found on PATH"
    done
}

# finish [STATUS]
# The only exit path. With no argument the status is derived from the finding
# count, which is why no gate has to remember whether it found anything.
#
# Any status outside {0,1,2} becomes 2, with a reason. Without this, pipefail
# turns a `grep | head` that closes its pipe early into exit 141, and the gate
# silently reports a code the contract does not define.
finish() {
    local status="${1:-}"

    if [ -z "$status" ]; then
        if [ "$(gate_finding_count)" -eq 0 ]; then
            exit 0
        fi
        exit 1
    fi

    case "$status" in
        0 | 1 | 2)
            exit "$status"
            ;;
        *)
            printf 'cannot run: gate produced undefined status %s\n' "$status" >&2
            exit 2
            ;;
    esac
}
