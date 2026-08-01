# Roadmap

## Where this is going

Each rung is something the software can do, not something that was built. The
marker shows where it is now. This ladder is maintained by hand.

```
  can learn      signals captured, offline evaluation closes the loop
  can choose     work routed on device or to a server, one contract either way
  can recover    a killed run resumes from its journal
  can run        a multi-step run executes and streams
  can install    an app that launches on a device
> can build      the package compiles, the tests pass, the gates bite
```

Everything below the marker is done. Everything above it is not started.

## Findings

Dated, sourced to the unit that found them, with a disposition. Every entry
cites something re-runnable.

**2026-08-01 — INV-10 has no gate and cannot have one yet.** Unit 01. Every
step a run takes must be journalled before its effect is observable, and there
is no runtime to check. Disposition: revisit when the journal lands.

**2026-08-01 — the definition-of-done INV-8 proof was wrong three ways.**
Unit 01. It used BRE alternation, which is a GNU extension while `gates.yml`
runs on a macOS runner; a bare `generated with` that flags this repository's own
prose; and a hand-retyped family list that lost five of seven entries while
every control still passed. Disposition: fixed. `gate-hygiene` derives the list
from `.githooks/commit-msg` and uses `-E`. See ADR-0006.

**2026-08-01 — a check earns trust only by being watched go both ways.**
Unit 01. Two opposite defects came from the same cause: checks that could not
fail and read as passes, and one that could not pass and read as a failure.
Both had been written and never observed in either direction. Disposition: this
is the argument for `teeth.sh` asserting a clean tree exits 0 before planting,
and it is a working agreement in `CLAUDE.md`.

**2026-08-01 — teeth found a defect in a gate that had already passed its own
verification.** Unit 01. `gate-build` emitted absolute paths where the contract
requires repo-relative ones, because on macOS `$PWD` is the logical path and
the toolchain emits the physical one. The two spellings coincide in a checkout
and diverge only under a temporary worktree, so per-gate verification could not
have found it. Disposition: fixed; the affected commit was amended and its
gates re-verified. Re-run with `scripts/gates/teeth.sh`.

**2026-08-01 — a verification block is the one artifact nothing validates.**
Unit 01. Three rounds were lost to commit blocks that could not parse, while
the blocks were checking every file they committed. Disposition: every commit
block is now a file, syntax-checked with `bash -n … || exit 1` before it runs.

**2026-08-01 — review from the artifact, not from a rendering of it.** Unit 01.
Eight claims raised at an approval dialog did not survive measurement, all from
the same cause: stripped blank lines, a diff's removed line read as a
duplication, left-edge clipping. Every claim read from command text was real.
Disposition: a disputed line is printed from the file before it is acted on.

**2026-08-01 — `status.sh` reports plant cases, not teeth cases.** Unit 01.
Nine teeth cases exist and only eight are files; the ninth is a code path. A
"teeth-case count" would have been a hand-typed constant inside a generated
block. Disposition: the generated line counts
`scripts/gates/teeth/plant-*.sh` and names what it counted.

**2026-08-01 — no iOS 17 runtime is installed on the development host.**
Unit 01. `xcrun simctl list runtimes` reports 18.0, 18.3, 18.4, 26.0, 26.1 and
26.5. Disposition: a finding for unit 02, which adds the Xcode project. It is
the concrete cost of the `.iOS(.v17)` hole below.

## Known holes

Three kinds, labelled: an invariant with no gate, a gate with no plant, and a
gate whose check is a heuristic that can be wrong. Then everything else that is
true and uncomfortable.

**Invariants with no gate.** INV-6 — nothing in the tree stops a dependency
being added; the ADR requirement is a habit until a gate reads the resolved
dependency list. INV-10 — cannot be gated until there is a runtime. INV-11 —
read by hand, and the line between "what this is for" and "what this does" is
where the hand review earns its keep. INV-12 — no gate reads commit message
shape.

**Gates with no plant.** INV-1's positive direction: the plant exercises the
opt-down, which is what happens when somebody silences a concurrency error, and
nothing exercises a manifest that declares no tools-version at all.
`gate-test`'s running half: `plant-skipped-test.sh` covers the text scan that
finds a disabled test, and nothing plants a *failing* test, which the gate finds
by a different mechanism. Both are asserted at the gate's own verification and
neither is watched by the harness.

**Heuristics that can be wrong.** `gate-hygiene`'s force-unwrap check is
line-level and cannot find Swift's literal boundaries in general; multiline
strings, raw string delimiters and nested interpolation defeat it. It admits
its range rather than being quietly widened until a fixture passes. A
syntax-aware check needs SwiftSyntax, which is a dependency and so needs an ADR
under INV-6.

