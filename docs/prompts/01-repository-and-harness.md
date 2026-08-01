# 01 — repository and harness

## Status

In progress. Phase 2 of five. No runtime, no device build; this unit ships the gates and the proof
that each one fails when it should.

## Preconditions

macOS with a Swift 6 toolchain installed — `swift --version` reporting 6.0 or later, and
`swift format --version` answering. The agent runs on that host rather than reaching it through a
file bridge, because `MidkeepUI` imports SwiftUI and three of the five gates shell out to the
toolchain. On a host without one, `gate-build`, `gate-test` and `gate-format` each return 2 and
`all.sh` returns 2. That is the contract working as designed and is not the definition of done.

No simulator is needed. Every gate in this unit runs against the host.

One tool is **optional rather than required**, and the distinction is the point.
`gate-workflow` uses `actionlint` — and `shellcheck` through it — to check `.github/workflows/`.
Neither is a precondition. When `actionlint` is absent that gate returns 2 with a reason and so does
`all.sh`, which is the contract's third code doing its job and is the same shape as a host with no
Swift. Adding it to the Preconditions would have made a fresh clone fail rather than report that it
could not look.

The versions observed for this run are recorded under Results.

## Intent

Build the harness before there is any Swift to check, because the cost of adding a rule grows with
the amount of code that has to change to satisfy it. On an empty tree INV-2 and INV-4 cost nothing;
on five thousand lines they cost a week and get waived.

Every unit from 02 onward answers one standing question in a sentence before it starts: does what
this unit builds lower the cost of proving something the software will do for a user, or does it
only demonstrate that the harness works. A repository whose checking apparatus outgrows the thing
being checked has inverted, and it inverts one reasonable-looking unit at a time. Unit 01 is exempt.
At this commit the harness is the entire repository, so the ratio is not yet a number that means
anything.

## Non-goals

This unit writes no feature code. There is no run engine, journal implementation, SQLite schema,
streaming parser, SSE client, API client, networking layer or persistence of any kind. Nothing
registers a background task, and no Core ML or TensorFlow Lite path is wired.

There is no Xcode project and no app target, so nothing builds for a device; the only SwiftUI in the
tree is a placeholder type with no members. Feature flags, entitlement code, the latency recorder,
the evaluation harness and any benchmark are later units.

No screenshot, recording, social preview, App Store metadata or privacy manifest is produced, and
coverage is not reported. The tree gains no third-party dependency, no `.claude/skills/` directory
and no second prompt file.

## Constraints

The gate specification, transcribed from the driving prompt before any gate script was written.
**This is the working copy.** The document it was transcribed from stops governing at the moment
this copy exists, and the gates are implemented against what is written here. Corrections made
during transcription are recorded under Falsified, citing the passage they correct.

```
driving prompt  -->  transcribed Constraints  -->  gate implementation
    seed only          the working copy            follows the copy
                       corrections enter here
                       and are logged under Falsified
```

If the implementation and this section disagree, the implementation is wrong — unless this section
is amended first, which is itself a Falsified entry. Amendments have one destination and the
authority chain runs one way.

### Preamble — `scripts/gates/lib/contract.sh`

Holds the shared preamble: `set -uo pipefail`, deliberately **not** `-e`, so that a grep which
legitimately matches nothing does not kill the script.

Helpers: `die_cannot_run`, `finding`, `need`, `finish`.

`finding` writes one line to stdout, `path:line: message`, and nothing else. `finish` is the only
exit path and it normalizes: any status other than 0, 1 or 2 becomes 2 with a reason on stderr.
Without that, `pipefail` turns a `grep | head` that closes its pipe early into exit 141, and a gate
silently reports a code the contract does not define.

### The exit-code contract

Stated once here and argued in ADR-0005.

- `0` — ran, found nothing.
- `1` — ran, found something. Findings on stdout.
- `2` — reached no verdict. Missing toolchain, no simulator. Reason on stderr.

Never 2 for findings. ADR-0005 also notes that Claude Code's hook protocol inverts the severity of
1 and 2, so gates are wrapped for hook use and never reused directly.

**Everything a gate prints to stdout is a finding.** `teeth.sh` counts stdout lines whose path is
the file a plant touched, so commentary, banners and progress belong on stderr. A gate that prints a
banner to stdout breaks every teeth case at once.

### `scripts/gates/gate-build.sh` — INV-5

Debug and release, both passing `-Xswiftc -warnings-as-errors`. The debug pass also passes
`--build-tests`.

Calls `need` first and returns 2, not 1, when the toolchain is absent.

Compiler diagnostics arrive on stderr as `path:line:col: error: …`. The gate parses them and
re-emits each through `finding`, so a failing build produces findings on stdout rather than only a
non-zero status.

### `scripts/gates/gate-test.sh` — INV-7

`swift test --parallel`, plus a grep for skipped tests. Swift Testing parallelises on its own; the
flag governs the XCTest half.

The skip grep covers both frameworks even though the tree uses only Swift Testing, so that a later
drift to XCTest does not silently disarm INV-7: `.disabled(`, `@Test(.disabled`, `XCTSkip`,
`withKnownIssue`, and any commented-out `@Test` or `func test` line.

`swift test` builds the test targets and what they depend on, so `MidkeepUI` and `MidkeepApp` may
never be compiled by it. That separation is intended: `gate-test` claims the tests pass,
`gate-build` claims everything compiles warning-free in debug and release, and neither substitutes
for the other. Do not make `gate-test` build the package to close the gap — `all.sh` runs both, and
a gate that quietly does another gate's work is a gate whose green means something other than its
name.

Calls `need` first; returns 2 when the toolchain is absent.

### `scripts/gates/gate-format.sh`

Claims no numbered invariant and is teeth-tested anyway.

`swift format lint --strict` against the committed `.swift-format`, over `Package.swift`, `Sources`
and `Tests`. `--strict` is load-bearing: without it lint exits 0 on warnings and the gate is
decorative. Without the configuration file the criterion it is strict about is whatever the
toolchain shipped with.

Diagnostics arrive on stderr as `path:line:col: error: [Rule] …` and are re-emitted through
`finding`, as in `gate-build`.

Calls `need` first; returns 2 when the toolchain is absent.

### `scripts/gates/gate-arch.sh` — INV-1 and INV-3

INV-1 is checked against the **text** of `Package.swift`, in two directions.

- Positive: the `swift-tools-version:` line reads 6.0 or later. That is what actually puts every
  target in Swift 6 mode, and the line is a comment by construction, so matching it is exact.
- Negative: no opt-down token appears — no `swiftLanguageMode` other than `.v6`, no
  `swiftLanguageVersions` below `.v6`, no `-strict-concurrency` below `complete`.

Both are needed. Under Swift 6 mode complete checking is implied and never appears in the manifest,
so an opt-down search alone passes a manifest that declares nothing at all, and a warnings check
sees neither failure.

The choice of text over a parsed dump is about which way the check fails. A text match can be fooled
by a token inside a comment, which produces a finding on a clean tree: red, immediately, and caught
by the clean-tree assertion every teeth case makes before it plants anything. Reading
`swift package dump-package` trades that for a key path that moves under a toolchain update, a
lookup that returns nothing, and nothing read as no violation. One failure shouts and the other
passes. Prefer the one that shouts, and accept the inelegance: this gate has no schema to track, no
temporary artifact, and nothing a Swift release can quietly take away.

Do not check INV-1 by building with `-Xswiftc -strict-concurrency=complete`. Forcing the flag on the
command line imposes the setting the gate is supposed to be verifying, so a target that opted down
still compiles under the forced flag and the check reports on a configuration nobody ships.

Do not add `swiftLanguageMode(.v6)` to each target to give the gate something to find. It is
redundant under tools-version 6, it is not how a manifest is written, and a reviewer reading it
concludes the author did not trust the default.

INV-3 is read from `Sources/`: no UI framework or third-party import under `MidkeepKit`, no import
in `MidkeepUI` other than `MidkeepKit` and SwiftUI, and no `import MidkeepApp` anywhere. Imports sit
at the top of a file and cannot appear inside an interpolation, so a line-level match is exact here
in a way it is not for INV-4.

Needs nothing but a checkout and git.

### `scripts/gates/gate-hygiene.sh` — INV-2, INV-4 and INV-8

Needs nothing but a checkout and git. With `gate-arch`, one of the two gates that still reach a
verdict on a host with no Swift.

**INV-2** — no `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency import` in
`Sources/`. Tests may, with `// INV-2-EXEMPT: <reason>`.

**INV-4** — no force unwrap or `try!` in `Sources/`. Tests exempt. This is a line-level grep and
cannot find Swift's literal boundaries: multiline strings, raw string delimiters and nested
interpolation pass it. The gate says so, and ROADMAP → Known holes says so. The rule is not softened
to match the tool.

**INV-8** — no AI-attribution trailer in any commit message.

Range resolution: `GATE_RANGE` if set; else `origin/main..HEAD` if `git rev-parse --verify
origin/main` succeeds; else all of `HEAD`. Then count the commits in whatever was resolved, and if
the count is zero, discard that range and fall back to all of `HEAD`. This is not defensive padding.
On a push to the default branch `HEAD` and `origin/main` are the same commit, so `origin/main..HEAD`
resolves successfully and contains nothing; without the count the gate would examine zero commits,
find nothing, exit 0, and report a green INV-8 that inspected no message at all.

The range actually used and the commit count are printed as the gate's first line **on stderr**, on
every run. A check whose scope is invisible is a check nobody can audit — and the stream matters:
stdout is findings only, so a range banner there would break every teeth case at once.

The INV-8 pattern uses `-E`. ERE alternation is POSIX and behaves identically on GNU and BSD grep;
BRE `\|` is a GNU extension, and `gates.yml` runs on a macOS runner with BSD grep and no Homebrew. A
gate whose pass criterion depends on which `grep` sits first in `PATH` is not reproducible.

The family list is **derived from `.githooks/commit-msg`** rather than restated:

```sh
family="$(sed -n "s/^family='\(.*\)'$/\1/p" .githooks/commit-msg)"
```

One source of truth. A family added to the hook is checked automatically; a family dropped from the
hook stops being claimed. The pattern mirrors the hook's three branches exactly — a
`Co-Authored-By:` line naming a family, a `Claude-Session:` line, and `generated with .*claude
code` — and no broader, because a bare `co-authored` flags a legitimate human co-author and a bare
`generated with` flags this repository's own prose.

The `core.hooksPath` check is skipped when `CI` is set, because a fresh `actions/checkout` has no
hooks path configured and the gate would fail on a clean tree.

The workflow sets `fetch-depth: 0` so that on a pull request the range is the branch's real commits
rather than a single shallow one.

### `scripts/gates/all.sh`

Prints one line per gate with its own code, then exits 2 if any gate returned 2, else 1 if any
returned 1, else 0. "Could not run" is the more urgent fact, and unknown is not safe. The precedence
is stated in ADR-0005.

### Teeth — `scripts/gates/teeth.sh`

Asserts three things per case, in a `git worktree` under a temp directory and never in the checkout:

1. the clean tree exits 0;
2. the planted defect exits **exactly 1** — a 2 means the gate broke, not that it caught something —
   and stdout carries the expected findings;
3. the worktree is removed either way.

Assertion 1 is per case, not once per gate. The clean run is what makes the plant mean anything: a
gate that fires on everything and a gate that fires on the defect are indistinguishable without it.

"Expected findings" is mechanical, not a judgement call. `finding` emits one line of
`path:line: message` per hit and nothing else on stdout, so a case asserts the number of stdout
lines whose path is the file the plant touched, and that number is one unless the case says
otherwise. Do not invent a per-plant expected string and do not match on message wording, which will
be reworded and will silently stop matching.

"Either way" is a `trap cleanup EXIT` installed **before** the worktree is created, not a line at
the end of the happy path — a plant that fails, a gate that dies, an assertion that aborts and a
Ctrl-C all have to land in the same cleanup. Guard the trap against `set -u` by testing
`${TEETH_WORKTREE:-}` before acting on it, `cd` back to the checkout inside `cleanup` before calling
`git worktree remove --force` — a working directory inside the worktree is the ordinary reason that
command fails and leaves the directory behind — and follow it with `git worktree prune`.

Worktrees are created detached: `git worktree add --detach "$dir" HEAD`, never a branch name.
`plant-ai-trailer.sh` commits inside the worktree, and on a branch that either fails outright as
already checked out or moves `main`. Detached leaves a dangling commit that `remove --force` and
`prune` discard.

