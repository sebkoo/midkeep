# 03 — app shell

## Status

Open. This is the unit's driving prompt, filed 2026-08-03 as the unit's
first act, before any other work — the ordering unit 02's retrospective
tense exists to make visible, restored here. From its landing the
never-edit rule binds everything above the amendment log, which this
file carries from birth.

## Preconditions

Read `CLAUDE.md`, `docs/ROADMAP.md` and
`docs/prompts/02-going-public-and-enforcement.md` before anything else.
The first act of the unit is this file, lightly formatted to the
unit-01 skeleton, at `docs/prompts/03-app-shell.md` — before any other
work.

## Intent

The app shell: a minimal iOS app target that wraps the existing SPM
package (MidkeepApp -> MidkeepUI -> MidkeepKit), builds with zero
warnings, launches on a simulator, and installs on the owner's phone.
The ladder row "app shell" flips to landed only when the install is
measured, because that row's words are "install it on a phone and watch
it launch" and a status is a claim measurable against the tree.

The screen the shell shows is honest: it renders what exists — the
app's name and the true state of the work (no journal yet, no runs
yet) — not a mock of features that do not. A shell that fakes its
insides on day one breaks the only rule this repository has never
broken.

## Opening docs commit, before any code

One commit carrying: this prompt file; the ladder repair, third event
included — row numerals 01–09 dropped, column header "Unit" renamed
"Capability" so the word unit appears in exactly one column (Driven by,
the sole numeral namespace, anchored by `docs/prompts/` filenames);
ROADMAP's Next-units enumeration lettered or dropped in the same commit
so the collision dies rather than migrates; the Findings entry
recording all three collision events with dates and the twice-overtaken
first repair; and the regenerated status block, which should now show
landed units 2 and unit 02's record span — the prediction filed when
the span derivation landed.

## Non-goals

No journal, no streaming, no model calls, no server. No background
execution: the shell declares NO UIBackgroundModes and NO
BGTaskSchedulerPermittedIdentifiers — the push/pull decision and
ADR-0007's open questions stay visibly open, and an empty declaration
is the honest spelling of "undecided". ADR-0008 (whose server) stays a
deferred marker. The three bypass plants owed before INV-2/INV-3/INV-7
marks return to enforced stay deferred with their marker — record where
they now belong, do not fold them in silently.

## Constraints

The owner's standing constraint, verbatim: no paid charges, ever. For
this unit that means: free personal-team signing only — no paid Apple
Developer Program, no TestFlight. CI stays on the standard hosted
runners already allowlisted by gate-runners; any simulator build rides
the existing macos-15 jobs' INV-13 markers. Every workflow or
Package.swift or scripts/gates change remains a ratification stop.

Harness deltas are minimal and each is its own decision: the app
target's sources must be visible to gate-arch (INV-3: SwiftUI stays in
MidkeepUI and the app layer) — either place them under a directory the
gate already scans or extend its scope WITH a plant in the same commit,
the born-enforced convention. INV-5 (warnings-as-errors) must bind the
xcodebuild path the same way it binds swift build, and the record must
say how that is enforced or that it is hand-checked, INV-11 style.

## Acceptance — predictions filed before the work

1. The opening docs commit lands as specified; the block shows landed
   units 2 and unit 02's span.
2. An app target exists wrapping MidkeepApp; xcodebuild builds it for
   the iOS simulator with zero warnings, locally and in CI, on the
   free runners.
3. The app launches in the simulator and renders the honest screen.
4. The owner installs it on a phone with free personal-team signing
   and watches it launch — the measurement that flips the ladder row.
5. gate-arch's verdict covers the app sources; all.sh 0; teeth all
   green, case count unchanged unless a gate's scope grew, in which
   case its plant landed in the same commit.
6. Every figure in the record names what it counted; every measurement
   names its instrument; the timing series gains CI points only on its
   stated basis.

## Mode

auto. The ask list is unchanged and is the ratification mechanism.
Standing effort high; raise to max for any commit touching
`Package.swift`, `scripts/gates/**`, `.githooks/**`, or
`.github/workflows/**`. Feature code in `Sources/` and the app target
flows without dialogs — the approval volume of unit 02 was a property
of harness work, not of the mode. The reviewer relay continues: stop at
draft for every ratification stop; commits land only after review.

## Results

Closed 2026-08-04 (UTC) by the commit carrying this section. The Status
section above records the filing and is left as written, per the
never-edit rule; this section is an addition below the filed prompt,
not an edit of it, and the amendment log is empty — nothing above
needed correcting.

The six acceptance items, each with what discharged it:

1. The opening docs commit landed as `e9d923e`, green on runs
   30873597996 and 30873597904. The block's prediction split between
   letter and meaning — the record count read 3 because this prompt
   filed first, and the label was renamed to name what it counts —
   ROADMAP → Findings, 2026-08-03.
2. The app target landed as `56621c4`: xcodebuild for the simulator
   with zero warning lines, locally (Xcode 26.6, 17F113) and on CI
   (Xcode 16.4, 16F6, run 30877538825, the step at 30 seconds), on the
   standard hosted runner already markered for INV-13.
3. The honest screen launched in an iPhone 16 Pro simulator, iOS 18.0
   runtime, and rendered its three lines; screenshot taken in the
   landing session, derivations recorded in the ratification entry.
4. The owner installed and launched it on a phone with free
   personal-team signing: iPhone 16 Pro Max (iPhone17,2), iOS 26.5.2
   (23F84), `devicectl device info apps` reading
   `Midkeep dev.midkeep.Midkeep 1.0 (1)` from the connected device,
   2026-08-04T05:05Z. The ladder row flipped to landed in the closing
   commit.
5. gate-arch's verdict covers the app sources through two clauses that
   landed with their two plants in `56621c4`; teeth stands at
   `plant cases 14, contract cases 1, failures 0` locally and on CI,
   and `all.sh` exited 0 over nine gates at every landing.
6. Held as a standing property: every figure in the unit's entries
   names what it counted and its instrument, and the timing series
   took its CI points on the stated basis — 31 seconds for fifteen
   cases the latest.

## Amendment log

Nothing yet. Corrections land here, dated, and never edit the text
above.
