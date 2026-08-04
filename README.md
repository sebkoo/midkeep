# midkeep

```
  step 1   rename the photos    done
  step 2   file them            done
  step 3   write the index      done
  step 4   summarise            working...
           *** interrupted ***
  relaunch
  step 4   summarise            picks up here
```

Phones get interrupted. Apps remember finished work and discard unfinished
work. This repository asks what changes when unfinished work is first-class
data.

[![gates](https://github.com/sebkoo/midkeep/actions/workflows/gates.yml/badge.svg?branch=main)](https://github.com/sebkoo/midkeep/actions/workflows/gates.yml)
[![ci](https://github.com/sebkoo/midkeep/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/sebkoo/midkeep/actions/workflows/ci.yml)
[![harness](https://img.shields.io/endpoint?url=https%3A%2F%2Fraw.githubusercontent.com%2Fsebkoo%2Fmidkeep%2Fmain%2Fdocs%2Fharness-badge.json)](docs/harness-badge.json)
[![Swift 6](https://img.shields.io/badge/Swift-6-orange)](Package.swift)
[![iOS 17+](https://img.shields.io/badge/iOS-17%2B-blue)](docs/adr/0004-ios-17-deployment-target.md)
[![MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

## What this does, for anyone

Say you ask an assistant to tidy up two hundred holiday photos: give each one a
name based on what is in it, sort them into folders by place, and then write a
list of what ended up where. That is not one task, it is three, and the third
depends on the first two. It takes a while.

Now the phone rings. Or you walk into a tunnel. Or you switch to another app
long enough that the system reclaims the memory. In most apps, what you come
back to is a spinner that has stopped meaning anything, or a screen that has
forgotten there was ever a job — and the two hundred photos are untouched, so
you start again.

The work was done. The first two steps had finished. Nothing had written them
down anywhere that survives the app being taken away. This project is an
attempt at the other thing: a job that knows which of its own steps are
finished, so that coming back means continuing rather than restarting.

<!-- demo:here -->

## What this cannot do yet

There is no journal, so nothing resumes yet. The app shell builds and launches
in a simulator and says exactly that on its one screen; it has not been
installed on a phone, which is the measurement its ladder row waits for. What
exists besides the shell is the harness — the checks, and the proof that each
one fails when it should.

See [the roadmap](docs/ROADMAP.md).

## Where this is right now

One row per planned capability, in plain language: what someone who does not
read code could do once that row lands. The rows carry no numbers, and the word
"unit" appears in exactly one column — Driven by, which maps each row to the
driving units that served it. Driving units are the numbered work-session
records in `docs/prompts/`; their filenames anchor the only numeral namespace
this table uses. A driving unit still open is marked so — "unit 03, open" —
the word read from that record file's own Status section, so effort in flight
is visible without an unmeasurable status entering the Status column. The
rows were numbered 01–09 until 2026-08-03, under a first
column headed "Unit", and that numbering collided with the driving-unit
numbering three times in one day — ROADMAP → Findings records all three events
— so the repair removed the namespace instead of explaining it. The commit
span of every filed driving-unit record is derived into the status block below
by `scripts/status.sh`, and a driving unit with no filed record shows no span
there. A status is a claim measurable against the tree: landed means the row's
artifact exists, not started means its first artifact does not. The words here
are still written by hand; the numbers live in the generated block.

| Capability | What you could do once it lands | Status | Driven by |
|---|---|---|---|
| repository and harness | Nothing — there is no app to open. The work here built the checks that guard every row below, and watched each one fail on purpose. | landed | units 01 and 02 |
| app shell | Install it on a phone and watch it launch. | not landed — builds and launches in a simulator; no phone install measured yet | unit 03, open |
| the journal | Close the app in the middle of a job and open it again; the job carries on from where it stopped instead of starting over. | not started | none yet |
| streaming | Watch a step's answer arrive as it is written, rather than waiting for the whole thing to finish. | not started | none yet |
| on-device or server | Keep a job moving with no signal, because the work can run on the phone instead of being sent away. | not started | none yet |
| signals and evaluation | Nothing new to do. The app keeps a record of how jobs went, so a change can be checked against the runs that came before it. | not started | none yet |
| performance and memory | Nothing new to do. How long a job takes and how much memory it uses becomes something anyone can measure. | not started | none yet |
| feature flags | Get a fix or a change without waiting for an App Store update. | not started | none yet |
| entitlements | Paid features can be told apart from free ones. Until then everything is unlocked. | not started | none yet |

<!-- status:begin -->
| | |
|---|---|
| version | no tag yet |
| commits | 30 |
| last commit | 2026-08-04 |
| gates | 9 |
| teeth plant cases | 14 |
| unit records filed | 3 |
| unit 01 record span | b853d54..b853d54, 1 commit touches it |
| unit 02 record span | 286d55b..286d55b, 1 commit touches it |
| unit 03 record span | e9d923e..e9d923e, 1 commit touches it |

A record span counts commits touching that file, not the unit's
whole work. The block is generated before the commit that carries
it and describes that commit's parent. Generated by
`scripts/status.sh`. Do not edit between the markers.
<!-- status:end -->

## The question

An iOS client can lose a run in four distinct ways, and they are not variations
on one problem. The system can suspend the app, which stops execution without
warning it. The system can terminate the app outright to reclaim memory, so
nothing in memory survives. The network can drop partway through a response, so
a step is neither finished nor cleanly failed. And the person can cancel, which
has to stop the work rather than merely stop showing it.

The question this repository exists to answer is what an iOS client looks like
if the unit of persistence is the half-finished run rather than the finished
result. That means a partway state is something the software can name; a
completed step is written down before its effect is visible, so it survives all
four; stopping actually stops; and every run leaves a record of what was
attempted and what landed. The argument for recording a step before its effect
is [ADR-0002](docs/adr/0002-the-run-is-the-unit-of-persistence.md).

## How it is built

Three modules in one direction. `MidkeepKit` holds runs, the journal and the
engine contracts, and imports no UI framework and nothing third-party.
`MidkeepUI` may import SwiftUI and `MidkeepKit`, and nothing else. `MidkeepApp`
is the composition root, and only the app-shell shim in `App/` may import it.
Swift Package Manager stays the source of truth for the modules;
`Midkeep.xcodeproj` wraps them for the app target and holds no code of its
own.

The rule the design rests on is that a step is recorded before its effect
becomes visible outside the run. That permits a step recorded and not performed,
which is recoverable because the record says it was attempted — and it prevents
a step performed and not recorded, which is not, because nothing knows it
happened.

## Running it

Xcode 26 or a Swift 6 toolchain.

```
git clone https://github.com/sebkoo/midkeep.git
cd midkeep
scripts/dev/bootstrap.sh
swift build
swift test
scripts/gates/all.sh
```

## The harness

Each check exits `0` if it ran and found nothing, `1` if it ran and found
something, and `2` if it could not reach a verdict at all — a missing
toolchain, an unreadable configuration. That third code exists because a check
that could not run and a check that found nothing are different facts, and
collapsing them is how a repository ends up with green that inspected nothing.

Teeth-testing is the other half: for each check, plant the defect it claims to
catch in a throwaway copy of the repository, and confirm it fails. A check
nobody has watched fail is not a check. The contract is
[ADR-0005](docs/adr/0005-gate-exit-code-contract.md).

## What is measured and what is not

No measurements yet — this commit contains no runtime.

| | Will be filled by |
|---|---|
| Cold launch to first frame | not yet written; needs the app shell |
| Resume after termination | not yet written; needs the journal |
| Time to first token | not yet written; needs the streaming contract |
| Peak memory during a run | not yet written; needs instrumentation |

## Decisions

[docs/adr/](docs/adr/README.md)

## License

MIT. See [LICENSE](LICENSE).