A worktree contains committed content only, which is why the gates are committed at Commit 5 before
the harness that tests them at Commit 6. The gate is run from the worktree as the working directory,
invoked by its path inside the worktree, so the copy under test is the committed one.

Every plant script begins with:

```sh
[ -n "${TEETH_WORKTREE:-}" ] || { echo 'refusing to plant outside a teeth worktree' >&2; exit 2; }
```

### The eight plants

One plant per invariant a gate claims, not one per gate. `gate-hygiene` alone claims INV-2, INV-4
and INV-8, so it needs three. The count is read off the invariant table: INV-1, INV-2, INV-3, INV-4,
INV-5, INV-7 and INV-8 are claimed by a gate, which is seven; `gate-format` enforces no numbered
invariant and is teeth-tested anyway, which is the eighth. INV-6, INV-10 and INV-11 are claimed by
no gate. INV-9 is the property `teeth.sh` asserts about every other gate, so it is the harness
rather than a subject of it.

Each case names the invariant it exercises, or `format` for the one that claims none, so the count
is read off the output rather than trusted from a summary line.

| Plant | Gate | Exercises |
|---|---|---|
| `plant-lang-mode.sh` | `gate-arch.sh` | INV-1, negative direction only |
| `plant-ui-in-kit.sh` | `gate-arch.sh` | INV-3 |
| `plant-unchecked-sendable.sh` | `gate-hygiene.sh` | INV-2 |
| `plant-force-unwrap.sh` | `gate-hygiene.sh` | INV-4 |
| `plant-ai-trailer.sh` | `gate-hygiene.sh` | INV-8 |
| `plant-warning.sh` | `gate-build.sh` | INV-5 |
| `plant-skipped-test.sh` | `gate-test.sh` | INV-7 |
| `plant-bad-format.sh` | `gate-format.sh` | the `indentation` rule named in `.swift-format` |

`plant-force-unwrap.sh` plants one real force unwrap alongside each near-miss the check has to
survive — `!=`, a prefix `!` on a boolean, and `\(x!)` inside a string literal — and its case
asserts exactly one finding rather than a non-zero exit, so the exclusions are proved on those forms
and not merely asserted. What that does not prove is stated plainly in the gate and in ROADMAP: a
line-level grep cannot find Swift's literal boundaries in general. A syntax-aware check needs
SwiftSyntax, which is a dependency and therefore needs an ADR under INV-6, so it is a later unit.
The heuristic stays and admits its range; it is not quietly widened until the fixture passes.

`plant-bad-format.sh` breaks the `indentation` rule and nothing else, so a finding means the rule
this repository chose was enforced rather than that the formatter disliked something.

`plant-ai-trailer.sh` is written and watched first, before any other plant exists. A trailer is
planted, the gate is run, and it is watched returning 1 before anything is made to pass. That plant
has to defeat the hook to do its job: `core.hooksPath` is repository configuration and a worktree
shares it, so the commit-msg hook fires inside the teeth worktree and rejects the very trailer the
plant exists to create. It is bypassed for exactly one invocation with
`git -c core.hooksPath=/dev/null commit` — not `--no-verify`, which is denied in settings, and not
by unsetting the configuration, which would silently disarm the hook for everything afterwards. This
is also the clearest demonstration of why the settings file is not the enforcement: a `deny` rule
stops an agent from typing a command, and nothing stops a plant script from doing the same thing
another way.

If a plant cannot be made to work for a gate, that gate is named under ROADMAP → Known holes. A
count that implies coverage which does not exist is never reported.

### The contract case

One failure this harness is exposed to is not a defect anyone can plant, because it is a behaviour
of a script rather than a property of a tree. `teeth.sh` carries it as a **second group of one**,
reported separately from the plants so that the plant group's eight still reads off the invariant
table and neither number implies the other's coverage.

Set `GATE_RANGE` to a range that resolves and contains nothing — `HEAD..HEAD` — run
`gate-hygiene.sh`, and assert that its first line names a different range than the one it was given
and a non-zero count. The trap this defends against is the obvious implementation, which resolves a
range, counts it, and never notices that a count of zero and a clean history are indistinguishable
from the exit code.

### `scripts/status.sh` — checked outside the harness

`teeth.sh` lands at Commit 6 and a worktree holds only committed content, so the harness cannot
reach a script that does not exist until Commit 12. The write-boundary check runs at Commit 12
instead, directly and once: from a clean tree, run `scripts/status.sh`, then `git diff --name-only`,
and confirm it lists `README.md` and nothing else. The output goes in Results and the displacement
goes in ROADMAP → Known holes, because a check living outside the harness is a check that will be
forgotten the first time somebody edits the script.

### Hook and settings

`.githooks/commit-msg` matches on family — `claude`, `anthropic`, `copilot`, `cursor`, `codex`,
`openai`, `gemini` — plus `Claude-Session:` and `Generated with .*Claude Code`, never a specific
model string.

`.claude/settings.json`: `attribution: {"commit": "", "pr": "", "sessionUrl": false}`;
`permissions.defaultMode: "plan"`; `ask` on `Package.swift`, `docs/adr/**`, `scripts/gates/**`,
`scripts/dev/**`, `.github/workflows/**`, `.githooks/**`, `Bash(git commit:*)`, `Bash(git push:*)`
and `Bash(git config core.hooksPath:*)` — that last one must be runnable once, deliberately, with a
prompt, because installing the hook is that command; `deny` on `Bash(git commit --no-verify:*)` and
`Bash(git commit -n:*)`.

Treat settings as convenience. The hook and CI are the enforcement, because a fresh clone has
neither until `scripts/dev/bootstrap.sh` runs.

### Corrections made at transcription

Four, each recorded under Falsified with the passage it corrects.

1. The paragraph beginning "Do not check INV-1 by building with
   `-Xswiftc -strict-concurrency=complete`" appeared twice, verbatim, and is collapsed to one.
2. `gate-format.sh` lints `Package.swift` as well as `Sources` and `Tests`. The manifest was read by
   no formatter at all, which is the one file a committed `.swift-format` most obviously ought to
   govern.
3. `gate-build.sh`'s debug pass adds `--build-tests`, bringing `Tests/` under INV-5.
4. `gate-hygiene.sh` writes its INV-8 check with `-E` and derives the family list from the hook.

Two clarifications rather than changes, because the seed says both things elsewhere and only left
them implicit at the point of use: `gate-hygiene.sh`'s range banner goes to stderr, and
`gate-build.sh` and `gate-format.sh` re-emit their tools' diagnostics through `finding`. Both follow
from stdout being findings-only, which the teeth case's line count depends on.

`.iOS(.v17)` is not widened. No gate in this unit compiles for iOS, because every gate runs against
the host and no simulator is needed. It stays a Known hole and closes with the Xcode project in
unit 02.

## Acceptance

Stated as gate outcomes, checked at the end and, where a check can run earlier, run earlier.

- `scripts/gates/all.sh` exits 0.
- `scripts/gates/teeth.sh` exits 0, reporting two groups separately: eight plant cases, each naming
  the invariant it exercises or `format` for the one that claims none, and one contract case naming
  itself. Each plant has been watched producing exit 1 with the expected findings.
- The transcription check emits no output — every script under `scripts/gates/` is named in
  § Constraints. Run at the moment the last gate script is written in Phase 3, and again at the end.
- `scripts/status.sh` was run at Commit 12 and `git diff --name-only` listed `README.md` and nothing
  else.
- `swift build` and `swift test` are clean and warning-free.
- Twelve commits, in order, none carrying an attribution trailer, proven by
  `git log --format='%B' | grep -i 'co-authored\|generated with\|claude-session'` returning empty.
- The README status block was generated, not typed.

## Plan of record

The Phase-1 plan as ratified. Reproduced verbatim; only heading levels are adjusted so the document
nests correctly.

### Toolchain observed (Phase 1, once)

Taken on the host this session runs on, at `/Users/<redacted>/dev/midkeep`, which is empty.

```
swift --version        swift-driver version: 1.148.6
                       Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101)
                       Target: arm64-apple-macosx26.0
swift format --version 6.3.0
xcodebuild -version    Xcode 26.6, Build version 17F113
git --version          2.50.1 (Apple Git-155)
uname                  Darwin 25.5.0, arm64
git config init.defaultBranch   main
```

Swift 6.3.3 satisfies "6.0 or later" and `swift format` answers, so all five gates can reach a
verdict on this host. This is the session's only toolchain check; Phase 2 copies these strings into
the prompt file under Results rather than re-running the commands.

Two further read-only observations taken here because they are load-bearing for Commit 2 and
Phase 3, and cost nothing now: `swift format lint --strict` exists as a subcommand, and the
`indentation` key is violable — a 2-space file linted against a 4-space configuration reports
`error: [Indentation] indent by 2 spaces` and exits 1, while the 4-space equivalent exits 0.

### 1. Commit sequence

Each commit lists the paths it introduces. Staging is by path on every commit.

| # | Message | Paths introduced |
|---|---|---|
| 1 | `chore: reject AI attribution trailers via commit-msg hook` | `.githooks/commit-msg`, `scripts/dev/bootstrap.sh` |
| 2 | `chore: add MIT license, ignore rules and formatter configuration` | `LICENSE`, `.gitignore`, `.swift-format` |
| 3 | `build: add Swift 6 manifest, three modules, placeholders and a test` | `Package.swift`, `Sources/MidkeepKit/Placeholder.swift`, `Sources/MidkeepUI/Placeholder.swift`, `Sources/MidkeepApp/Placeholder.swift`, `Tests/MidkeepKitTests/PlaceholderTests.swift` |
| 4 | `build: add gate exit-code contract and shared preamble` | `scripts/gates/lib/contract.sh` |
| 5 | `build: add build, test, format, arch and hygiene gates` | `scripts/gates/all.sh`, `scripts/gates/gate-build.sh`, `scripts/gates/gate-test.sh`, `scripts/gates/gate-format.sh`, `scripts/gates/gate-arch.sh`, `scripts/gates/gate-hygiene.sh` |
| 6 | `test: add teeth harness proving each gate fails on a planted defect` | `scripts/gates/teeth.sh`, and under `scripts/gates/teeth/`: `plant-ai-trailer.sh`, `plant-unchecked-sendable.sh`, `plant-force-unwrap.sh`, `plant-lang-mode.sh`, `plant-ui-in-kit.sh`, `plant-skipped-test.sh`, `plant-bad-format.sh`, `plant-warning.sh` |
| 7 | `ci: add build and gate workflows` | `.github/workflows/ci.yml`, `.github/workflows/gates.yml` |
| 8 | `docs: add ADR convention and decisions 0001-0006` | `docs/adr/README.md`, `docs/adr/0001-record-architecture-decisions.md`, `docs/adr/0002-the-run-is-the-unit-of-persistence.md`, `docs/adr/0003-three-modules-one-direction.md`, `docs/adr/0004-ios-17-deployment-target.md`, `docs/adr/0005-gate-exit-code-contract.md`, `docs/adr/0006-history-records-decisions-not-tools.md` |
| 9 | `docs: add CLAUDE.md invariants and Claude Code permission rules` | `CLAUDE.md`, `.claude/settings.json`, `.claude/rules/gates.md` |
| 10 | `docs: add roadmap findings log and driving-prompt convention` | `docs/ROADMAP.md`, `docs/prompts/README.md`, `docs/prompts/01-repository-and-harness.md` |
| 11 | `docs: add README with an empty generated status block` | `README.md` |
| 12 | `build: add status script that regenerates the readme status block` | `scripts/status.sh` |

Phase 2 lands 1 to 3, Phase 3 lands 4 to 6, Phase 4 writes without committing, Phase 5 lands 7 to
12. Commit 12 also stages `README.md`, modified in place by running `scripts/status.sh`; that is the
only path staged by two commits, and it is introduced by exactly one.

### 2. Reconciliation against the specified tree

Run both ways over the 43 paths in the file tree, against the introducing commit of each.

- Tree to commits: 43 of 43 paths are introduced by exactly one commit. Clean.
- Commits to tree: 43 of 43 introduced paths appear in the file tree. Clean.

Per-commit counts sum to the tree: 2+3+5+1+6+9+2+7+3+3+1+1 = 43.

### 3. Invariant to gate

