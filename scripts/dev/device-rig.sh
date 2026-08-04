#!/usr/bin/env bash
#
# device-rig.sh — the unit-04 device rig (ruling D5), extended in unit 05
# for the streaming measurement (ruling D4). Not a gate: device state is
# not a tree property, and all.sh stays device-free. This script runs on
# the development host against a connected phone and measures the ladder
# capabilities themselves, judged from the journal and artifacts read back
# off the device, never from a screen.
#
# Two modes:
#   default   the unit-04 measurement: a job killed mid-flight among the
#             unitary steps carries on after relaunch.
#   --stream  the unit-05 measurement: a job killed mid-stream resumes
#             from the journalled offset — the resumed record first, no
#             re-emitted byte — and finishes the same answer its control
#             run produced.
#
# Every run begins with an uninterrupted CONTROL run in a reset container
# — the rig's own positive control (unit 05, ruling D4): the killed run's
# final artifacts must equal the control's byte for byte, so "carried on"
# is judged against a measured answer, never a hard-coded one.
#
# Time to first token is measured on the control run, externally, by
# polling the stream artifact over devicectl until its first byte appears
# (ruling D4: records stay clockless; the rig is the clock). The figure
# is an interval, not a point — the poll period is its granularity — and
# presentation pacing dominates it by design; the record must say so.
#
# The container is reset by overwriting the journal and artifacts with
# empty files over `devicectl device copy to`, not by uninstalling:
# unit 04 measured that an uninstall drops the phone's trust in the
# developer profile and costs a tap in Settings per run. --fresh still
# uninstalls first for a truly clean container, at that price.
#
# The two channels, measured on 2026-08-04 against Xcode 26.6's devicectl:
#   kill    `devicectl device process signal --signal SIGKILL` — a kill
#           without ceremony, mid-foreground; no suspend, no backgrounding
#           callbacks, the strong semantics of D5's rider.
#   verify  `devicectl device copy from --domain-type appDataContainer` —
#           journal and artifacts read from the container by the host.
#
# The signing team identifier is derived from the local certificate at run
# time and is never committed — the unit-03 withholding rule. Override with
# MIDKEEP_TEAM_ID. Pick a device with MIDKEEP_DEVICE (name or UDID) when
# more than one is connected.
#
# Exit: 0 the capability held, facts on stdout; 1 it did not, facts on
# stdout; 2 could not measure — no device, no identity, build failure, a
# control run that never finished, or the kill missed its window — reason
# on stderr. On exit 2 the temp directory is kept so the logs the reasons
# point at still exist.

set -uo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/../.." || {
    printf 'device-rig: cannot reach the repository root\n' >&2
    exit 2
}

BUNDLE=dev.midkeep.Midkeep
CONTAINER_DIR='Library/Application Support/Midkeep'
RESUME_WAIT="${RESUME_WAIT:-15}"
CONTROL_WAIT="${CONTROL_WAIT:-30}"

MODE=unitary
FRESH=no
for arg in "$@"; do
    case "$arg" in
        --stream) MODE=stream ;;
        --fresh) FRESH=yes ;;
        *)
            printf 'device-rig: unknown argument %s\n' "$arg" >&2
            exit 2
            ;;
    esac
done
if [ "$MODE" = stream ]; then
    KILL_AFTER="${KILL_AFTER:-11}"
else
    KILL_AFTER="${KILL_AFTER:-5}"
fi

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

if [ "$FRESH" = yes ]; then
    note 'fresh: uninstalling first — this costs a trust tap in Settings'
    xcrun devicectl device uninstall app --device "$DEVICE" "$BUNDLE" >/dev/null 2>&1
fi

note 'installing'
xcrun devicectl device install app --device "$DEVICE" "$APP" > "$TMP/install.log" 2>&1 \
    || die2 "cannot run: install failed (phone unlocked? trusting this host?); log kept at $TMP/install.log"

copy_from() {
    xcrun devicectl device copy from --device "$DEVICE" \
        --domain-type appDataContainer --domain-identifier "$BUNDLE" \
        --source "$1" --destination "$2" > /dev/null 2>&1
}
copy_to() {
    xcrun devicectl device copy to --device "$DEVICE" \
        --domain-type appDataContainer --domain-identifier "$BUNDLE" \
        --source "$1" --destination "$2" > /dev/null 2>&1
}

