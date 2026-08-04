# 04 — the journal

## Status

Open. This is the unit's driving prompt, filed 2026-08-04 as the
unit's first act, before any other work — the ordering unit 03
restored and this unit inherits. From its landing the never-edit rule
binds everything above the amendment log, with one exception declared
at filing rather than claimed later: the Results section below is
filed empty so that the close can fill it as an addition, the shape
unit 03's close used.

## Preconditions

Read `CLAUDE.md`, `docs/ROADMAP.md` — the unit 04 prelude at the end
of Findings, Known holes, and the deferred items units 02 and 03 left
on the table — and `docs/prompts/03-app-shell.md` before anything
else. The first act of the unit is this file, on the unit-03 skeleton,
at `docs/prompts/04-the-journal.md` — before any other work.

## Intent

The journal: ADR-0002 made executable. An append-only journal in
`MidkeepKit`, a job honest enough to be worth journalling, and
resume-after-kill measured on the owner's phone. The acceptance bar is
the ladder row's capability sentence, already written in `README.md`:
"Close the app in the middle of a job and open it again; the job
carries on from where it stopped instead of starting over." The row
flips only when that is measured on a phone, never when code lands.

The honest-screen rule extends here. The app is three lines of text,
and the journal must not fabricate work in order to have something to
record. What a "job" honestly is while that is true is the first
ruling of the unit's decision brief, which precedes implementation —
this prompt does not pre-decide it.

INV-10 is the invariant this unit exists to serve. It has been
UNENFORCED since unit 01 because no runtime existed to check; the
journal is the artifact it has been waiting for, and the 2026-08-01
finding's disposition — revisit when the journal lands — comes due in
this unit.

## Opening docs commit, before any code

One commit carrying: this prompt file; the ladder row "the journal"
gaining its Driven-by mark, "unit 04, open", the word read from this
file's Status section per the rider convention, while the row's
Status stays "not started" — status follows artifact, and no journal
exists; the ROADMAP Next-capabilities bullet for the journal gaining
"Driven by unit 04, opened 2026-08-04"; and the regenerated status
block.

Predictions for the block, filed here because the commit measures
them: unit records filed reads 4; the unit 04 record span row reads
"file not committed yet", because the block is generated before the
commit that carries it and describes that commit's parent; and on the
push carrying this commit the prose gates' scanned counts move from
18 and 19 to 19 and 20, the delta being exactly this file.

## Non-goals

No streaming, no model calls, no server, no routing. No background
execution: `UIBackgroundModes` and `BGTaskSchedulerPermittedIdentifiers`
stay undeclared, ADR-0007's push/pull question stays visibly open, and
resume in this unit means a foreground relaunch reading the journal,
never the system keeping work alive. ADR-0008 (whose server) stays a
deferred marker. No third-party dependency unless the brief's ruling
chooses one, in which case its ADR lands before it (INV-6). No device
measurement on CI, ever, and no paid device farm — the prelude's
boundary. The three bypass plants owed before the INV-2/INV-3/INV-7
marks return to enforced stay deferred with their marker.

## Constraints

The owner's standing constraint, verbatim: no paid charges, ever. For
this unit that means the kill-and-relaunch measurements run on the
local rig — scripted `devicectl`, XCUITest device destinations — and
CI covers everything up to the device, on the standard hosted runners
`gate-runners` already allowlists. Every workflow, `Package.swift` or
`scripts/gates` change remains a ratification stop.

From the journal's first commit INV-10's wording binds the code:
every step journalled before its effect is observable, no run state
living only in memory. Whether the mark moves off UNENFORCED, and to
what, is a brief decision — a mark moves only with enforcement, the
rule the INV-2/INV-3/INV-7 findings set.

Package code lands where the gates already read: journal and run
types in `Sources/MidkeepKit`, views in `Sources/MidkeepUI`,
composition in `Sources/MidkeepApp`, under INV-3's permission form.
The `App/` shim stays a handful of lines — INV-2, INV-4 and the
format rule are unenforced there, the Known-holes boundary. Any gate
scope growth takes its plant in the same commit, the born-enforced
convention.

