#!/usr/bin/env bash
#
# device-rig.sh — the unit-04 device rig (ruling D5). Not a gate: device
# state is not a tree property, and all.sh stays device-free. This script
# runs on the development host against a connected phone and measures the
# ladder capability itself: a job killed mid-flight carries on after
# relaunch, judged from the journal and artifact read back off the device,
# never from a screen.
#
# Flow: build signed for the device, install, launch with --start-job (the
# rig's stand-in for a person's tap on Start), SIGKILL the process at
# +KILL_AFTER seconds, read the journal from the app's data container,
# relaunch with no argument — resume must need nothing — wait, read again,
# and judge.
#
# The judge's discriminator is the append-only property itself: the journal
# read after the kill must be a byte-prefix of the journal read after the
# relaunch, and the step that was attempted-without-completion at the kill
# must show exactly one more attempted record afterwards — both attempts
# kept, ADR-0002's bookkeeping. A relaunch that wiped the journal and
# started over would pass every count-based check and is exactly what the
# capability sentence excludes; the prefix check fails it instantly.
#
# The two channels, measured on 2026-08-04 against Xcode 26.6's devicectl:
#   kill    `devicectl device process signal --signal SIGKILL` — a kill
#           without ceremony, mid-foreground; no suspend, no backgrounding
#           callbacks, the strong semantics of D5's rider.
#   verify  `devicectl device copy from --domain-type appDataContainer` —
#           the journal and artifact read from the container by the host.
#
# The signing team identifier is derived from the local certificate at run
# time and is never committed — the unit-03 withholding rule. Override with
# MIDKEEP_TEAM_ID. Pick a device with MIDKEEP_DEVICE (name or UDID) when
# more than one is connected.
#
# Exit: 0 the capability held, facts on stdout; 1 it did not, facts on
# stdout; 2 could not measure — no device, no identity, build failure, or
# the kill missed the mid-job window — reason on stderr. On exit 2 the
# temp directory is kept so the logs the reasons point at still exist.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || {
    printf 'device-rig: cannot reach the repository root\n' >&2
    exit 2
}

BUNDLE=dev.midkeep.Midkeep
CONTAINER_DIR='Library/Application Support/Midkeep'
KILL_AFTER="${KILL_AFTER:-5}"
RESUME_WAIT="${RESUME_WAIT:-15}"

note() { printf 'device-rig: %s\n' "$*" >&2; }
die2() { note "$*"; exit 2; }

command -v xcrun >/dev/null || die2 'cannot run: xcrun not found'
xcrun devicectl --version >/dev/null 2>&1 || die2 'cannot run: devicectl not found'
command -v python3 >/dev/null || die2 'cannot run: python3 not found'

TMP="$(mktemp -d "${TMPDIR:-/tmp}/device-rig.XXXXXX")" || die2 'cannot run: no temp dir'
cleanup() {
    code=$?
    if [ "$code" -eq 2 ]; then
        note "kept for inspection: $TMP"
    else
        rm -rf "$TMP"
    fi
}
trap cleanup EXIT

# The device: MIDKEEP_DEVICE, or the single connected one.
if [ -n "${MIDKEEP_DEVICE:-}" ]; then
    DEVICE="$MIDKEEP_DEVICE"
else
    DEVICE="$(xcrun devicectl list devices 2>/dev/null \
        | grep ' connected ' \
        | grep -oE '[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}' \
        | head -1)"
    [ -n "$DEVICE" ] || die2 'cannot run: no connected device (devicectl list devices)'
fi
note "device: $DEVICE"

# The team, derived rather than committed.
if [ -n "${MIDKEEP_TEAM_ID:-}" ]; then
    TEAM="$MIDKEEP_TEAM_ID"
else
    TEAM="$(security find-certificate -c 'Apple Development' -p 2>/dev/null \
        | openssl x509 -noout -subject 2>/dev/null \
        | sed -nE 's/.*OU ?= ?([A-Z0-9]{10}).*/\1/p')"
    [ -n "$TEAM" ] || die2 'cannot run: no Apple Development identity; set MIDKEEP_TEAM_ID'
fi

note 'building signed for the device (xcodebuild, log in temp dir)'
xcodebuild -project Midkeep.xcodeproj -scheme Midkeep \
    -destination generic/platform=iOS \
    -derivedDataPath "$TMP/dd" \
    DEVELOPMENT_TEAM="$TEAM" -allowProvisioningUpdates \
    build > "$TMP/xcodebuild.log" 2>&1 \
    || die2 "cannot run: device build failed; log kept at $TMP/xcodebuild.log"
APP="$TMP/dd/Build/Products/Debug-iphoneos/Midkeep.app"
[ -d "$APP" ] || die2 'cannot run: built app not found where expected'

if [ "${1:-}" = --fresh ]; then
    note 'fresh: uninstalling first to clear the container'
    xcrun devicectl device uninstall app --device "$DEVICE" "$BUNDLE" >/dev/null 2>&1
fi

note 'installing'
xcrun devicectl device install app --device "$DEVICE" "$APP" > "$TMP/install.log" 2>&1 \
    || die2 "cannot run: install failed (phone unlocked? trusting this host?); log kept at $TMP/install.log"