reset_container() {
    # Empty files over the three run files: a fresh run without an
    # uninstall, so the trust tap is not spent. Verified by reading one
    # back — a reset that silently failed would corrupt every later
    # judgement, so the reset carries its own check. The whole reset
    # retries, because an app instance left running by an earlier rig
    # run holds the journal open and can race the overwrite — observed
    # 2026-08-04, one verification failure between two clean runs — and
    # a retry re-runs the operation rather than re-reading until lucky.
    : > "$TMP/empty"
    local attempt
    for attempt in 1 2 3 4 5; do
        if copy_to "$TMP/empty" "$CONTAINER_DIR/rehearsal.journal" \
            && copy_to "$TMP/empty" "$CONTAINER_DIR/rehearsal-products.txt" \
            && copy_to "$TMP/empty" "$CONTAINER_DIR/rehearsal-stream.txt" \
            && copy_from "$CONTAINER_DIR/rehearsal.journal" "$TMP/reset-check" \
            && [ ! -s "$TMP/reset-check" ]; then
            return 0
        fi
        note "container reset attempt $attempt left bytes behind; retrying"
        sleep 3
    done
    die2 'cannot run: container reset left bytes behind after 5 attempts'
}

launch_start_job() {
    xcrun devicectl device process launch --terminate-existing \
        --json-output "$1" \
        --device "$DEVICE" "$BUNDLE" --start-job > "$2" 2>&1
}

# ---- The control run: uninterrupted, in a reset container. ----
note 'control run: reset, launch, wait for completion'
reset_container
# Epoch time, not time.monotonic(): each poll below runs its own python
# process, and monotonic's reference point is undefined across processes —
# measured on this host, two calls 2 s apart subtracted to 0.00. Epoch
# time is cross-process valid, and NTP steps are noise at this scale.
CONTROL_LAUNCH_AT="$(python3 -c 'import time; print(time.time())')"
launch_start_job "$TMP/control-launch.json" "$TMP/control-launch.log" \
    || die2 "cannot run: control launch failed (phone unlocked?); log kept at $TMP/control-launch.log"

# Time to first token, on the control run, by polling the stream artifact.
# Each poll is a devicectl round trip, so the poll period is the figure's
# granularity; both bounds are reported.
TTFT_LOW=''
TTFT_HIGH=''
LAST_EMPTY_AT="$CONTROL_LAUNCH_AT"
DEADLINE=$((SECONDS + CONTROL_WAIT))
while [ "$SECONDS" -lt "$DEADLINE" ]; do
    NOW="$(python3 -c 'import time; print(time.time())')"
    if copy_from "$CONTAINER_DIR/rehearsal-stream.txt" "$TMP/ttft-probe" \
        && [ -s "$TMP/ttft-probe" ]; then
        TTFT_LOW="$(python3 -c "print(f'{$LAST_EMPTY_AT - $CONTROL_LAUNCH_AT:.1f}')")"
        TTFT_HIGH="$(python3 -c "print(f'{$NOW - $CONTROL_LAUNCH_AT:.1f}')")"
        break
    fi
    LAST_EMPTY_AT="$NOW"
done
[ -n "$TTFT_HIGH" ] || note 'time to first token: not observed within CONTROL_WAIT'

# Wait until the control journal shows the whole run complete.
CONTROL_DONE=no
DEADLINE=$((SECONDS + CONTROL_WAIT))
while [ "$SECONDS" -lt "$DEADLINE" ]; do
    if copy_from "$CONTAINER_DIR/rehearsal.journal" "$TMP/control-journal" \
        && [ "$(grep -c '"completed"' "$TMP/control-journal")" -ge 5 ]; then
        CONTROL_DONE=yes
        break
    fi
    sleep 2
done
[ "$CONTROL_DONE" = yes ] || die2 'cannot run: control run did not complete within CONTROL_WAIT'
copy_from "$CONTAINER_DIR/rehearsal-products.txt" "$TMP/control-artifact" \
    || die2 'cannot run: could not read the control artifact'
copy_from "$CONTAINER_DIR/rehearsal-stream.txt" "$TMP/control-stream" \
    || die2 'cannot run: could not read the control stream artifact'
