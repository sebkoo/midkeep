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

## Amendment log

Nothing yet. Corrections land here, dated, and never edit the text
above.
