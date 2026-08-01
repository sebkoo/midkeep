# 3. Three modules, one direction

Date: 2026-08-01

Status: Accepted

## Context

Module boundaries drawn after there is code to move are drawn around whatever
already imports whatever. Drawn before, they cost nothing and they constrain
what can be written next.

## Decision

Three targets in one direction. `MidkeepApp` depends on `MidkeepUI`, which
depends on `MidkeepKit`, which depends on nothing.

`MidkeepKit` holds runs, the journal and the engine contracts. It imports no UI
framework and no third-party module. `MidkeepUI` may import SwiftUI and
`MidkeepKit`, and nothing else. `MidkeepApp` is the composition root, and
nothing imports it.

This is INV-3, enforced by `scripts/gates/gate-arch.sh`, which reads imports at
source level. The rule is stated in the gate as an allowlist rather than a list
of banned frameworks, so a module nobody anticipated is a finding rather than a
silent pass.

Swift Package Manager is the source of truth. There is no Xcode project at this
commit.

## Why `MidkeepApp` is a library product

A reader opening `Package.swift` will ask this within ten seconds, and an
unexplained shape in a manifest reads as a mistake.

`MidkeepApp` is the composition root, and at this commit it composes nothing.
An executable target would need a `main.swift` or an `@main` type, which is
feature code this unit does not write, and an executable product would be
meaningless on the iOS platform the package targets anyway. The application
target arrives with the Xcode project and will depend on this library.

Exposing all three targets as library products has a second reason. `MidkeepApp`
is the one target nothing else depends on, so it reaches the build only through
a product of its own. Whether a given SwiftPM version also builds unreferenced
targets is a detail that changes between releases, and this repository should
not rest on it.

Until the app target exists, `MidkeepApp` is a boundary drawn before there is
anything to put on either side of it. That is the point.

## The cost, stated rather than discovered later

SPM-only means a third-party binary framework has nowhere convenient to go. The
earlier repository this work draws on ran Core ML and TensorFlow Lite behind a
single engine contract, and bringing TensorFlow Lite back here will require
either a vendored `xcframework` in the tree or an ADR relaxing INV-6.

That is a known cost of choosing SPM as the source of truth, not an oversight.
It is written here so the unit that hits it inherits a decision rather than a
surprise.

## Consequences

`MidkeepKit` cannot reach for a UI type to make something convenient, which is
the constraint doing its job and will occasionally be annoying.

`gate-arch` needs only a checkout and git, so it still reaches a verdict on a
host with no Swift toolchain. That is a property of reading imports as text
rather than compiling, and it is why two of the six gates stay useful when the
other three cannot run.