if [ -n "$TTFT_HIGH" ]; then
    printf 'rig fact: time to first token (control run, external poll): between %ss and %ss after launch; presentation pacing dominates by design\n' \
        "$TTFT_LOW" "$TTFT_HIGH"
fi

# ---- The measured run: reset, launch, kill, relaunch, judge. ----
note "measured run (${MODE}): reset, launch with --start-job, kill at +${KILL_AFTER}s"
reset_container
launch_start_job "$TMP/launch.json" "$TMP/launch.log" \
    || die2 "cannot run: launch failed (phone unlocked?); log kept at $TMP/launch.log"
PID="$(python3 -c 'import json,sys
print(json.load(open(sys.argv[1]))["result"]["process"]["processIdentifier"])' \
    "$TMP/launch.json")" || die2 'cannot run: no pid in launch output'

sleep "$KILL_AFTER"
xcrun devicectl device process signal --device "$DEVICE" \
    --pid "$PID" --signal SIGKILL > "$TMP/kill.log" 2>&1 \
    || die2 "cannot run: SIGKILL failed; log kept at $TMP/kill.log"
note "killed pid $PID with SIGKILL via devicectl — mid-foreground, no ceremony"

copy_from "$CONTAINER_DIR/rehearsal.journal" "$TMP/journal-after-kill" \
    || die2 'cannot run: could not read the journal from the container'
printf -- '--- journal after the kill ---\n'
cat "$TMP/journal-after-kill"

if [ "$MODE" = stream ]; then
    if ! grep -q '"streamChunk"' "$TMP/journal-after-kill"; then
        die2 'kill missed the stream window: no chunk record yet; raise KILL_AFTER'
    fi
    if grep -q '"completed":{"stepIndex":4' "$TMP/journal-after-kill" \
        || grep -q '"stepIndex":4[^}]*"completed"' "$TMP/journal-after-kill"; then
        die2 'kill missed the stream window: the stream already completed; lower KILL_AFTER'
    fi
else
    COMPLETED_AT_KILL="$(grep -c '"completed"' "$TMP/journal-after-kill")"
    if [ "$COMPLETED_AT_KILL" -ge 4 ]; then
        die2 'kill missed the window: the unitary steps already complete; lower KILL_AFTER'
    fi
    if ! grep -q '"attempted"' "$TMP/journal-after-kill"; then
        die2 'kill missed the window: nothing journalled yet; raise KILL_AFTER'
    fi
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
copy_from "$CONTAINER_DIR/rehearsal-stream.txt" "$TMP/stream" \
    || die2 'cannot run: could not read the stream artifact'
printf -- '--- journal after the relaunch ---\n'
cat "$TMP/journal-after-resume"
printf -- '--- artifact after the relaunch ---\n'
cat "$TMP/artifact"
printf -- '--- stream artifact after the relaunch ---\n'
cat "$TMP/stream"
printf -- '\n'

python3 - "$MODE" "$TMP/journal-after-kill" "$TMP/journal-after-resume" \
    "$TMP/artifact" "$TMP/stream" "$TMP/control-artifact" "$TMP/control-stream" <<'PY'
import json, sys

mode = sys.argv[1]

def raw(path):
    return open(path, "rb").read()

def valid_lines(data):
    # Complete, parseable JSON lines only. A SIGKILL can tear the last
    # line; the app drops and truncates a torn tail on relaunch, so the
    # judge reads the journal the way the app does and says when it did.
    out = []
    consumed = 0
    for line in data.split(b"\n")[:-1]:
        try:
            out.append(json.loads(line))
        except json.JSONDecodeError:
            break
        consumed += len(line) + 1
    return out, consumed

before_raw = raw(sys.argv[2])
after_raw = raw(sys.argv[3])
before_all, before_bytes = valid_lines(before_raw)
after_all, _ = valid_lines(after_raw)
before = before_all[1:]  # line 1 is the header
after = after_all[1:]
artifact = open(sys.argv[4], encoding="utf-8").read().splitlines()
stream = raw(sys.argv[5])
control_artifact = open(sys.argv[6], encoding="utf-8").read().splitlines()
control_stream = raw(sys.argv[7])