note "launching with --start-job, killing at +${KILL_AFTER}s"
xcrun devicectl device process launch --terminate-existing \
    --json-output "$TMP/launch.json" \
    --device "$DEVICE" "$BUNDLE" --start-job > "$TMP/launch.log" 2>&1 \
    || die2 "cannot run: launch failed (phone unlocked?); log kept at $TMP/launch.log"
PID="$(python3 -c 'import json,sys
print(json.load(open(sys.argv[1]))["result"]["process"]["processIdentifier"])' \
    "$TMP/launch.json")" || die2 'cannot run: no pid in launch output'

sleep "$KILL_AFTER"
xcrun devicectl device process signal --device "$DEVICE" \
    --pid "$PID" --signal SIGKILL > "$TMP/kill.log" 2>&1 \
    || die2 "cannot run: SIGKILL failed; log kept at $TMP/kill.log"
note "killed pid $PID with SIGKILL via devicectl — mid-foreground, no ceremony"

copy_from() {
    xcrun devicectl device copy from --device "$DEVICE" \
        --domain-type appDataContainer --domain-identifier "$BUNDLE" \
        --source "$1" --destination "$2" > /dev/null 2>&1
}

copy_from "$CONTAINER_DIR/rehearsal.journal" "$TMP/journal-after-kill" \
    || die2 'cannot run: could not read the journal from the container'
printf -- '--- journal after the kill ---\n'
cat "$TMP/journal-after-kill"

COMPLETED_AT_KILL="$(grep -c '"completed"' "$TMP/journal-after-kill")"
if [ "$COMPLETED_AT_KILL" -ge 4 ]; then
    die2 'kill missed the window: all steps already complete; lower KILL_AFTER'
fi
if ! grep -q '"attempted"' "$TMP/journal-after-kill"; then
    die2 'kill missed the window: nothing journalled yet; raise KILL_AFTER'
fi

note "relaunching with no argument — resume must need nothing — waiting ${RESUME_WAIT}s"
xcrun devicectl device process launch \
    --device "$DEVICE" "$BUNDLE" > "$TMP/relaunch.log" 2>&1 \
    || die2 "cannot run: relaunch failed; log kept at $TMP/relaunch.log"
sleep "$RESUME_WAIT"

copy_from "$CONTAINER_DIR/rehearsal.journal" "$TMP/journal-after-resume" \
    || die2 'cannot run: could not re-read the journal'
copy_from "$CONTAINER_DIR/rehearsal-products.txt" "$TMP/artifact" \
    || die2 'cannot run: could not read the artifact'
printf -- '--- journal after the relaunch ---\n'
cat "$TMP/journal-after-resume"
printf -- '--- artifact after the relaunch ---\n'
cat "$TMP/artifact"

python3 - "$TMP/journal-after-kill" "$TMP/journal-after-resume" "$TMP/artifact" <<'PY'
import json, sys

def raw(path):
    return open(path, "rb").read()

def records(path):
    lines = open(path, encoding="utf-8").read().splitlines()
    return [json.loads(line) for line in lines[1:]]  # line 1 is the header

def attempts(entries, step):
    return sum(1 for e in entries
               if e.get("attempted", {}).get("stepIndex") == step)

def completed(entries):
    return {e["completed"]["stepIndex"] for e in entries if "completed" in e}

before = records(sys.argv[1])
after = records(sys.argv[2])
artifact = open(sys.argv[3], encoding="utf-8").read().splitlines()

ok = True
def fact(text):
    print("rig fact:", text)

fact(f"completed records at the kill: {sorted(completed(before))}")
fact(f"completed records after relaunch: {sorted(completed(after))}")
fact(f"artifact lines: {len(artifact)}, distinct: {len(set(artifact))}")

# The append-only discriminator: a journal that carried on extends the one
# the kill left, byte for byte. A wiped-and-restarted journal passes every
# count below and fails here.
if not raw(sys.argv[2]).startswith(raw(sys.argv[1])):
    ok = False
    fact("FAIL: the post-relaunch journal is not an extension of the "
         "pre-relaunch journal — this is starting over, not carrying on")

if completed(after) != {0, 1, 2, 3}:
    ok = False
    fact("FAIL: not every step completed after the relaunch")
if len(artifact) != 4 or len(set(artifact)) != 4:
    ok = False
    fact("FAIL: the artifact does not hold exactly four distinct products")
for step in sorted(completed(before)):
    if attempts(after, step) != attempts(before, step):
        ok = False
        fact(f"FAIL: step {step} was re-attempted after completing")

# The step the kill caught mid-work: attempted without completion at the
# kill, so the relaunch owes it exactly one more attempted record — both
# attempts kept, ADR-0002's bookkeeping.
mid = [s for s in range(4)
       if attempts(before, s) > 0 and s not in completed(before)]
fact(f"steps attempted without completion at the kill: {mid}")
for step in mid:
    got = attempts(after, step)
    want = attempts(before, step) + 1
    if got != want:
        ok = False
        fact(f"FAIL: step {step} shows {got} attempted records after "
             f"relaunch, wanted {want} — both attempts must be kept")

sys.exit(0 if ok else 1)
PY
JUDGE=$?
if [ "$JUDGE" -eq 0 ]; then
    printf 'device-rig: the job carried on — killed mid-flight, resumed from the journal\n'
    exit 0
fi
printf 'device-rig: the capability did not hold; the facts above say where\n'
exit 1
