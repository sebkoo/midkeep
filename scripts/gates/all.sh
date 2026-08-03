#!/usr/bin/env bash
#
# all.sh — run every gate and aggregate their verdicts into one.
#
# Precedence: 2 if any gate returned 2, else 1 if any returned 1, else 0.
# "Could not run" is the more urgent fact and unknown is not safe, so a run
# that both found something and could not finish reports 2. That is not the
# same as either alone, and this is the only place the distinction can be lost.
# Argued in docs/adr/0005-gate-exit-code-contract.md.
#
# Each gate's stdout flows through untouched, so findings stay countable by
# path from outside. The per-gate summary goes to stderr, because stdout
# carries findings and nothing else.

. "$(dirname "${BASH_SOURCE[0]}")/lib/contract.sh"

GATES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)" \
    || die_cannot_run "cannot reach the gates directory"

# Cheapest first. gate-arch, gate-hygiene and gate-runners need only a
# checkout and git, so on a host with no toolchain they still reach a verdict
# while the three toolchain gates report 2.
#
# gate-workflow needs actionlint, which the Preconditions do not require. On a
# host without it that gate returns 2 and so does this runner — the same shape
# as a host with no Swift, and the contract working rather than failing.
GATES="gate-arch gate-hygiene gate-runners gate-workflow gate-format gate-build gate-test"

saw_finding=0
saw_no_verdict=0

for gate in $GATES; do
    script="$GATES_DIR/$gate.sh"
    if [ ! -f "$script" ]; then
        note "$(printf '%-14s %s' "$gate" "missing")"
        saw_no_verdict=1
        continue
    fi

    bash "$script"
    rc=$?

    note "$(printf '%-14s %s' "$gate" "$rc")"

    case "$rc" in
        0) ;;
        1) saw_finding=1 ;;
        2) saw_no_verdict=1 ;;
        # A gate that returns anything else has broken its own contract, and a
        # broken gate is a gate that reached no verdict.
        *) saw_no_verdict=1 ;;
    esac
done

if [ "$saw_no_verdict" -eq 1 ]; then
    note "all.sh: 2 — at least one gate reached no verdict"
    finish 2
elif [ "$saw_finding" -eq 1 ]; then
    note "all.sh: 1 — at least one gate found something"
    finish 1
fi

note "all.sh: 0 — every gate ran and found nothing"
finish 0