| Invariant | Enforcement | Mark |
|---|---|---|
| INV-1 Swift 6 mode, strict concurrency complete | `gate-arch`, positive and negative reads of `Package.swift` | enforced |
| INV-2 no `@unchecked Sendable`, `nonisolated(unsafe)`, `@preconcurrency import` in `Sources/` | `gate-hygiene` | enforced |
| INV-3 module direction and import restrictions | `gate-arch` | enforced |
| INV-4 no force unwrap or `try!` in `Sources/` | `gate-hygiene` | PARTIAL, line-level grep cannot see literal boundaries |
| INV-5 warning-free debug and release build | `gate-build` | enforced |
| INV-6 no new dependency without an accepted ADR | none | UNENFORCED |
| INV-7 no skipped test on `main` | `gate-test` | enforced |
| INV-8 no AI-attribution trailer | `.githooks/commit-msg` + `gate-hygiene` + CI | enforced |
| INV-9 every gate obeys the exit contract | `scripts/gates/teeth.sh` | enforced |
| INV-10 every step journalled before its effect is observable | none, no runtime exists | UNENFORCED |
| INV-11 every claim names the file, script or run behind it | hand review | UNENFORCED |

### 4. Gate to plant, with the count derived

Seven invariants are claimed by a gate: INV-1 and INV-3 by `gate-arch`; INV-2, INV-4 and INV-8 by
`gate-hygiene`; INV-5 by `gate-build`; INV-7 by `gate-test`. INV-6, INV-10 and INV-11 are claimed by
no gate and get no plant. INV-9 is the property `teeth.sh` asserts about every other gate, so it is
the harness rather than a subject of it. `gate-format` claims no numbered invariant and is
teeth-tested anyway. Seven plus one is eight plants, in one group; the contract case is a second
group of one, reported separately so neither count implies the other's coverage.

| Plant | Gate | Exercises |
|---|---|---|
| `plant-lang-mode.sh` | `gate-arch` | INV-1, negative direction only |
| `plant-ui-in-kit.sh` | `gate-arch` | INV-3 |
| `plant-unchecked-sendable.sh` | `gate-hygiene` | INV-2 |
| `plant-force-unwrap.sh` | `gate-hygiene` | INV-4, asserting exactly one finding beside three near-misses |
| `plant-ai-trailer.sh` | `gate-hygiene` | INV-8, written and watched first |
| `plant-warning.sh` | `gate-build` | INV-5 |
| `plant-skipped-test.sh` | `gate-test` | INV-7 |
| `plant-bad-format.sh` | `gate-format` | the `indentation` rule named in `.swift-format`, no numbered invariant |
| contract case, `GATE_RANGE=HEAD..HEAD` | `gate-hygiene` | that a range which resolves and contains nothing is discarded |

Five entries land in ROADMAP under Known holes as a consequence: INV-1's positive direction has a
gate and no plant, and INV-6, INV-10 and INV-11 have no gate; `gate-hygiene`'s force-unwrap check is
a heuristic. Four more that are not invariants land there too: the `status.sh` write boundary
checked at Commit 12 rather than inside the harness, `gate-hygiene`'s `core.hooksPath` check
verified only in its own teeth case, the hook's one-command bypass, and the transcription check
proving mention rather than conformance.

### 5. Assumptions, and how each was decided

Each of these changed the plan on a one-word answer. The decision follows the assumption.

1. **Plan-mode re-entry cadence.** Read literally, re-entering plan mode before anything touching
   `Package.swift`, `scripts/gates/**`, `docs/adr/**` and `.github/**` stops the session for
   ratification four more times: before Commit 3, before Phase 3, before Phase 4's ADRs, and before
   Commit 7. **Decided: all four stops, not batched.** At the moment a batched stop would happen,
   Appendix B has not been read, so the stop that matters — the one before `scripts/gates/**` —
   would ratify a phase nobody has thought about yet, and a ratification that cannot be diffed
   against anything is the formality this protocol exists to avoid.

2. **Phase 5 fan-out scale.** Eleven invariants plus seven house rules is eighteen dimensions.
   **Decided: six reviewers, three dimensions each, then one refutation pass — seven invocations.**
   Independence between batches is what the fan-out is for; a reviewer holding three dimensions at
   once loses less than a serial read, which would give up the only place this session fans out at
   all. The output stays one line per dimension, eighteen lines, a mark plus `clean` or `file:line`.

3. **Whether `gates.yml` runs `teeth.sh`.** **Decided: it does.** `ci.yml` runs `bootstrap.sh`, then
   `swift build` debug and release, then `swift test`. `gates.yml` runs `bootstrap.sh`, then
   `all.sh`, then `teeth.sh`, with `fetch-depth: 0` and a check of the pull-request body for
   trailers. A harness that has only ever run on one Mac is the failure this unit argues against.
   Known holes gains a note, beside the entry already planned for `core.hooksPath`, that `CI` being
   set skips that check — so the gate under test takes a different path in CI than locally. Teeth in
   CI builds a worktree per plant; if the runtime proves prohibitive that is a measurement for
   whichever unit first pushes, not a reason to leave it out now.

4. **What `status.sh` prints for teeth cases.** **Decided: count
   `scripts/gates/teeth/plant-*.sh` and name the line as plant cases.** This corrects the driving
   prompt, which asks for a "teeth-case count": nine cases exist and only eight are files, so the
   literal wording asks for a hand-typed constant inside a generated block — the failure the
   landed-units line went through three positions to avoid. The contract case is reported by
   `teeth.sh` itself. The correction has no Falsified home, because Falsified takes corrections made
   during the Appendix B transcription and `status.sh` is not in Appendix B; it is recorded here and
   opens ROADMAP → Findings, sourced to this unit.

5. **When the macOS-platform experiment runs.** ADR-0004 has to quote the compiler's own message
   from a build with `.macOS(.v14)` removed. **Decided: immediately after Commit 3 lands, not
   before.** Before the commit the manifest is untracked and putting it back depends on editing
   carefully; after it, the restore is `git checkout -- Package.swift` and a clean `git status`
   proves it. The observation is captured into Results at the moment of the run, as every other
   observation is.

### 6. Corrections carried into execution

Three amendments ratified with the plan.

1. `Sources/MidkeepUI/Placeholder.swift` carries `import SwiftUI` and no members. Without it the
   experiment in assumption 5 probably produces no error at all: the placeholders would import
   nothing, removing `.macOS(.v14)` would build clean, and ADR-0004 would have no compiler message
   to quote. With it, the default macOS deployment target and SwiftUI's minimum collide. The import
   is permitted to `MidkeepUI` under INV-3, so `gate-arch` stays green. If the build succeeds
   anyway, ADR-0004 records the successful build verbatim and says the platform is declared for what
   Kit and UI will import. Under either outcome the ADR does not assert what happens without the
   platform — it reports what was observed.

2. The teeth worktree is created detached: `git worktree add --detach "$dir" HEAD`, never a branch
   name. `plant-ai-trailer.sh` commits inside the worktree, and on a branch that either fails
   outright as already checked out or moves `main`. Detached leaves a dangling commit that
   `remove --force` and `prune` discard.

3. Appendix B contains the paragraph beginning "Do not check INV-1 by building with
   `-Xswiftc -strict-concurrency=complete`" twice, verbatim. The transcription collapses it to one
   and logs the collapse under Falsified, citing both occurrences. This is the amendment channel
   doing what it was written for, and the first evidence that it works.

### Mode

Never `auto`. Manual approval of edits for the whole session: stricter than `acceptEdits` in
Phase 2, and matching `default` in Phases 3 and 5.

## Predictions

Written at the start of Phase 2, before `git init`, and never edited afterwards. Each names an
outcome this plan is most likely to be wrong about in execution rather than on the page, and each is
decidable inside this session from commands anyone can re-run. None waits on a CI run; this session
never pushes and never triggers one.

1. Whether `.githooks/commit-msg` rejects Commit 1's own message. This is the first point at which
   the protocol depends on itself. Judged by attempting Commit 1 with
   `Co-Authored-By: Claude <noreply@anthropic.com>` appended, then removing the trailer and
   committing for real. A bare exit code cannot diagnose this, because three different faults all
   present as a successful commit: the hooks path unset, the hook file not executable, or the hook
   running and its regex failing to match. All four observations are recorded at the moment of the
   attempt:

   ```
   git config --get core.hooksPath        # empty -> bootstrap ordered too late
   test -x .githooks/commit-msg; echo $?  # non-zero -> chmod missing
   git commit …                           # exit code
                                          # stderr, verbatim
   ```

   Together they separate the three. Results says which one it was rather than moving on.

2. Whether `swift build` succeeds on the manifest at Commit 3, and against which toolchain version.

3. Which range `gate-hygiene` names on its first line when `origin/main` and `HEAD` are the same
   commit, which is the state a push to the default branch produces. That state is made locally and
   the gate's own first line is read; no workflow run is waited on. What the gate does under a real
   `actions/checkout` is a finding for whichever unit first pushes.

4. Whether `teeth.sh` removes its worktree when the gate under test exits 2.

5. Whether `bootstrap.sh` sets `core.hooksPath` before any commit is possible.

6. What `scripts/status.sh` prints in a repository with no tag.

## Results

Each observation is entered when it happens, not collected at the end. After Phase 5 the section
gets one final pass marking each prediction confirmed or falsified, with the command and the output
that decided it.

### Toolchain

Observed once in Phase 1, on the host this session ran on. Copied here rather than re-run.

```
swift --version        swift-driver version: 1.148.6
                       Apple Swift version 6.3.3 (swiftlang-6.3.3.1.3 clang-2100.1.1.101)
                       Target: arm64-apple-macosx26.0
swift format --version 6.3.0
xcodebuild -version    Xcode 26.6, Build version 17F113
git --version          2.50.1 (Apple Git-155)
uname                  Darwin 25.5.0, arm64
git config init.defaultBranch   main
```

### Gate coverage of the early commits

No gate exists before Commit 5, so Commits 1 to 4 are checked by running the underlying command
directly — `bash -n` on every script, and `swift build` and `swift test` from Commit 3 onward. Each
commit body names the command it ran; the records follow as each lands.

Commit 1. Read in a form that derives the status rather than asserting it, so that each script is
checked whichever way the previous one went and the number printed is the one the command returned.

```
$ for s in .githooks/commit-msg scripts/dev/bootstrap.sh; do
    bash -n "$s"; printf '%s: bash -n exit=%s\n' "$s" "$?"
  done
.githooks/commit-msg: bash -n exit=0
scripts/dev/bootstrap.sh: bash -n exit=0
```

### Prediction 5 — `bootstrap.sh` sets `core.hooksPath` before any commit is possible

Confirmed. Read with zero commits in the repository, which is the only window in which the
conjunction is observable at all.

```
$ bash scripts/dev/bootstrap.sh
bootstrap: core.hooksPath set to .githooks
bootstrap: done
exit=0
$ git config --get core.hooksPath
.githooks
$ git rev-list --count --all
0
```

`bootstrap.sh` also claims to do this idempotently, and nothing else in this unit checks that claim —
no gate, and it is not a Known hole either. Read rather than assumed:

```
$ bash scripts/dev/bootstrap.sh
bootstrap: core.hooksPath already .githooks
bootstrap: done
second run exit=0
$ git config --get core.hooksPath
.githooks
--get exit=0
$ git config --get-all core.hooksPath | wc -l
1
```

One value, and `--get` exits 0 on the second read. An implementation using `git config --add` would
leave two values and make `--get` exit non-zero, so the claim holds.

### Prediction 1 — the commit-msg hook rejects Commit 1's own message

Confirmed, and the four readings were taken at the moment of the attempt, against the hook as it is
committed rather than an earlier draft of it.

```
$ git config --get core.hooksPath
'.githooks'
$ test -x .githooks/commit-msg; echo $?
0
$ git commit -F <message carrying Co-Authored-By: Claude <noreply@anthropic.com>>
exit=1
--- stderr, verbatim ---
commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
commit-msg: history records who can be asked why a change was made.
commit-msg: remove the trailer and commit again.
$ git rev-list --count --all
0
```

Which of the three faults it was: none of them. A non-empty `core.hooksPath` rules out the hooks
path being unset, so the ordering of `bootstrap.sh` before the first commit holds. `test -x`
returning 0 rules out a missing `chmod`. The exit code of 1 together with stderr carrying the hook's
own diagnostic rules out the third — the hook ran and its regex matched, rather than running and
failing to match. The three faults are distinguishable because all three would otherwise have
presented as a successful commit.

The hook is also read for the case where it cannot inspect anything, because a hook has only 0 and
non-zero and the no-verdict case has to land on reject:

```
$ bash .githooks/commit-msg
exit=1
commit-msg: cannot read the message file; refusing
```

### Every reject branch of the hook, watched matching

Prediction 1 exercises one of the hook's three reject branches, and `plant-ai-trailer.sh` plants the
same `Co-Authored-By` line, so on the commits alone `Claude-Session:` and `Generated with .*Claude
Code` would never be watched matching, and five of the seven family tokens would never appear in any
message. A regex nobody has watched match is not a check, and that applies to the branches of a
check as much as to the check as a whole. Closing it needs no commit — the hook is invoked directly
against scratch files.

```
$ for t in <each trailer below>; do
    printf 'chore: scratch\n\n%s\n' "$t" > probe.txt
    bash .githooks/commit-msg probe.txt; printf 'exit=%s\n' "$?"
  done

exit=1  Co-Authored-By: Claude <noreply@anthropic.com>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: Anthropic Bot <bot@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: Copilot <copilot@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: Cursor <agent@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: Codex <codex@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: OpenAI Assistant <a@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Co-Authored-By: Gemini <g@example.invalid>
        commit-msg: INV-8 violation: Co-Authored-By naming an AI assistant
exit=1  Claude-Session: https://example.invalid/x
        commit-msg: INV-8 violation: Claude-Session trailer
exit=1  Generated with Claude Code
        commit-msg: INV-8 violation: Generated with Claude Code attribution
exit=1  Generated with [Claude Code](https://claude.com/claude-code)
        commit-msg: INV-8 violation: Generated with Claude Code attribution
```

All three branches fire and all seven family tokens match. A clean control confirms these are
findings rather than a hook that rejects whatever it is given:

```
$ printf 'chore: scratch\n\nA body with no trailer.\n' > probe.txt
$ bash .githooks/commit-msg probe.txt
clean exit=0
```

That control is not sufficient on its own. It carries no co-author trailer at all, so a regex whose
`.*(claude|anthropic|…)` half was broken would produce exactly the same eleven readings. The
near-misses are what prove the exclusion, the same way `plant-force-unwrap.sh` plants `!=` and a
prefix `!` beside the real one:

```
exit=0  Co-Authored-By: Jane Doe <jane@example.com>
exit=0  Signed-off-by: Claude Kim <ck@example.com>
exit=0  Reviewed-by: Sam <sam@opencodex.example>
```

The first proves the alternation discriminates rather than the trailer name alone. The second and
third prove the check is scoped to the three trailers it claims and does not fire on a family token
appearing anywhere in a message — `codex` inside a domain and `Claude` as a human given name both
pass.

Fourteen readings in total: seven family tokens, three other-branch forms, one clean control, three
near-misses. No branch and no token failed to fire, so no Known hole follows from coverage.

One false positive does follow, and is logged rather than fixed. A human contributor actually named
Claude, or an address at a domain containing one of the seven tokens, is rejected by the
`Co-Authored-By` branch — `Co-Authored-By: Claude Kim <ck@anthropic.example>` would not commit. That
is the loud direction and it is the right trade for a line-level match, but a contributor should not
discover it by being unable to commit. **ROADMAP → Known holes owes an entry for this.**

### Commit 1 landed, and what is in it

The message was amended once on HEAD, for wording only: a clause describing how the `bash -n` status
had been read was replaced by the two commands themselves. Amend on HEAD is the one place it is
allowed and the window closed when Commit 2 landed. The amend was a third clean pass through the
hook. Prediction 1's four observations were taken against the pre-amend attempt and are unaffected by
it — the rejection and the amend are separate events, in that order.

What landed was then compared against the file that was reviewed, because from here the committed
hook governs every commit in this repository:

```
$ git status --short -- .githooks/commit-msg scripts/dev/bootstrap.sh
(empty)
$ git show HEAD:.githooks/commit-msg | grep -cE 'refusing|cat "\$msg_file"'
2
$ git show HEAD:.githooks/commit-msg | grep -cE "grep -v '\^#'"
0
```

Empty status means the corrected version is the one committed rather than sitting unstaged. The
count of 2 is the fail-closed guard and the raw read; the count of 0 is the absence of the comment
strip those two replaced.

### Which `grep` runs, and which alternation form is safe

The definition-of-done proof for INV-8 uses BRE alternation, `\|`, which is a GNU extension rather
than POSIX. The proof's own correctness therefore depends on which `grep` runs. Read as a literal
string the pattern would match nothing, every trailer would pass, and the proof would report green
having inspected nothing — the failure this repository exists to make impossible, appearing in the
command meant to prove it did not happen. Measured rather than assumed.

```
$ /usr/bin/grep --version | head -1
grep (BSD grep, GNU compatible) 2.6.0-FreeBSD

                                   BRE -ci    ERE -ciE
Co-Authored-By: Claude <x>            1          1
Generated with Claude Code            1          1
Claude-Session: x                     1          1
A body with no trailer                0          0
```

The negative control is the load-bearing row. Six counts of 1 cannot distinguish "the pattern
matched" from "the pattern matches every line", and a BRE read as an empty alternation does exactly
the second. Both forms return 0 on a clean line, so the pattern discriminates.

What a script resolves `grep` to, since that is what a gate will run:

```
script grep = /usr/bin/grep
grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
BRE counts: 1 1 1     ERE counts: 1 1 1
```

Separately, and not the question being asked: inside the agent's interactive shell `grep` is not
`/usr/bin/grep` at all but a shell function shimming to `ugrep 7.5.0`. Non-interactive scripts do not
inherit it — `type -t grep` returns `file`, `command -v grep` returns `/usr/bin/grep` — so no gate is
affected. Every ad-hoc verification run from the agent's shell is, and must name the binary or it
measures a different program than the repository specifies.

Three dispositions follow, and none of them depends on the counts above. A green BRE reading is a
fact about this machine's `PATH` and this grep build; it says nothing about the macOS runner
`gates.yml` uses, which inherits none of this, and nothing about a contributor's machine.

- `gate-hygiene` writes its INV-8 check with `-E`. ERE alternation is POSIX and identical on GNU and
  BSD grep. A gate whose pass criterion depends on which `grep` sits first in `PATH` is not
  reproducible, which is the argument this repository already makes for committing `.swift-format`
  rather than trusting the toolchain default. The correction enters through the Appendix B
  transcription in Phase 3 and is logged under Falsified, citing these readings.
- The driving prompt's definition-of-done proof specifies the BRE form. That passage sits outside
  Appendix B and has no Falsified home, so it opens **ROADMAP → Findings**, sourced to this unit,
  naming the ERE replacement. The Commit 12 proof uses `-E`, as does every trailer grep in this
  session.
- No gate script pins `/usr/bin/grep`. Pinning is right for a one-off proof that BSD grep agrees;
  inside a gate it hardcodes an absolute path, which is a reproducibility problem of its own. Gates
  use plain `grep -E`.

The finding does not touch `.githooks/commit-msg`. All three of its branches already use
`grep -Eqi`, so the hook was never exposed to this. It is not edited for it.

A third correction to the same command, found while writing the audit: the driving prompt's pattern
uses a bare `generated with` and a bare `co-authored`, both broader than the hook. `Co-Authored-By:
Jane Doe` is a legitimate human co-author and would trip it, and so would a sentence such as "the
sample was generated with plant-bad-format.sh". The audit used from here mirrors the hook's three
patterns exactly, and carries a positive control so that a broken pattern is distinguishable from
clean history — without one, both read as 0.

```
$ git log --format='%B' | grep -ciE '^[[:space:]]*co-authored-by:.*(claude|anthropic|copilot|cursor|codex|openai|gemini)|^[[:space:]]*claude-session:|generated with .*claude code'
0
$ printf 'Co-Authored-By: Claude <x>\n' | grep -ciE '<same pattern>'
1
```

This joins the ERE change in the same ROADMAP → Findings entry, since both correct the same command.

### Commit 2 — `.swift-format` is the criterion, measured four ways

The claim in Commit 2's body is that `gate-format` is reproducible because the configuration is
committed. Exit codes alone cannot establish that: `swift format lint --strict` exits non-zero both
when a rule fires and when the tool fails, so a corrupt `.swift-format` would produce the same shape
of output and read as a pass. The check therefore asserts on diagnostic text with stdout and stderr
captured separately, and carries two controls.

```
$ swift format --version
6.3.0

                          exit   diagnostic
two.swift  with config      1    error: [Indentation] indent by 2 spaces
four.swift with config      0    (none)
two.swift  no config        0    (none)
four.swift no config        1    error: [Indentation] unindent by 2 spaces
two.swift  bad config      64    error: Unable to read configuration: The data couldn't be
                                 read because it isn't in the correct format.
```

The no-config rows are the control that makes `--configuration` load-bearing: the toolchain default
is two spaces, the committed file sets four, and the verdicts invert. Run without the flag from a
directory with no `.swift-format` above it, so the tool cannot find the repository's copy by
directory search. Had the two pairs agreed, the file would be setting a value equal to the default
and the gate would prove nothing about it.

The bad-config row is the control separating a rule firing from the tool failing. It exits non-zero
and never names indentation, so the two are distinguishable by text where they are not by status.

### How a commit message is checked before it lands

Counting blank lines is neither necessary nor sufficient — a separator of three spaces counts as
zero and still splits correctly, and three blank lines in the wrong places count as three and
produce a mangled commit. From Commit 2 onward the message is committed to a throwaway repository
first and the recorded fields are read back:

```
r=$(mktemp -d) || exit 1
[ -n "$r" ] || exit 1
git -C "$r" init -q
git -c user.email=a@b.c -c user.name=t -C "$r" commit -q --allow-empty -F <message>
git -C "$r" log -1 --format='%s'   # compared against the literal expected subject
git -C "$r" log -1 --format='%b'   # must be non-empty
```

The `mktemp` guards are load-bearing rather than defensive. `git -C ""` is a documented no-op, so an
empty variable would run `git init` and `git commit --allow-empty` against the live repository
instead of the throwaway one.

## Commit message convention

Adopted at Commit 2 and binding from Commit 3 onward.

- The subject is a single line under 72 columns, in Conventional Commits form, imperative mood.
- The body wraps at 72 columns. A command or path that would not survive wrapping gets its own line.
- No trailer of any kind.

Seventy-two rather than eighty, because `git log` indents the body by four and 72 + 4 lands inside
80. Eighty was the other candidate and was rejected for a reason worth recording: the draft under
discussion was 78 columns at its longest, so adopting 80 would have been choosing the rule to fit
the artifact already written. That is the same move as softening INV-4's wording until a line-level
grep can satisfy it, which this unit refuses on principle. The rule is chosen first and the text is
rewrapped to meet it.

Commit 2 was amended on HEAD to comply; it was written before the rule existed and its first form
had a 161-column line. Commit 1 predates the rule and is left as it stands, because it has a child
and rewriting a closed commit is forbidden. The exception is recorded here rather than tolerated
silently.

This is INV-12, and it is UNENFORCED. **It binds from Commit 2 onward.** Commit 1 is the root
commit, predates the rule, and is exempt for the reason set out under Prompt deltas; a check that
sweeps the whole history expects two violations rather than none, and one that expects none will
fail every run and stop being read. Nothing in the tree checks the shape of a commit message
beyond INV-8's trailer rule. Promoting it to a gated invariant was the alternative and was rejected:
it would widen Commits 5 and 6, which were specified and ratified before this rule existed, and it
would add a ninth plant to a count the plan derives from the invariant table. Marking it UNENFORCED
uses vocabulary the table already carries for INV-6, INV-10 and INV-11, and says the true thing —
the convention exists and no gate checks it — rather than implying a gate that is not there.

CLAUDE.md § Working agreements carries the rule from Phase 4, with the UNENFORCED mark beside it.
This unit's own verification script checks the 72-column rule on each message before it is
committed, which is a convenience for the rest of this session and not enforcement, in the same
sense that `.claude/settings.json` is a convenience for INV-6 and a fresh clone does not have it.

## The INV-8 history audit has one source of truth

The audit pattern was hand-retyped in three consecutive rounds and broke three different ways: the
alternation was BRE where the host might have read it literally, then a bare `generated with`
false-positived on this repository's own generator language, then the family list was truncated. The
defect was the retyping, not any of the three instances.

The pattern is now derived from the committed hook rather than written out:

```
family="$(git show HEAD:.githooks/commit-msg | sed -n "s/^family='\(.*\)'$/\1/p")"
AUDIT="^[[:space:]]*co-authored-by:.*(${family})|^[[:space:]]*claude-session:|generated with .*claude code"
```

Coverage is proved by probing every token the hook declares, rather than every token someone
remembered to list — the loop reads its inputs from `$family`, so a family added to the hook is
probed automatically and a family dropped from the hook stops being claimed.

```
extracted family = [claude|anthropic|copilot|cursor|codex|openai|gemini]
audit.family_count        expect=7 actual=7 PASS
audit.all_families_fire   expect=0 actual=0 PASS   (0 tokens failed to fire)
audit.session_branch      expect=1 actual=1 PASS
audit.genwith_branch      expect=1 actual=1 PASS
audit.negative            expect=0 actual=0 PASS
audit.human_coauthor      expect=0 actual=0 PASS   Co-Authored-By: Jane Doe
audit.generated_with_sh   expect=0 actual=0 PASS   "generated with plant-bad-format.sh"
```

From Commit 5 the audit moves into `gate-hygiene` and everything calls that instead.

## The agent's shell is zsh; the gates run bash

A second instance of the class the `grep` finding belongs to. Ad-hoc verification blocks run under
`/bin/zsh`, so `read -ra`, `<<<` word-splitting into an array, and other bash-only forms fail there
with `bad option: -a`. Gate scripts carry `#!/usr/bin/env bash` and are unaffected.

The consequence is the same as for `grep`: a construct verified in an ad-hoc block has not been
verified for a gate, and a construct that fails in an ad-hoc block has not necessarily failed for a
gate. Verification blocks use portable forms — `tr '|' ' '` and a `for` loop rather than an array
read. Nothing about this reaches the repository, and no gate is changed for it.

## A check earns trust by being watched go both ways

Two shapes of defect appeared in this session's own verification blocks, and they look like
opposites until the cause is named.

The first kind cannot fail. `bash -n "$s" && echo "ok exit=$?"` prints `0` or prints nothing; a
failure short-circuits the line out of existence, so the output states a status it never measured.
The INV-8 audit had the same shape three times over: a pattern that matched nothing returned 0 and
was indistinguishable from clean history.

The second kind cannot pass. A check written as
`print(json.load(f)).get("defaultMode","MISSING")` calls `.get` on `print`'s return value, so it
raises — but only after printing the whole object to stdout. With stderr discarded, the captured
value is the object followed by the fallback's `MISSING`, and the comparison fails against a correct
file. Reproduced against a known-good file: it still failed.

The cause is identical. Each check was written and then never watched failing, and never watched
passing. A check observed in only one direction proves nothing in either, because the observation is
consistent with the check being broken.

This is the argument for the teeth harness stated in miniature, and it is why `teeth.sh` asserts a
clean tree exits 0 *before* it plants anything: the plant proves the gate can fire and the clean run
proves it can stay quiet, and neither alone is evidence. **ROADMAP → Findings owes an entry**,
sourced to this unit.

A second entry from the same episode: each hand-rewritten iteration of a verification block gained a
check and quietly lost one. `deny.count`, `json.valid`, `bash.rules` and the six per-family pair
checks were all present one round before they went missing. A block retyped each round decays the
same way the file it was checking did, and for the same reason.

A third entry, from correcting a claim that had propagated into a commit body and a doc comment:
**a check for the absence of a wrong thing is half a check.** `msg.no_nominal` and `file.no_nominal`
assert the disproved sentence is gone, and both pass equally if the sentence was deleted outright
and nothing replaced it. That is not hypothetical — an edit earlier in this session removed the
antecedent of the sentence that followed it. Every removal check needs its arrival partner:
`msg.has_inv3`, `file.has_inv3`, and `file.import_kept`, which catches the case where the sentence
was fixed by deleting the import it describes. This is the "watched both ways" argument again,
applied to edits rather than to gates.

## What the two approval gates caught in Phase 2

The plan asked for this measurement at the Phase 3 boundary, to decide whether `acceptEdits` was
worth a delta. A first version of this entry answered "nothing", having scoped edit approval to
Commit 3's six source files — all of which matched a ratified spec and went in unchanged. That
scoping was wrong, and the wrong answer pointed the wrong way: it reads as an argument *for*
`acceptEdits`.

Counted across the whole phase, the two gates caught different classes and neither could have seen
the other's.

**Bash approval — defects in what was about to execute.** A truncated heredoc. The INV-8 audit
pattern truncated to `copiloni`, losing five of seven families. A missing index guard before a
commit. `tail`'s exit status read as the build's, in the probe meant to decide whether a SwiftUI use
fails. `2>&1 >file` with the redirections reversed, capturing no diagnostics. `bash -n && echo`,
which prints a status it never measured. `sort -u` conflating the manifest's compile triple with the
module's.

**Edit approval — defects in what was about to be claimed.** `defaultMode` written at the top level
of `.claude/settings.json`, where Claude Code does not read it, making the key inert. "All eight ADR
files" where there are seven, which broke this document's own 43-path reconciliation into 44. An
edit that deleted the antecedent its next two sentences referred to. A present-tense claim about
what `teeth.sh` asserts, written two commits before `teeth.sh` exists. `.gitignore` omitted from the
group of paths acted on by something other than a human. A doc comment saying `gate-arch` checks
INV-3, before `gate-arch` exists.

Six and six. The first two edit-approval items are precisely what `acceptEdits` would have silenced:
a permission rule or a misplaced key inside a whole-file write is invisible unless someone reads the
proposed content.

**Review also raised claims that did not survive measurement, and they sort into three kinds.**

Three were false positives, disproved by measuring: that a commit message had no blank lines (it had
three, at lines 2, 5 and 12); that an amend had not happened (HEAD was already the amended commit);
and that a probe directory had leaked (all seven candidates predated the session, one by four days,
and none contained a `.git`).

One was not a false positive at all and must not be filed as one. The `git -C ""` hazard — an empty
variable making `git init` and `git commit --allow-empty` land in the live repository instead of a
throwaway — was reproduced in a scratch repository and then closed by adding the `mktemp` guards.
A hazard demonstrated and prevented is the reason those guards exist; recording it as disproved
would leave them looking unmotivated.

Two are unresolved: that a rule had been dropped from the ask list, and that `defaultMode` appeared
twice after an edit. Both were judged from an approval dialog by both parties, and neither was
checked against a resulting file at the time. They are recorded as open rather than resolved in
either direction.

**The cause is narrower than "measure before acting".** Every claim that failed came from reading a
*rendered approval dialog* rather than the artifact — stripped blank lines, a diff's removed line
read as a duplication, left-edge clipping. None of the six Bash-approval findings failed, because
those read the command text itself. So the rule adopted for Phase 3 is one notch tighter: **review
from the file, not from the dialog.** When a proposed edit is worth challenging, print the resulting
file and run the challenge against that. It costs one command and removes the whole class.

The conclusion survives the correction and now rests on the right reason. `acceptEdits` is not
adopted for Phase 3, because all sixteen files there sit under `scripts/gates/**`, which this
repository ask-gates itself, so it would save zero prompts in the phase with the most files. But the
reason is no longer "edit approval catches nothing" — it catches a class Bash approval structurally
cannot see, because prose defects never execute.

### Prediction 3 — which range `gate-hygiene` names when `origin/main` equals `HEAD`

Confirmed. The state was made locally with `git update-ref refs/remotes/origin/main HEAD`, which is
what a push to the default branch produces, and the gate's own first line was read. No workflow run
was waited on; this session never triggers one.

```
$ git update-ref refs/remotes/origin/main HEAD
$ bash scripts/gates/gate-hygiene.sh
gate-hygiene: INV-8 over HEAD, 4 commits (origin/main..HEAD resolved empty, fell back to all of HEAD)
exit=0
$ git update-ref -d refs/remotes/origin/main
```

The range named is `HEAD`, not `origin/main..HEAD`, and the count is non-zero. `origin/main..HEAD`
resolved successfully and contained nothing, the zero-count fallback discarded it, and the gate went
on to inspect four commits. Without the fallback the gate would have examined none, found nothing,
exited 0, and reported a green INV-8 that read no message at all.

What the gate does under a real `actions/checkout` remains a finding for whichever unit first
pushes.

## Phase 4 — `status.sh`, and what running it found

### `awk -v` cannot carry a multi-line value

The first `scripts/status.sh` passed the generated block to `awk` with
`-v block="$block"`. An awk variable assignment cannot contain embedded newlines, so every run
failed with `awk: newline in string | | | …` and the block was never inserted:

```
$ bash scripts/status.sh
awk: newline in string | | |
|---|---|
| ve... at source line 1
status: could not rewrite README.md
exit=2
```

The block is now written to a temporary file and read with `getline`. Worth recording because the
failure mode was loud only by luck: the script returns 2 and refuses to write, which is the contract
working. Had it been written to swallow the awk failure it would have produced an empty block and
reported success.

### Prediction 6 — what `status.sh` prints in a repository with no tag

Confirmed. `git describe --tags` exits non-zero with no tags, and the fallback supplies the text
rather than leaving the field blank:

```
| version | no tag yet |
| commits | 6 |
| last commit | 2026-08-01 |
| gates | 5 |
| teeth plant cases | 8 |
| landed units | 1 |
```

Every number is derived: gates from `scripts/gates/gate-*.sh`, plant cases from
`scripts/gates/teeth/plant-*.sh`, units from `docs/prompts/[0-9]*.md`, and the rest from git. The
line reads `teeth plant cases` rather than `teeth cases` because nine cases exist and only eight are
files; reporting nine would mean adding one by hand inside a generated block.

### The write boundary, checked at the filesystem rather than through git

The ratified criterion is `git diff --name-only` listing `README.md` and nothing else. That is
weaker than it looks, because git cannot see untracked files and at Phase 4 the whole of this
phase's output is untracked. Checked instead by hashing every file in the tree — excluding `.git`
and `.build`, with `-print0`/`xargs -0` so a path containing a space could not be mis-split — before
and after the run, and diffing the two.

```
first run   changed: ./README.md          exit 0
second run  changed: (nothing)            exit 0, byte-identical output
```

The second run is the load-bearing one. `status.sh` is idempotent, so a boundary check that expects
`README.md` to change would fail at exactly the moment Commit 12 satisfies the Acceptance clause.
An empty change set is a pass.

A missing marker is a no-verdict rather than a silent success:

```
$ bash scripts/status.sh     # begin marker removed
status: README.md has no begin marker
exit=2
```

### Which run generates the block

§ 1 says Commit 11 lands "README with an empty generated status block" and Commit 12 fills it.
Phase 4 therefore verified `status.sh` against the real README and then **restored the empty block**,
leaving two markers with nothing between them. Generating it here would have made Commit 11 land a
full block, which is a different commit from the one ratified.

Commit 12 runs `status.sh` for the first time on tracked content, and that run is where the
`git diff --name-only` form of the check applies.

The restore is what makes the Acceptance clause satisfiable, not merely what makes Commit 11
faithful. Acceptance reads: `scripts/status.sh` was run at Commit 12 and `git diff --name-only`
listed `README.md` and nothing else. With the block empty going in, the run fills it and README is
listed — the clause holds. Had Phase 4 left the block filled, `status.sh` is idempotent, so the
Commit 12 run would change nothing and `git diff --name-only` would list *nothing*. That satisfies
the boundary half of the sentence and fails the other half, and it would fail in the direction that
looks like success.

So the block was emptied deliberately, and the reason is recorded here rather than left to look like
tidying.

### Installed simulator runtimes — a measurement, not a check

Owed as a finding for unit 02.

```
$ xcrun simctl list runtimes
iOS 18.0 (18.0 - 22A3351)
iOS 18.3 (18.3.1 - 22D8075)
iOS 18.4 (18.4 - 22E238)
iOS 26.0 (26.0 - 23A343)
iOS 26.1 (26.1 - 23B86)
iOS 26.5 (26.5 - 23F77)
```

No iOS 17 runtime is installed. So `.iOS(.v17)` could not be compiled on this host even if a gate
wanted to, which is the concrete cost of the Known hole recording that no gate compiles for iOS. It
belongs to whichever unit adds the Xcode project.

### The house-rule-5 regression scan needs two scopes