**Checks that live outside the harness.** The `status.sh` write boundary is
verified once at the commit that adds it, not by `teeth.sh`, because a worktree
holds only committed content and the script does not exist when the harness
lands. The transcription check proves every gate is *named* in a unit's
Constraints, which is mention rather than conformance — a section could name a
gate and say nothing true about it.

**Checks that differ between here and CI.** `gate-hygiene`'s `core.hooksPath`
check is skipped when `CI` is set, because a fresh `actions/checkout` has no
hooks path configured. So it runs in exactly one place anyone observes — its own
teeth case — and on a developer's machine, where nothing records whether it ran.

**Enforcement that can be stepped around.** The commit-msg hook is local
configuration and `git -c core.hooksPath=/dev/null commit` bypasses it for one
command, which is what `plant-ai-trailer.sh` does deliberately. CI is the only
layer of INV-8 a contributor cannot switch off. The same hook rejects a human
contributor actually named Claude, or one whose address is at a domain
containing one of the seven family tokens.

**The workflows land having never run, and this is the one place the unit's own
standard is not met.** `scripts/gates/gate-workflow.sh` checks them with
`actionlint`, which validates the workflow schema and — when `shellcheck` is on
`PATH`, as it was here — the `run:` blocks as well. So they are not unchecked.

What nothing checks is that `gates.yml` actually drives the harness against a
real checkout. A linter reads the file; only a push runs it, and this session
never pushes. Everything else in this repository was watched failing and watched
staying quiet before it landed; these two were shipped on reasoning. The reason
is structural rather than an omission, and the first push is what closes it.

**`gate-workflow` is the only gate outside the teeth harness.** It was watched
firing on a planted defect and staying quiet on a clean tree, by hand, but it
has no plant in `scripts/gates/teeth.sh`. The plant count stays at eight because
Acceptance names that number and a ninth needs a delta editing it. A later unit
that wants the ninth plant should take that delta.

**`actionlint` is optional, not a precondition.** Without it `gate-workflow`
returns 2 and so does `all.sh` — the contract's third code rather than a
failure, and the same shape as a host with no Swift. The cost is that a fresh
clone's `all.sh` reports "could not run" rather than green until the tool is
installed.

**Things nothing reads.** Sixteen paths in the tree are read by no gate:
`LICENSE`, `.gitignore`, `CLAUDE.md`, `README.md`, the ADR index and its six
records, this file, `docs/prompts/README.md`, `.claude/settings.json`,
`.claude/rules/gates.md` and `scripts/dev/bootstrap.sh`. For documentation that
is expected. One is worth naming because something other than a human acts on
it: `.gitignore` is read by git, so a wrong line either commits a per-machine
override or silently hides a tracked path, and no gate would notice either.

The two workflow files were in this set until `gate-workflow` was added.

**`.iOS(.v17)` is declared and never compiled.** Every gate runs against the
host, so the deployment target ADR-0004 argues for is asserted and not
exercised. Closing it needs an iOS SDK build, which needs the Xcode project.
The host has no iOS 17 runtime installed either, so it could not be compiled
here today.

**`scripts/dev/**` is ask-gated but is not a ratification stop.** So
`bootstrap.sh` — which sets `core.hooksPath` and therefore carries INV-8's
entire local layer — can be changed with a prompt and without a plan. That
asymmetry is deliberate: the stops exist for files whose contents are
architectural, and `bootstrap.sh` is operational.

**A fresh session opens in plan mode.** `permissions.defaultMode` is `plan`,
which is right when starting a unit and friction when making a one-line fix.

**A gate that installs its own `EXIT` trap** would replace the one in
`contract.sh` and leak a tally file. No gate does; nothing enforces it.

**The teeth harness has run on one machine.** `scripts/gates/teeth.sh` takes
about 42 seconds there, warm, on Apple Silicon. A GitHub macOS runner is a
different machine with a cold cache. Whether it can run on every push is a
measurement for whichever unit first pushes.

## Next units

1. **App shell.** An Xcode project wrapping the SPM modules, with the
   Info.plist, entitlements and background-task identifiers later units need.
   Until this lands, nothing runs on a device and no launch, memory or UI
   measurement is possible.
2. The journal, and a test that kills the process and resumes from it.
3. The streaming contract, with a recorded-fixture test.
4. The on-device gate that decides local against server, and a second engine
   behind the same contract.
5. Signal capture and an offline evaluation loop.
6. Performance and memory instrumentation.
7. A remote-config-backed feature flag service.
8. An `EntitlementProviding` protocol with an always-entitled stub, decided
   while the module boundaries are still soft rather than retrofitted through
   call sites later.
