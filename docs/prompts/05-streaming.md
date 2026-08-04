# 05 — streaming

## Status

Open. This is the unit's driving prompt, filed 2026-08-04 as the
unit's first act, before any other work — the ordering units 03 and
04 held and this unit inherits. From its landing the never-edit rule
binds everything above the amendment log, with the same exception
units 03 and 04 declared at filing: the Results section below is
filed empty so that the close can fill it as an addition rather than
an edit.

## Preconditions

Read `CLAUDE.md`, `docs/ROADMAP.md` — the unit 04 findings, Known
holes, and the deferred items on the table: the teeth-at-every-landing
mechanism, the three bypass plants, the whose-server cluster — and
`docs/prompts/04-the-journal.md` before anything else. ADR-0002,
ADR-0007 and ADR-0008 are this unit's inheritance. ADR-0007 already
names what the device journals for a stream — "the offset a stream
resumed from" — and that sentence is the oldest committed claim this
unit must either make true or amend on the record. The first act of
the unit is this file, on the unit-04 skeleton, at
`docs/prompts/05-streaming.md`.

## Intent

Streaming: a step's answer arriving as it is written. The acceptance
bar is the ladder row's capability sentence, already written in
`README.md`: "Watch a step's answer arrive as it is written, rather
than waiting for the whole thing to finish." The row flips only when
that is measured, never when code lands.

No server exists and whose-server is undecided, so nothing in this
unit may depend on a live endpoint. The streaming bullet has named
its own shape since unit 01: the streaming contract, with a
recorded-fixture test. What a stream honestly is under those
conditions — what produces it, what the contract looks like, what a
fixture records and where it lives — is the first ruling of the
unit's decision brief, which precedes implementation; this prompt
does not pre-decide it.

INV-10 is the invariant this unit presses on. Its PARTIAL boundary
says a test sees only the step types it drives, and a streaming step
is exactly the step type no test has driven. ADR-0002's own word for
observable includes "a token delivered to the user", so a stream
makes ADR-0002's cost paragraph measurable for the first time: what
the journal records per chunk of a stream, and what that recording
costs, are brief decisions owed a measurement, not defaults to
inherit.

## Opening docs commit, before any code

One commit carrying: this prompt file; the ladder row "streaming"
gaining its Driven-by mark, "unit 05, open", the word read from this
file's Status section per the rider convention, while the row's
Status stays "not started" — status follows artifact, and no
contract exists; the ROADMAP Next-capabilities bullet for streaming
gaining "Driven by unit 05, opened 2026-08-04"; and the regenerated
status block.

Predictions for the block, filed here because the commit measures
them: unit records filed reads 5; the unit 05 record span row reads
"file not committed yet", because the block is generated before the
commit that carries it and describes that commit's parent; and on
the push carrying this commit the prose gates' scanned counts move
from 20 and 21 to 21 and 22, the delta being exactly this file.

## Non-goals

No server, no live endpoint, no network transport: whether SSE or
anything else carries a real stream is decided with whose-server,
which stays a deferred marker, and the `sse` topic stays deferred
with it. No model calls. No background execution: `UIBackgroundModes`
stays undeclared, ADR-0007's push/pull question stays visibly open,
and a resumed stream in this unit means a foreground relaunch reading
the journal, never the system keeping work alive. No third-party
dependency unless a ruling chooses one, in which case its ADR lands
first (INV-6). No device measurement on CI, ever, and no paid device
farm. The three bypass plants owed on INV-2/INV-3/INV-7 stay
deferred with their marker. Whether this unit takes up the
teeth-at-every-landing hook is a brief decision rather than a
pre-commitment: unit 04 closed naming the mechanism deferred, with
`.githooks/` the candidate and its own ratification stop.

## Constraints

The owner's standing constraint, verbatim: no paid charges, ever.
Free hosted runners inside `gate-runners`' allowlist, free
personal-team signing, and the device measurements on the local rig —
`scripts/dev/device-rig.sh` and `devicectl`, extended only by ruling.
Every workflow, `Package.swift`, `.githooks/**` or `scripts/gates/**`
change remains a ratification stop.

INV-10's wording binds every streaming step from its first commit:
journalled before its effect is observable, no run state living only
in memory. Whether the ordering test grows to drive the streaming
step, and whether the mark's row text changes, are brief decisions —
a mark moves only with enforcement, the rule the INV-2/INV-3/INV-7
findings set.