ok = True
def fact(text):
    print("rig fact:", text)

if before_bytes != len(before_raw):
    fact(f"the kill tore the journal's last line; {len(before_raw) - before_bytes} "
         "bytes dropped by the judge as the app drops them")

def attempts(entries, step):
    return sum(1 for e in entries
               if e.get("attempted", {}).get("stepIndex") == step)

def completed(entries):
    return {e["completed"]["stepIndex"] for e in entries if "completed" in e}

def chunks(entries, step):
    return [e["streamChunk"] for e in entries
            if e.get("streamChunk", {}).get("stepIndex") == step]

def resumes(entries, step):
    return [e["streamResumed"] for e in entries
            if e.get("streamResumed", {}).get("stepIndex") == step]

fact(f"completed records at the kill: {sorted(completed(before))}")
fact(f"completed records after relaunch: {sorted(completed(after))}")
fact(f"artifact lines: {len(artifact)}, distinct: {len(set(artifact))}")
fact(f"stream artifact: {len(stream)} bytes; control: {len(control_stream)} bytes")

# The append-only discriminator: a journal that carried on extends the one
# the kill left, byte for byte (minus a torn tail the app truncates). A
# wiped-and-restarted journal passes every count below and fails here.
if not after_raw.startswith(before_raw[:before_bytes]):
    ok = False
    fact("FAIL: the post-relaunch journal is not an extension of the "
         "pre-relaunch journal — this is starting over, not carrying on")

if completed(after) != {0, 1, 2, 3, 4}:
    ok = False
    fact("FAIL: not every step completed after the relaunch")
if len(artifact) != 4 or len(set(artifact)) != 4:
    ok = False
    fact("FAIL: the artifact does not hold exactly four distinct products")

# The control comparison — ruling D4's positive control: "carried on"
# means it produced what an uninterrupted run produced, byte for byte.
if artifact != control_artifact:
    ok = False
    fact("FAIL: the artifact differs from the control run's")
if stream != control_stream:
    ok = False
    fact("FAIL: the stream artifact differs from the control run's")

products = [e["completed"]["product"] for e in after
            if "completed" in e and e["completed"]["stepIndex"] == 4]
if products and products[-1].encode() != stream:
    ok = False
    fact("FAIL: the stream artifact does not match the journalled product")

for step in sorted(completed(before) - {4}):
    if attempts(after, step) != attempts(before, step):
        ok = False
        fact(f"FAIL: step {step} was re-attempted after completing")

if mode == "stream":
    before_chunks = chunks(before, 4)
    offset_at_kill = sum(len(c["text"].encode()) for c in before_chunks)
    fact(f"chunk records at the kill: {len(before_chunks)}, "
         f"{offset_at_kill} bytes of answer on record, no completion — "
         "partial output journalled before the step finished, caught live")
    rs = resumes(after, 4)
    if len(rs) != 1 or rs[0].get("fromOffset") != offset_at_kill:
        ok = False
        fact(f"FAIL: wanted exactly one streamResumed(fromOffset="
             f"{offset_at_kill}), saw {rs}")
    continued = chunks(after, 4)[len(before_chunks):]
    position = offset_at_kill
    for c in continued:
        if c["offset"] != position:
            ok = False
            fact(f"FAIL: post-resume chunk at offset {c['offset']}, "
                 f"wanted {position} — a re-emitted or skipped byte")
            break
        position += len(c["text"].encode())
else:
    mid = [s for s in range(4)
           if attempts(before, s) > 0 and s not in completed(before)]
    fact(f"steps attempted without completion at the kill: {mid}")
    if not mid:
        print("rig judge: no unitary step was mid-flight at the kill; "
              "the window was missed", file=sys.stderr)
        sys.exit(2)
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
if [ "$JUDGE" -eq 2 ]; then
    note "kept for inspection: $TMP"
    exit 2
fi
if [ "$JUDGE" -eq 0 ]; then
    if [ "$MODE" = stream ]; then
        printf 'device-rig: the stream carried on — killed mid-answer, resumed from the journalled offset\n'
    else
        printf 'device-rig: the job carried on — killed mid-flight, resumed from the journal\n'
    fi
    exit 0
fi
printf 'device-rig: the capability did not hold; the facts above say where\n'
exit 1