`git grep` sees tracked files only, and Phase 4's entire output is untracked until Commits 8 to 10 —
so the tracked scan is blind to exactly the documents being written. Both scopes are run and kept
separate: `git grep -ilE` for the forbidden token over tracked files, and a plain recursive grep
over `docs/`,
`.claude/` and the root markdown. Both return zero files. An earlier version scanned with
`--exclude-dir=.git`, which does not exclude `.build/` — hundreds of megabytes of compiled package,
where any hit would be noise rather than a regression.

## Commit 6 — the harness caught a defect its own gate verification could not

`teeth.sh` exited 1 on its first run, with two failures, and one of them was in a gate that had
already passed its own verification and landed in Commit 5. This is the one result here that could
not have been reached by reasoning about the code.

```
  ok    plant-lang-mode [INV-1]: gate-arch.sh quiet when clean, 1 finding(s) when planted
  ok    plant-unchecked-sendable [INV-2]: gate-hygiene.sh quiet when clean, 1 finding(s) when planted
  ok    plant-ui-in-kit [INV-3]: gate-arch.sh quiet when clean, 1 finding(s) when planted
  FAIL  plant-force-unwrap [INV-4]: plant-force-unwrap.sh refused or failed to plant
  FAIL  plant-warning [INV-5]: 0 finding(s) matching Sources/MidkeepKit/Placeholder.swift, expected 1
  ok    plant-skipped-test [INV-7]: gate-test.sh quiet when clean, 1 finding(s) when planted
  ok    plant-ai-trailer [INV-8]: gate-hygiene.sh quiet when clean, 1 finding(s) when planted
  ok    plant-bad-format [format]: gate-format.sh quiet when clean, 1 finding(s) when planted
plant cases 8, contract cases 1, failures 2
```

**The gate defect.** `gate-build` emitted
`/private/var/folders/.../Sources/MidkeepKit/Placeholder.swift:12: INV-5: ...` where the contract
wants a repo-relative path. On macOS `$PWD` holds the logical path and the toolchain emits the
physical one — `/var/folders` versus `/private/var/folders` — so stripping only `$PWD` left the path
absolute. `gate-format` and `gate-test` shared the idiom and the bug.

This could not have been found by per-gate verification. Those blocks run in the checkout, where
logical and physical spellings coincide; the divergence only appears once a worktree under a temp
directory exists, which is to say only when the teeth harness runs. That is the harness earning its
place rather than demonstrating itself.

**The plant defect** is the inverse failure. `plant-force-unwrap.sh` planted correctly and then
refused, because its own landed-check used `value ..(maybe!)` where `..` consumed `\(` and left
`maybe!)` to match `(maybe!)`. Fixed with a fixed-string match.

A plant can fail in three ways and only one of them is invisible, which is worth stating precisely
because the obvious reading gets it wrong. A plant that **refuses** exits non-zero and teeth reports
the case as failed. A plant that **proceeds having planted nothing** leaves the gate quiet, and
teeth reports the mismatch between the expected finding and the zero it got. Both are loud.

The invisible case is the third: a plant that lands a **different** defect from the one it names.
The gate fires, teeth counts the expected finding, the case passes — and the harness has certified
teeth the gate does not have. That is what the landed-assertions exist for, and it is not
hypothetical: a probe using `sed -i '' 's|a|a\nb|'` inserted a mangled single line on BSD sed,
`gate-arch` fired on the mangled text, and the check passed while testing something other than what
it named.

The fix touched `gate-build.sh`, `gate-format.sh` and `gate-test.sh`, all introduced by Commit 5.
**Commit 5 was amended** rather than the fix riding in Commit 6: Commit 5 was HEAD, nothing was
pushed, and staging those paths in Commit 6 would have made a second path staged by two commits,
which § 1 says only `README.md` is.

The three amended gates were then re-verified against the amended content, because Commit 5's body
claims each gate was watched exiting 1, 0 and 2 and that had been observed against the pre-fix code.
27 checks, all passing, including that findings are now repo-relative and no finding begins with
`/`. `gate-arch`, `gate-hygiene` and `all.sh` were not re-run and did not need to be: the fix did
not touch them, shown by `git diff HEAD --name-only` returning nothing for each.

### Runtime, against the parked question

The plan defers teeth's cost to "whichever unit first pushes". Measured here instead, so that unit
inherits a number:

```
$ time bash scripts/gates/teeth.sh
20.45s user  11.19s system  74% cpu  42.249 total
```

Forty-two seconds wall for nine cases — eight worktrees each built from scratch, with `gate-build`'s
case compiling the package twice and `gate-test`'s once.

That is the number and not a verdict. It is one warm run, on one Apple Silicon machine, with a
populated toolchain cache. A GitHub macOS runner is a different machine with a cold cache and is
materially slower, and § 5 of the plan says in its own words that a harness which has only ever run
on one Mac is the failure this unit argues against. Whether teeth can run on every push is a
measurement for whichever unit first pushes; this entry gives that unit a starting figure rather
than an answer.

### The clean baseline — decided, and already in teeth.sh

`teeth.sh` runs the gate against the clean worktree before planting, per case, and treats a non-zero
result as a case failure. It is not left to each plant's verification. Every passing line reads
"quiet when clean, N finding(s) when planted" because both halves were asserted. Nine cases, nine
clean runs.

### The ninth plant — decided against, recorded as a hole

`gate-test` has two mechanisms: a text scan finds a disabled or commented-out test, and running the
suite finds a failing assertion. Two runs of teeth have now shown they fail differently — the scan
half is planted by `plant-skipped-test.sh`, and the running half needed its parser rewritten from
captured output after returning 2 for a failing suite.

A ninth plant would break the count derived from the invariant table and the ratified Acceptance
clause that `teeth.sh` reports eight plant cases. **ROADMAP → Known holes** takes the entry instead,
beside INV-1's positive direction: `gate-test`'s ability to catch a genuine test failure is verified
at Commit 5 and not watched by the harness.

### The plant guard is an identity check, not a presence check

A guard testing only whether `TEETH_WORKTREE` is set would plant a defect in the live repository if
it pointed there. Measured discriminator:

```
main working tree     --absolute-git-dir == --git-common-dir
linked worktree       --absolute-git-dir under .git/worktrees/, differs
not a repository      rev-parse exits 128
```

All eight plants were then run against the live repository deliberately — an adversarial test of the
guard, on real history rather than a worktree, run as a decision rather than by accident. All eight
exited 2, HEAD stayed at 5 commits, and `git status` was unchanged. Unset and non-repository both
exit 2 as well.

A marker file only `teeth.sh` writes closes the remaining case: a linked worktree of this repository
that someone is actually working in is refused as firmly as the main tree. Defence in depth was
checked too — a marker placed by hand in the repository root is still refused, by the
main-working-tree test, with `refusing to plant: /Users/<redacted>/dev/midkeep is the main working
tree`.

## What the two approval gates caught in Phase 3

The same measurement Phase 2 made, with its denominator stated, because a zero without one is an
empty set rather than a result.

**Denominator.** Phase 3 wrote sixteen repository files through the Write tool — `contract.sh`, six
gate scripts, `teeth.sh` and eight plants — and made roughly twenty-nine Edits to those same paths.
All of them are under `scripts/gates/**`, which `.claude/settings.json` ask-gates. So gate content
did pass through the file-write layer in volume; this is not a phase where edit approval had nothing
to look at.

**One limit on this measurement, stated rather than glossed.** From inside the session the tool
result is observable and the approval dialog is not. What can be said is that no file write or edit
in Phase 3 was rejected or amended at that step. Whether each was presented for approval or
auto-accepted cannot be determined here, and the author's own record is the authority on that half.

**Caught by edit review: zero.** No gate script was corrected before it ran.

**Caught by running things: five.** A `.disabled` plant that did not compile. A plant whose
landed-check misread `\(` as a group open. `gate-build` emitting absolute paths. `gate-test`
returning 2 for a failing suite because its parser was anchored at the start of the line. INV-4's
bracket expression, which could never fire.

**Caught by Bash approval: three.** Two blocks that could not parse, and a global FAIL counter read
back as a local result.

That inverts Phase 2, where edit review caught six prose defects and no gate content existed to
look at. The explanation is structural and survives the caveat above: Phase 2 produced prose, whose
defects are visible on the page, and Phase 3 produced executables, whose defects appear only when
run. Neither phase's tooling was wrong for the other's material.

## Commit 5 — the verification blocks were the only artifacts nothing validated

Three rounds were lost to commit blocks that could not parse. The harness checks every file it
commits and had no way to check the thing doing the checking, because an inline shell block is not
a file and nothing runs `bash -n` over it.

Two of those rounds were spent on a different failure. Two lines were reported as mangled — an `EXP`
assignment pointing at a nonexistent `scripts/gas/gates/` and omitting `gate-hygiene.sh`, and a
`probe.body` line truncated mid-substitution. Both were read from the approval dialog. Measured
against the file, `bash -n` returned 0, a grep for `gas/` found only the guard assertion looking for
it, and the block's own output printed `EXP` with all six paths present. `index.exact` then passed
against the six actually staged.

So both were false positives, which takes this session's total to **eight**. The count matters less
than the attribution, which is now unambiguous: every claim that failed came from reading a
rendering, and every finding read from command text was real. That is the Phase 2 rule confirmed by
its own hardest case rather than weakened by it.

**The rule from here: every commit block is a file, syntax-checked before it runs, invoked as one
command.**

```sh
bash -n "$SP/commit-NN.sh" || exit 1
bash "$SP/commit-NN.sh"
```

`|| exit 1` is the load-bearing half. A `bash -n` whose result is printed and not acted on is a
check that cannot fail, which is the defect this document has recorded four times in other forms.
The shape also has a second benefit that was the original argument for a checked-in verification
script: one analysable command rather than a wall of inline shell.

## Commit 5 — gate-test has two mechanisms and the plant list covers one

`gate-test` finds a disabled or commented-out test by scanning text, and a failing assertion only by
running the suite. Both were watched firing, and the running half needed its parser rewritten from
captured output — Swift Testing reports
`✘ Test "..." recorded an issue at PlaceholderTests.swift:8:5: ...`, a bare basename mid-line, and
no line begins with a path at all. A parser anchored at the start of the line saw a failing suite as
a toolchain failure and returned 2 for what is plainly a finding.

The ratified plant list carries one `plant-skipped-test.sh` against INV-7, which exercises the
scanning half only. **ROADMAP → Known holes owes an entry** beside INV-1's positive direction: the
gate's ability to catch a genuine test failure is asserted at Commit 5 and not watched by the teeth
harness, unless a plant covers it at Commit 6.

A related gap `skip.compiles` found: a plant-landed check verifies text arrived, not that the text
means what it was supposed to mean. The first `.disabled` probe used
`@Test(.disabled("flaky"), "name")`, which does not compile — traits follow the display name — so
the gate fired off the scan while the plant was broken. Every plant at Commit 6 asserts three
things: what arrived, what left, and that it still compiles where compiling is what makes the defect
real.

## Commit 5 — INV-4's check could not fire

`gate-hygiene`'s force-unwrap heuristic was written as `[A-Za-z0-9_)\]]!($|[^=])`. Backslash is not
an escape inside a POSIX bracket expression, so that parses as the set `A-Za-z0-9_)\` followed by a
**literal** `]` — the pattern required a `]` immediately before the `!` and could never match an
ordinary force unwrap. To include `]` in a set it has to come first: `[]A-Za-z0-9_)]`.

It was caught by watching the gate fail to catch a real force unwrap, and it would not have been
caught otherwise. The near-miss control — `!=`, a prefix `!`, and `\(x!)` inside a string literal —
passed while the pattern was broken, because a pattern that matches nothing satisfies every negative
control there is. This is the "watched both ways" finding for the third time, now inside a gate
rather than a verification block.

Watched in all three directions after the fix:

```
one real force unwrap                          exit 1, 1 finding
three near-misses alone                        exit 0, 0 findings
one real force unwrap beside all three         exit 1, exactly 1 finding
```

The third line is the ratified description of `plant-force-unwrap.sh` executed as a check at
Commit 5 rather than deferred to Commit 6, so the exclusions are proved on those forms before the
plant that depends on them is written.

## Commit 5 — a plant that plants the wrong thing

`sed -i '' 's|a|a\nb|'` does not expand `\n` on BSD sed. A verification probe using it inserted the
literal text `midkeep",n    swiftLanguageVersions:` — one mangled line rather than the two-line
opt-down being tested — and `gate-arch` fired anyway, on the `swiftLanguageVersions` text. The check
passed while testing something other than what it named.

