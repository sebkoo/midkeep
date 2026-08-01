# 4. iOS 17.0 as the deployment target

Date: 2026-08-01

Status: Accepted

## Context

An earlier repository by the same author pins iOS 26. That is comfortable to
develop against and it excludes most of the devices people are actually
carrying. A repository whose whole argument is about what happens when a real
phone gets interrupted should run on the phones being interrupted.

## Decision

`Package.swift` declares `platforms: [.iOS(.v17), .macOS(.v14)]`.

iOS 17.0 is the product target. It is low enough to install on hardware in
current use and high enough for the concurrency and SwiftUI features the run
engine and its views will need.

macOS 14 is declared for one reason: so `swift build` and `swift test` run on
the host and in CI. It is not a supported product surface. Nothing in this
repository is intended to ship as a macOS application, and a later unit adding
macOS support would need its own decision.

## What was measured

The obvious question is whether declaring platforms at all does anything, or
whether it is decoration that SwiftPM would supply by default. That was tested
rather than assumed, by removing `.macOS(.v14)` and building.

The first attempt proved nothing, and saying so matters more than the result.
With the platform removed, a package whose only SwiftUI usage was `import
SwiftUI` in `Sources/MidkeepUI/Placeholder.swift` built cleanly:

```
$ swift build          # platforms: [.iOS(.v17)]
Build complete! (16.61s)
```

The reason is not that the default is sufficient. Reading the target triple
from the compile of the SwiftUI-importing file:

```
with    .macOS(.v14)     -target arm64-apple-macosx14.0
without                  -target arm64-apple-macosx10.13
```

macOS 10.13 is *below* SwiftUI's minimum of 10.15. The build succeeded because
an unused import never triggers availability checking at all. Importing a
framework does not subject a module to that framework's availability floor;
only using an API from it does.

Adding four lines that actually use SwiftUI, with the platform still removed:

```
$ swift build          # platforms: [.iOS(.v17)], Probe.swift declares `struct Probe: View`
exit=1
Sources/MidkeepUI/Probe.swift:4:20: error: 'View' is only available in macOS 10.15 or newer
```

And with `.macOS(.v14)` restored, the identical source compiles:

```
$ swift build
Build complete! (1.18s)
```

So the platform declaration is load-bearing, and the probe that shows it is the
one that uses SwiftUI rather than the one that merely imports it.

## What this evidence is not about

The diagnostic above concerns macOS and SwiftUI's macOS minimum. This ADR's
subject is the iOS 17 deployment target, and no gate in this repository
compiles for iOS at all — every gate runs against the host, and the driving
prompt for this unit states that no simulator is needed. `docs/ROADMAP.md`
carries that under Known holes: `.iOS(.v17)` is declared and never exercised.

The measurement is still the right one to record here, because what it
establishes is that the platform list changes what the compiler will accept.
That generalises to the iOS entry. It is not, and must not be read as, evidence
about iOS 17 specifically.

The cost of that hole is concrete on this host. No iOS 17 runtime is installed:

```
$ xcrun simctl list runtimes
iOS 18.0, iOS 18.3, iOS 18.4, iOS 26.0, iOS 26.1, iOS 26.5
```

So `.iOS(.v17)` could not be compiled here even if a gate wanted to, without
first installing a runtime. That is a finding for the unit that adds the Xcode
project rather than for this one.

## Consequences

Anything the run engine or the views use has to be available on iOS 17.0, which
will occasionally mean writing something by hand that a newer API provides.

macOS 14 in the manifest is load-bearing for the build and misleading to a
reader who assumes it signals macOS support. This record is the place that says
it does not.