Package code lands where the gates read: contract and stream types
in `Sources/MidkeepKit`, views in `Sources/MidkeepUI`, composition
in `Sources/MidkeepApp`, under INV-3's permission form. The `App/`
shim stays a handful of lines — the Known-holes boundary. Any gate
scope growth takes its plant in the same commit, the born-enforced
convention. A recorded fixture is committed text: it carries no host
path, no personal address and no secret, and the prose gates do not
read `Tests/`, so the rule binds where the tool does not reach — the
INV-14/INV-15 posture, not a new one.

Sequencing: this docs commit, then the decision brief, then a full
stop for ruling. Implementation does not start until the brief is
ruled, and every implementation commit traces to a ruling.

## Acceptance — predictions filed before the work

1. The opening docs commit lands as specified, and the block and
   prose-gate predictions filed above hold as measured on the push
   carrying it.
2. The decision brief is delivered in-session after this commit and
   ruled per decision before any implementation commit exists.
3. The streaming contract lands in `Sources/MidkeepKit` with package
   tests that run on the existing free runners, driven by a recorded
   fixture rather than a live endpoint — each test watched going
   both ways, seen failing on a planted defect before its green is
   trusted.
4. The capability sentence is measured on hardware with the facts
   derived from the device rather than transcribed from the act:
   partial output observable before the step's completion, and a
   process killed mid-stream resuming as ruled — the journalled
   offset ADR-0007 names is the inherited shape. That measurement,
   and only it, flips the ladder row; "time to first token" enters
   README's measurement table with its instrument named.
5. `all.sh` exits 0 over all nine gates and teeth closes with
   failures 0 at every landing; the case count changes only with a
   scope growth whose plant lands in the same commit.
6. Every figure names what it counted and its instrument; findings
   go to ROADMAP dated, kept, and annotated; a finding of absence
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

1. Confirmed in meaning, its letter split by batching. The opening
   commit landed as `f88e700` with the block predictions holding as
   filed. The prose-gate prediction — 21 and 22 on the push carrying
   the commit — assumed a push per commit; no push happened until the
   unit's close, and the pre-push hook later added a 23rd
   address-scope file, so the batched push will print 21 and 23. The
   per-commit local gate runs recorded 21 and 22 before the hook and
   21 and 23 after, confirming the meaning: the opening's delta was
   exactly this file. The CI half of this item is measured at the
   push and recorded in ROADMAP when taken.
2. Confirmed. The brief was delivered in-session after `f88e700`,
   ruled per decision with riders, and every implementation commit
   names its ruling; two mid-landing shape rulings — the ADR
   amendment's position and the mutant table's location — were taken
   at their commits and honored.
3. Confirmed. The contract landed in `77a6ae1` and the rehearsal
   stream with its fixture in `283e4f8`, thirteen mutants watched
   across the two landings — nine of code, four including a tamper of
   the committed fixture — every new test seen failing before its
   green was trusted, 27 of 27 restored. The tests are plain
   `swift test` and run on the existing free runners; the CI run
   follows the owner's push.
4. Confirmed, on the phone, fourth run of the extended rig: killed at
   +11 s with 23 chunk records and 64 answer bytes on record and no
   completion, resumed through `streamResumed(fromOffset: 64)` with
   contiguous offsets and no re-emitted byte, final artifacts
   byte-equal to the uninterrupted control run's, judge exit 0, every
   fact derived from the device (iPhone17,2, 23F84). That run and no
   other flipped the row. Time to first token entered README's table
   from the same run — 8.2 to 8.6 s by the rig's external poll — with
   the simulator's single-process 9.44 s beside it and the pacing
   caveat on both. Two instrument defects found on the way are
   findings in ROADMAP, each caught by its own check.
5. Held in meaning, its letter narrowed and stated: `all.sh` exited 0
   at every landing; teeth ran green at the opening and at both code
   landings — the only commits that could move it, since no gate
   reads `scripts/dev/` or `.githooks/` — and not after every docs
   commit. The pre-push hook landed mid-unit (ruling D6), so the push
   boundary is now enforced rather than habitual; the close's final
   sweep ran both instruments green over the finished tree.
6. Held as a standing property: every figure names what it counted
   and its instrument, findings are dated in ROADMAP with two
   retractions handled by refusal rather than erasure — an uncaptured
   TTFT recorded as not existing, an impossible reading refused and
   its cause measured — and the fixture's finding of absence carries
   the provenance test as its standing positive control.

## Amendment log

Nothing yet. Corrections land here, dated, and never edit the text
above.