Every probe now asserts that the plant landed in the shape intended, before the gate is run, and
multi-line insertion uses `awk` rather than BSD `sed`. This matters more at Commit 6 than here: a
plant that plants the wrong thing makes the teeth harness report that a gate has teeth it does not
have, which is the one failure the harness cannot detect about itself.

## Commit 4 — `finish` counted findings in a variable, and lost them

Found by review before `lib/contract.sh` landed, and closed before it did.

`finish` derived its exit status from a shell variable incremented by `finding`. In bash the last
element of a pipeline runs in a subshell, so a variable incremented there is discarded when the
subshell exits. Measured on the first implementation:

```
finding called directly                       finish exits 1   correct
finding inside `... | while read` loop        finish exits 0   tally lost
finding inside an explicit ( ) subshell       finish exits 0   tally lost
```

The consequence is worse than a wrong number. Findings are written to stdout by `finding` itself,
which is not affected by the subshell, so a gate scanning with
`grep -n "$pat" "$f" | while read -r line; do finding ...; done` would print every finding and then
exit 0. Anything reading exit codes believes the gate. A harness counting stdout lines sees the
findings. The two disagree, and the exit code — the thing the contract is *for* — is the one that
lies. That is the failure this repository exists to prevent, sitting in the primitive every gate is
built on, and a line-scanning gate is the natural place for that shape.

**Closed by tallying findings in a file** rather than a variable, created by `mktemp` when
`contract.sh` is sourced and removed by an `EXIT` trap. A file survives any subshell
unconditionally. Two alternatives were rejected: `shopt -s lastpipe` fixes only the last pipeline
element and only with job control off, leaving explicit subshells broken; and a documented rule
saying `finding` must not be called from a pipeline is discipline, which this repository does not
rely on anywhere else and should not start relying on in its own contract.

Verified in both directions, since a tally that always reports findings is as broken as one that
never does:

```
pipeline, one finding      exit 1, 2 stdout lines      pipeline, no finding      exit 0, 0 lines
explicit ( ), one finding  exit 1                      explicit ( ), none        exit 0
nested ( ) in pipeline     exit 1                      process substitution      exit 1 / exit 0
direct call                exit 1 / exit 0             tally file after exit     removed
```

Two obligations follow. **ADR-0005 carries this as part of the contract**, not as an implementation
note: the exit code is derived from a tally that must survive subshells, and the reason is that the
natural shape for a scanning gate puts `finding` inside one.

**Teeth coverage comes from the gates' own shape rather than a tenth case.** `gate-arch` and
`gate-hygiene` are line scanners and are written with the pipeline form deliberately, so
`plant-ui-in-kit.sh`, `plant-lang-mode.sh`, `plant-unchecked-sendable.sh`, `plant-force-unwrap.sh`
and `plant-ai-trailer.sh` all exercise a finding raised through a pipeline. Had the tally still been
a variable, five of the eight plant cases would have failed. No plant is added and the derived count
of eight stands.

One caveat recorded rather than fixed: a gate that installs its own `EXIT` trap replaces
`contract.sh`'s and leaks one tally file. That is a leak, not a wrong verdict, and no gate does it.

## Measure first, then write the entry once

The Falsified entry above cost five rewrites. Every one of them came from a claim written before the
thing it claimed had been measured: the cause was asserted, then corrected to a different asserted
cause, then measured and found to be the opposite of both. The probes that settled it took one
command.

This is the finding recorded two sections above — a claim earns trust by being watched, not by being
reasoned to — arriving in how this document was produced rather than in what it says. The rule
adopted for Phase 3: **run the measurement first and write the entry once, from its output.** A
Falsified entry in particular has no business being drafted ahead of the run, since its whole
subject is what the run disproved.

Two check-naming defects from the same episode belong here rather than in the entry. A check named
`probe.D.exit1` matched a heading string and never looked at an exit code — a name claiming more
than its pattern is how a green run certifies something nobody measured. And a check named
`oldcause.gone` asserted the absence of a sentence that quoted the superseded claim *and marked it
false*, which is precisely what a Falsified entry should contain; it was asserting the absence of
the right behaviour. Both are the same error as writing before measuring, one level down: the name
was chosen before the pattern that would have to justify it.

## Smaller findings from the same episode

**A count is a weaker claim than the thing counted.** `chk status_clean 2` counts
untracked entries and passes for any two, where `chk status '?? .claude/|?? docs/|'` compares the
content. The stronger form was already in use in this session and was regressed to the weaker one
while adding checks elsewhere — the same decay described above, and the same distinction the path
sweep draws between counting files and knowing which ones.

That conclusion is scoped, because the Commit 3 stop decided the opposite for half of it. The
invariant half — the INV-8 audit — moves into `gate-hygiene` at Commit 5 and stops decaying there.
The procedure half stays inline and will keep decaying, and that is the priced cost of not adding a
44th path, recorded here rather than wished away. The two are not in tension once the halves are
named; they would be if this sentence were read as a rule about all verification.

## Which gate reads which path

§ 3 marks invariants. It does not mark paths, and a path no gate reads is the same failure as an
invariant nothing enforces. Swept across the 43 ratified paths and across every platform and setting
the manifest declares.

| Path | Read by |
|---|---|
| `Package.swift` | `gate-arch` (INV-1), `gate-build`, `gate-format` |
| `Sources/**/Placeholder.swift` | `gate-build`, `gate-arch`, `gate-hygiene`, `gate-format` |
| `Tests/MidkeepKitTests/PlaceholderTests.swift` | `gate-test`, `gate-format`, `gate-build` |
| `.swift-format` | `gate-format`, via `--configuration` |
| `.githooks/commit-msg` | git, and `gate-hygiene` derives its family list from it |
| `scripts/gates/lib/contract.sh` | sourced by all five gates |
| `scripts/gates/gate-*.sh` | `all.sh`, `teeth.sh` |
| `scripts/gates/teeth/plant-*.sh` | `teeth.sh` |
| `scripts/gates/all.sh`, `teeth.sh` | `ci.yml`, `gates.yml` |
| `scripts/status.sh` | the Commit 12 write-boundary check |
| `docs/prompts/01-repository-and-harness.md` | the transcription check |
| everything else | **nothing** |

Three of those readings are decisions taken here rather than descriptions, because two of them
change what a gate has to do and all three would otherwise be silent holes.

**`Package.swift` gains a formatter.** The plan's lint invocation covers `Sources` and `Tests`, so
the manifest — Swift source under a formatter this repository committed precisely so the criterion
would be in the tree — was read by no formatter at all. `gate-format` lints `Package.swift`,
`Sources` and `Tests`.

**`Tests/` comes under INV-5.** `swift build` does not build test targets, and `gate-test` runs
`swift test` without `-Xswiftc -warnings-as-errors`, so a warning in a test was invisible to the
invariant that forbids warnings. `gate-build`'s debug pass adds `--build-tests`. The release pass
does not: a release build of test targets is not a configuration anything ships.

**`.iOS(.v17)` stays uncompiled, and it is a Known hole.** `swift build` targets the host, so every
gate in this unit runs against macOS and the iOS deployment target ADR-0004 argues for is declared
and never exercised. Closing it needs an iOS SDK build, which needs the Xcode project from unit 02.
The driving prompt is explicit that no simulator is needed here, so this is the spec working as
intended rather than an oversight — but it means ADR-0004's subject is asserted, not tested.

The rows above account for 25 paths: the manifest, three sources, one test, `.swift-format`, the
hook, `contract.sh`, five gates, eight plants, `all.sh` and `teeth.sh`, `status.sh`, and this file.
So `everything else` is 18, and it enumerates to exactly 18: `LICENSE`, `.gitignore`, `CLAUDE.md`,
`README.md`, the two workflow files, `docs/adr/README.md` and the six decision records,
`docs/ROADMAP.md`, `docs/prompts/README.md`, `.claude/settings.json`, `.claude/rules/gates.md` and
`scripts/dev/bootstrap.sh`. 25 and 18 close at 43, which is the point of doing the sweep at all.

That resolves into a single Known holes entry rather than eighteen. For the documentation it is
expected — the house-style review at Phase 5 is what reads those, and INV-11 is marked UNENFORCED
for exactly this reason.

Three are worth naming individually, by the criterion that something other than a human acts on
them. The two workflow files are executed by GitHub and are never syntax-checked by anything in the
tree. `bootstrap.sh` is run by CI but read by no gate, which matters because it sets
`core.hooksPath` and so carries INV-8's entire local layer. And `.gitignore` is acted on by git
itself: the rule keeping `.claude/settings.local.json` out of the repository is now checked by
nothing, since the only thing that ever checked it was a `git check-ignore` in an inline block early
in this session. A wrong line there either commits a per-machine override or silently hides a
ratified path, and both are what a gate is for.

The two counts in this section, 25 and 18, are hand-maintained. Nothing derives them: which gate
reads which path is a mapping that exists only in this table, so a script counting files could not
reproduce the split without being handed the same mapping. Assumption 4 refused a hand-typed
constant inside a *generated* block, which is a different thing — a generated block claims to be
derived. This paragraph claims only to have been added up, and it is marked as such so a later
reader knows which kind of claim it is. Anyone editing the table at Commits 8 to 10 has to re-add.

### Commit 3 — the macOS-platform experiment

Run immediately after Commit 3 landed, per ratified assumption 5. `.macOS(.v14)` was removed from
the manifest, the package was built, and the manifest was restored with `git checkout --`.

```
platforms: [.iOS(.v17), .macOS(.v14)],     ->     platforms: [.iOS(.v17)],

$ swift build
exit=0
[0/1] Planning build
Building for debugging...
[2/3] Compiling MidkeepKit Placeholder.swift
[3/3] Emitting module MidkeepKit
[4/5] Compiling MidkeepUI Placeholder.swift
[5/5] Emitting module MidkeepUI
[6/7] Compiling MidkeepApp Placeholder.swift
[7/7] Emitting module MidkeepApp
Build complete! (16.61s)
stderr: (empty)
```

The build succeeded. There is no compiler message to quote, so ADR-0004 records the successful
build verbatim and says the platform is declared for what Kit and UI will import rather than for
what the compiler currently demands. Under neither outcome does the ADR assert what happens without
the platform; it reports what was observed on this toolchain, Swift 6.3.3.

Restore verified: `git status --porcelain -- Package.swift` empty, `macOS(.v14)` present again, and
the working tree back to `?? .claude/` and `?? docs/`.

## Falsified

Append-only, dated. What the run disproved that nobody predicted. Each entry cites evidence that can
be re-run: a command and its output, or a `file:line`. A correction made during the Appendix B
transcription cites the passage it corrects, quoted, because no gate has run at that point and the
evidence is the contradiction on the page.

### 2026-08-01 — the gate specification carried one paragraph twice, verbatim

Found while transcribing Appendix B into § Constraints. This is the first correction to enter
through the amendment channel, and the evidence is the contradiction on the page rather than a
command, because no gate had run at that point.

The seed's `gate-arch` section carried this paragraph twice, in immediate succession, with no
intervening text and no difference between the two:

> Do not check INV-1 by building with `-Xswiftc -strict-concurrency=complete`. Forcing the flag on
> the command line imposes the setting the gate is supposed to be verifying, so a target that opted
> down still compiles under the forced flag and the check reports on a configuration nobody ships.

> Do not check INV-1 by building with `-Xswiftc -strict-concurrency=complete`. Forcing the flag on
> the command line imposes the setting the gate is supposed to be verifying, so a target that opted
> down still compiles under the forced flag and the check reports on a configuration nobody ships.

The transcription carries it once. The instruction is unaffected — it was never in dispute, and
`gate-arch` implements it — so what changed is the text and not the rule.

Recorded because the amendment channel exists for exactly this and had not yet been exercised. A
specification surviving in two places drifts in one of them; a paragraph surviving twice inside one
place is the same failure at smaller scale, and the transcription is where it gets fixed rather than
carried forward.

The correction is visible in § Constraints in two forms: the instruction, once, in the `gate-arch`
section; and its citation in that section's own list of corrections. Any check asserting the
collapse has to distinguish those two — matching the opening clause alone counts both and reads as
a failed collapse against a correct file.

### 2026-08-01 — adding `import SwiftUI` does not make the macOS platform load-bearing

Ratified correction 1 to the Phase-1 plan reads: "Without it the Commit 3 experiment probably
produces no error at all: the placeholders import nothing, removing `.macOS(.v14)` would build
clean… With it, the default macOS deployment target and SwiftUI's minimum collide and the error is
real."