Sequencing: this docs commit, then the decision brief, then a full
stop for ruling. Implementation does not start until the brief is
ruled, and every implementation commit traces to a ruling.

## Acceptance — predictions filed before the work

1. The opening docs commit lands as specified, and the block
   predictions filed above hold as measured on the push carrying it.
2. The decision brief is delivered in-session after this commit and
   ruled per decision before any implementation commit exists.
3. The journal lands in `Sources/MidkeepKit` with package tests that
   run on the existing free runners: append, read-forward
   reconstruction, reopen-as-relaunch, and the torn-tail case — each
   test watched going both ways, seen failing on a planted defect
   before its green is trusted.
4. A job that honestly exists, as ruled, runs on the phone; killing
   the process mid-job and relaunching continues from the journal,
   measured on the local rig with the facts derived from the device
   rather than transcribed from the act. That measurement, and only
   it, flips the ladder row.
5. `all.sh` exits 0 over all nine gates and teeth closes with
   failures 0 at every landing; the case count changes only with a
   scope growth whose plant lands in the same commit.
6. Every figure names what it counted and its instrument; findings go
   to ROADMAP dated, kept, and annotated; a finding of absence
   carries a positive control.

## Mode

auto. The ask list is unchanged and is the ratification mechanism.
Standing effort high for prose and decisions; max for anything
touching `scripts/gates/**`, `Package.swift`, `.githooks/**`,
`.github/workflows/**`, or any gate or harness code this unit adds.
Never push — the owner types the push command. Stop at draft for
every ratification stop; implementation begins only after the brief
is ruled.

## Results

Empty at filing, by design: results land here when the unit closes,
as an addition below the filed prompt rather than an edit of it, and
the emptiness declared now is what makes that filling an addition.

Closed 2026-08-04 (UTC) by the commit carrying this text, added below
the declaration above exactly as it provided for. The six acceptance
items, each marked against what discharged or disproved it:

1. Confirmed. The opening commit landed as `24b254a`, green on runs
   30924525654 and 30924525125; the prose gates printed 19 and 20 as
   predicted, the block figures held as filed, and teeth ran fifteen
   cases in 48 seconds on the series' stated basis (ROADMAP →
   Findings, the measured entry).
2. Confirmed. The brief was delivered in-session after `24b254a` and
   ruled per decision, with one amendment taken at review — the
   corrupt-middle refusal — and every implementation commit names its
   ruling.
3. Confirmed. `Journal.swift` landed in `48122a8` with seven package
   tests, each watched failing under at least one of seven planted
   mutants before its green was trusted, and the torn-tail/
   corrupt-middle pair watched discriminating in both directions. The
   CI run over these commits follows the owner's push and is recorded
   in ROADMAP when taken.
4. Confirmed. The rehearsal job ran on the phone: pid 2708 SIGKILLed
   at +5 seconds inside step 2, the plain relaunch carried on — both
   attempts kept, earlier steps not re-run, four distinct products,
   the post-kill journal a byte-prefix of the final one — every fact
   derived from the device (iPhone17,2, build 23F84) by
   `scripts/dev/device-rig.sh`, judge exit 0. The ladder row flipped
   in the closing commit, on this measurement and no other.
5. Falsified in part, repaired before close. `all.sh` exited 0 at
   every landing, but teeth was not run at `48122a8`, `fbf6fa9` or
   `ac04756` and was red there — six plants anchored on the deleted
   placeholder files, `failures 6`, measured twice. Caught at close,
   repaired at a ratification stop by ruling (self-contained plants,
   `2931c0f`), teeth back to `failures 0` over fourteen plants and
   the contract case. ROADMAP carries the mechanism, the three SHAs,
   and the deferred enforcement — teeth-at-every-landing has no
   mechanism yet, and a `.githooks/` hook is the named candidate.
6. Held as a standing property: every figure names what it counted
   and its instrument, findings are dated in ROADMAP, and the rig
   judge's fixtures gave its finding of absence the positive controls
   the rule demands.

## Amendment log

Nothing yet. Corrections land here, dated, and never edit the text
above.