The import was added for that reason and the build came back clean. **Correction 1 is vindicated in
substance and falsified in mechanism**: the collision it predicted is real, and a bare import is not
what surfaces it. This entry is not a refutation of the correction's reasoning, only of its
assumption about what triggers the check.

An earlier version of this entry recorded the cause as "SwiftPM's default macOS deployment target is
already at or above SwiftUI's minimum". That was asserted, not measured, and it is false in the
opposite direction — the default is *below* SwiftUI's minimum. Five probes settle it.

```
A  triple, manifest WITH .macOS(.v14)      -target arm64-apple-macosx14.0
B  triple, manifest WITHOUT                -target arm64-apple-macosx10.13

C  unused `import SwiftUI`, WITHOUT        exit=0   Build complete! (0.17s)
D  a real SwiftUI use,      WITHOUT        exit=1
     Sources/MidkeepUI/Probe.swift:4:20: error: 'View' is only available in
     macOS 10.15 or newer
E  the same real use,       WITH           exit=0   Build complete! (1.18s)
```

Triples come from the `swift build -v` line that compiles
`Sources/MidkeepUI/Placeholder.swift`, isolated from the line that compiles the manifest itself,
which always carries the host default and would otherwise make the pair ambiguous. Probe D used a
four-line `Probe.swift` declaring `struct Probe: View`, removed afterwards.

B is the decisive reading: 10.13 is *below* SwiftUI's 10.15, not above it. The default does not meet
SwiftUI's minimum, so the reason C builds clean is that an unused import never triggers availability
checking at all. D and E show what the declaration is actually worth: with the platform removed a
real SwiftUI use fails, and with it restored the identical source compiles.

So the platform declaration is load-bearing — correction 1 was right about that — and the original
experiment could not have shown it either way. `MidkeepUI` contains no SwiftUI *use*, only an
import, so removing the platform was never going to produce a diagnostic. The experiment tested
nothing, and a clean build was the only outcome it could have produced.

The correction's error is narrow and worth stating precisely, because the ADR depends on it: it
assumed importing a framework subjects a module to that framework's availability floor. It does not.
Only using an API from it does.

Three consequences.

ADR-0004 quotes probe D rather than the empty build: it is the only run in which the manifest's
platform list changed a compiler outcome. The ADR also has to say what its evidence is about — the
experiment removes the macOS declaration and builds for macOS, so the diagnostic concerns macOS and
SwiftUI's minimum, while the ADR is titled for the iOS 17 deployment target which the sweep records
as never compiled anywhere in this unit. One sentence, citing that Known holes entry, or a reader
takes a macOS diagnostic for evidence about iOS.

The disproved reason had propagated to three places and all three have moved. It was recorded here;
Commit 3's body said "which is what makes that module's platform requirement real rather than
nominal" and now says "which INV-3 permits to that module and which unit 02 will use";
`Sources/MidkeepUI/Placeholder.swift` carried the same sentence and now gives the same weaker,
honest reason. Both were corrected in a single amend of Commit 3, verified from the HEAD object.

`import SwiftUI` stays, on the reason that survives: INV-3 permits it to `MidkeepUI` and unit 02
will use it.

## Prompt deltas

Where this unit departed from the driving prompt, and why.

### INV-12 added, marked UNENFORCED — commit message shape

The driving prompt specifies eleven invariants. None covers the shape of a commit message: INV-8
covers trailers and nothing else. Seventy-two columns is therefore either a new invariant or it is
nothing, and adopting it silently would leave Commit 3 free to reintroduce a long line with nothing
noticing.

INV-12 is added and marked UNENFORCED, the mark INV-6, INV-10 and INV-11 already carry. Promoting it
to a gated invariant was the alternative: `gate-hygiene` would check it over its resolved commit
range and a ninth plant would follow. That was rejected because it widens Commits 5 and 6, both
specified and ratified before this rule existed, and because the plant count is derived from the
invariant table rather than chosen.

Evidence, at the two commits either side of the amend:

```
4d663458   body lines over 72: 7    longest: 161   (pre-amend, unreachable)
b50b9c52   body lines over 72: 0    longest:  71
```

Commit 2 was amended on HEAD to comply. **The rule binds from Commit 2 onward; Commit 1 is exempt.**
Of the two available responses — amend Commit 1 to comply, or write the exception down — the second
was chosen, and the decision is recorded here before any check asserts it.

INV-12 was adopted during Commit 2's amend, so Commit 1 was never measured against it. That alone
would only be an argument from age. The decisive reason is that Commit 1 is the root commit:
amending it rewrites the hashes of Commits 2 and 3, and `1a132dd`, `b50b9c5` and `158ef70` are
already cited in the plan document's Commit 3 stop, in Results, and in the Falsified entry above.
Rewriting the root would falsify every recorded hash in a document whose entire argument is that a
claim cites evidence someone else can re-run. A 73-column line is a smaller cost than that.

**Unit 02 editorial note, 2026-08-01 — the hashes in this section were rewritten.** A prompt file is
historical and is never edited to match later reality. This is the one exception in this document,
and it is marked rather than made silently. Unit 02 rewrote all twelve commits to move every author
and committer address to `61488202+sebkoo@users.noreply.github.com`. The hashes cited here then named
objects that no longer existed, so the citations stopped being re-runnable — which is the property
this passage argues for. They now name the rewritten commits. The originals were `f22c608`
(Commit 1), `334438d` and `334438db` (Commit 2), `0d1904c` (Commit 3), and `4d663458` (Commit 2
before its amend, already unreachable then and expired by the rewrite; it survives only in a
pre-rewrite backup).

The paragraph above is not refuted. It weighed a rewrite of the root against the loss of recorded
hashes and chose the hashes, and that reasoning holds for the case it was made about. Unit 02 weighed
the same rewrite against a personal address in every commit of a history intended to go public,
answered the other way, and paid the cost this paragraph names by repairing the citations in a second
pass. Both readings stand side by side; neither supersedes the other silently. Recorded in
`docs/ROADMAP.md` under Findings.

The tripwire below did not fire and could not have. It counts over-72 lines in the root commit's
message, which a change of identity leaves untouched — a tripwire on message shape does not detect a
rewrite.

Measured across the whole history rather than asserted, since a sweep of `git log` is what a later
reader would run:

```
1a132dd  over72=2   chore: reject AI attribution trailers via commit-msg hook
b50b9c5  over72=0   chore: add MIT license, ignore rules and formatter configuration
158ef70  over72=0   build: add Swift 6 manifest, three modules, placeholders and a test

  73 cols: scripts/dev/bootstrap.sh. Installing the hook path is the same concern as
  75 cols: No gate exists before Commit 5. Checked with `bash -n .githooks/commit-msg`
```

Both are Commit 1's. A whole-history check of INV-12 therefore expects 2, not 0, until Commit 1
leaves the history — which it does not. Any later gate or check that sweeps all messages has to
carry that exemption explicitly, or it reports a violation every run and gets ignored, which is how
a check stops being read.

That expectation is a tripwire, not a tolerance: it goes red if anyone amends Commit 1, which is
exactly the event the exemption exists to prevent. Written bare it reads as a hardcoded 2 and the
next reader "fixes" it to 0, losing the decision silently. It carries the same kind of comment
`family_count` does, naming what it guards:

```sh
# Tripwire, not a tolerance. Commit 1 is the root and predates INV-12; amending
# it would rewrite the hashes of Commits 2 and 3, which are cited across this
# document. Expecting 2 means "the exemption is intact". If this goes red,
# someone rewrote the root — do not change the 2 to make it pass.
chk inv12.root.exempted 2 "$(git log -1 --format='%B' "$(git rev-list --max-parents=0 HEAD)" | awk 'length>72' | grep -c .)"
```

### `scripts/gates/gate-workflow.sh` added — a 44th path

The ratified tree is 43 paths. This is the 44th, and unlike `verify-commit.sh` — which was proposed
and rejected earlier for the same reason — it stays.

The path sweep found `.github/workflows/ci.yml` and `gates.yml` among the three paths something
other than a human acts on and nothing in the tree reads. GitHub executes them. Until this gate they
were the only executables here with no check of any kind: not linted, not parsed, not run.

`gate-workflow` runs `actionlint`, which validates the workflow schema and, when `shellcheck` is on
`PATH`, checks the `run:` blocks too. Both were present on this host, so the green result covers the
shell that invokes `bootstrap.sh`, `all.sh` and `teeth.sh`. Watched in three directions:

```
real workflows                exit 0, 0 findings
uses: and run: in one step    exit 1, 1 finding on .github/workflows/ci.yml
actionlint absent from PATH   exit 2, "actionlint not installed", 0 findings
```

Reconciliation becomes **44 of 44** in both directions. `all.sh` runs six gates.

**The plant count stays at eight, and the reasoning is worth recording because § 4 could be read
the other way.** § 4 derives eight as seven invariants claimed by a gate plus `gate-format`. Read as
a general rule — every gate claiming no numbered invariant gets a plant — `gate-workflow` would make
nine. Read as the driving prompt states it, the general rule is "one plant per invariant a gate
claims to enforce, not one per gate", and `gate-format` is a named exception with a reason specific
to it: a decorative formatter is the failure `--strict` exists to prevent.

The second reading is taken, for three reasons. Acceptance says `teeth.sh` reports eight plant cases
and is ratified, so a ninth needs a fourth delta editing an acceptance clause. This unit already
denied `gate-test`'s running half a plant on exactly that ground, and reversing it here would make
the earlier decision arbitrary. And `gate-workflow` has been watched failing and watched staying
quiet — the readings above — just not by `teeth.sh`.

That leaves it as the only gate outside the harness, which is a Known hole and is recorded as one. A
later unit that wants the ninth plant needs an Acceptance delta and should have it.

### § 1's per-commit assignment and its "only path staged twice" sentence

Two ratified statements changed, and both are recorded here rather than left to be discovered by
counting.

**Commit 7 introduces three paths, not two.** § 1 assigns it
`.github/workflows/ci.yml` and `.github/workflows/gates.yml`, and puts gate scripts in Commit 5.
`gate-workflow.sh` landed in Commit 7 instead. Amending Commit 5 was the alternative: it would have
kept gate scripts in the commit whose subject describes them, at the cost of reopening a commit two
phases back and rewriting Commits 6 and 7's hashes — the same objection that kept Commit 1 exempt
from INV-12. Landing it forward was chosen; the cost is that Commit 7's subject,
`ci: add build and gate workflows`, describes two of its three new paths.

As landed, the per-commit counts are 2, 3, 5, 1, 6, 9, 3 for Commits 1 to 7, against § 1's
2, 3, 5, 1, 6, 9, 2. Commits 8 to 12 are unchanged at 7, 3, 3, 1, 1. Total 44.

**`README.md` is no longer the only path staged by two commits.** § 1 says it is.
`scripts/gates/all.sh` is now staged by Commit 5, which introduced it, and by Commit 7, which added
`gate-workflow` to its gate list. It is still introduced by exactly one commit, so the reconciliation
holds in both directions; what changed is the uniqueness claim beside it.

This is the objection that moved `verify-commit.sh` out of Commit 3 earlier in this unit, and it was
incurred deliberately this time rather than avoided. The alternative — a gate sitting in the tree
that `all.sh` never runs — is worse than a falsified sentence about staging, and the sentence is
corrected here instead of quietly outliving its truth.

### `all.sh` was edited outside its own commit

`scripts/gates/all.sh` belongs to Commit 5, which closed when Commit 6 landed, so it cannot be
amended. Adding `gate-workflow` to its gate list rides in Commit 7 instead, under the driving
prompt's named-exception rule: the commit body says which file was touched outside its concern and
why, and this is that record.

Without it the new gate would sit in the tree and never run, which is worse than not adding it.

### The definition-of-done INV-8 proof was rewritten

The driving prompt's proof greps history with `co-authored\|generated with\|claude-session`. Three
corrections were made and are recorded in full under Results: BRE alternation replaced by `-E`
because `\|` is a GNU extension and `gates.yml` runs on a macOS runner; the bare `generated with`
and bare `co-authored` narrowed to mirror the hook exactly, because both false-positive on
legitimate content — a human co-author, and this repository's own sentence about a sample generated
with `plant-bad-format.sh`; and the family list derived from the committed hook rather than retyped,
after being retyped wrongly three times in three rounds.

This opens a ROADMAP → Findings entry sourced to this unit, since the passage sits outside
Appendix B and has no Falsified home.
