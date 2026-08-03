# midkeep

## Orientation

An iOS client built around resumable multi-step runs: the unit of persistence
is the half-finished run, not the finished result. Why that is the interesting
unit is ADR-0002.

At this commit there is no runtime. What exists is the harness — the gates, the
invariants they enforce, and the proof that each gate fails when it should. It
was built before there was any Swift to check, because the cost of adding a
rule grows with the amount of code that has to change to satisfy it.

Rationale lives in `docs/adr/`. This file states the rules; it does not argue
for them.

## Layout

```
Sources/MidkeepKit    runs, journal, engine contracts. No UI, no third party.
Sources/MidkeepUI     views. May import SwiftUI and MidkeepKit, nothing else.
Sources/MidkeepApp    composition root. Nothing imports it.
Tests/                Swift Testing.
scripts/gates/        seven gates, one contract, one teeth harness.
scripts/dev/          bootstrap. Sets core.hooksPath.
docs/adr/             decisions.
docs/prompts/         per-unit lab notes: asked, predicted, observed, falsified.
```

Swift Package Manager is the source of truth. There is no Xcode project yet, so
nothing runs on a device — ADR-0003.

## Invariants

Every invariant carries one of three marks: the gate that enforces it, PARTIAL
with the gate and what the gate cannot see, or UNENFORCED. A rule with no
enforcement and no admission of that is worse than no rule, and a rule whose
check is weaker than its wording is the same failure wearing a gate's name.
Where the tool is weaker than the rule, weaken the mark, never the rule.

1. **INV-1** — Swift 6 language mode, strict concurrency complete, every
   target. (`gate-arch`, reading `Package.swift` in two directions. Positive:
   the `swift-tools-version:` line is 6.0 or later, which is what actually puts
   every target in Swift 6 mode. Negative: nothing opts back out. Both are
   needed — under Swift 6 mode complete checking is implied and never appears
   in the manifest, so an opt-down search alone passes a manifest that declares
   nothing at all.)

2. **INV-2** — No `@unchecked Sendable`, `nonisolated(unsafe)` or
   `@preconcurrency import` in `Sources/`. Tests may, with
   `// INV-2-EXEMPT: <reason>`. (`gate-hygiene`)

3. **INV-3** — `MidkeepKit` imports no UI framework and no third-party module;
   `MidkeepUI` imports `MidkeepKit` and SwiftUI only; nothing imports
   `MidkeepApp`. (`gate-arch`. This is a source-level property and a test
   cannot assert it — a test can only observe what its own target links, not
   what another module chose to import.)

4. **INV-4** — No force unwrap or `try!` in `Sources/`. Tests exempt.
   (`gate-hygiene`, PARTIAL — the rule is absolute and binds anyone writing
   here; the check is a line-level match and cannot find Swift's literal
   boundaries, so multiline strings, raw string delimiters and nested
   interpolation pass it. Named in ROADMAP → Known holes. Closes when a
   syntax-aware check earns its ADR. Do not soften the rule to match the tool.)

5. **INV-5** — Warning-free debug and release build, no suppression mechanism.
   (`gate-build`, which passes `-Xswiftc -warnings-as-errors` and adds
   `--build-tests` to the debug pass so `Tests/` is covered too.)

6. **INV-6** — No new dependency without an accepted ADR. (UNENFORCED —
   `Package.swift` is `ask`-gated in `.claude/settings.json`, and a settings
   file is a convenience a fresh clone does not have. Nothing in the tree stops
   a dependency being added.)

7. **INV-7** — No test skipped, disabled or commented out on `main`.
   (`gate-test`)

8. **INV-8** — No AI-attribution trailer in any commit message or PR body.
   (`.githooks/commit-msg` + `gate-hygiene` + CI. ADR-0006.)

9. **INV-9** — Every gate obeys the exit contract. (`scripts/gates/teeth.sh`.
   ADR-0005.)

10. **INV-10** — Every step a run takes is journalled before its effect is
    observable; no run state lives only in memory. (UNENFORCED — no runtime
    exists. The invariant the product rests on, and the one that cannot be
    gated until there is code. ADR-0002.)

11. **INV-11** — Every statement of what the repository *does* names the file,
    script or run behind it. A statement of what it is *for* is not that kind
    of claim and needs nothing behind it. Unmeasured things say "not measured
    yet"; unbuilt things are not listed. (UNENFORCED — reviewed by hand.)

12. **INV-12** — Every commit message has a single-line subject under 72
    bytes and a body wrapped at 72. Bytes, because bytes are what the checks
    that have measured this rule count, and in UTF-8 a line inside a byte
    limit is always inside the same character limit, never the reverse — the
    byte reading is strictly the more conservative one. Bytes, characters
    and display columns coincide today only because the tree holds no wide
    characters; the first substantially non-ASCII line reopens the choice,
    and ROADMAP → Findings states that trigger. (UNENFORCED — no gate reads
    message shape; INV-8's checks cover trailers only. Binds from Commit 2
    onward. Commit 1 is the root commit and is exempt because it predates
    the rule, which was adopted during Commit 2's amend. Its two over-72
    lines, at 73 and 75 bytes, are the only artifact in the tree recording
    that the rule arrived mid-unit, and the `inv12.root.exempted` tripwire
    exists to keep them: a whole-history sweep expects 2, not 0. An earlier
    version of this note gave a different reason — that amending would
    invalidate cited hashes — which unit 02 falsified by action. ROADMAP →
    Findings carries it.)

13. **INV-13** — No paid GitHub usage. The readable clauses: every `runs-on`
    in every workflow names a standard GitHub-hosted runner label — the set
    that is free on a public repository — never a large-runner or custom
    label; and `runs-on: macos-*` appears only in a job that needs a Swift
    or SwiftUI build. (`gate-runners`, PARTIAL — the gate carries both
    clauses and `teeth.sh` proves each going both ways, the move the
    previous mark promised, made on 2026-08-03 by enforcement rather than
    amendment. PARTIAL for what a grep with no YAML parser cannot see — a
    job calling a reusable workflow has its runner chosen in the called
    file, and the gate's header names its false positives — and because
    the marker clause checks a declaration, not the need it declares:
    whether a `macos-*` job truly requires a Swift build stays a
    hand-review question. The unreadable half
    stays: the spending limit lives in account settings nothing in this
    tree can reach, and the Actions timing API read `billable.MACOS.total_ms`
    of 0 against non-zero `run_duration_ms` on 2026-08-01. Clause 1 replaced
    a push-trigger ban by amendment on 2026-08-02: the ban was right when
    written — a private repository running `macos-*` jobs on push triggers
    was the one configuration that could bill — and was overtaken when the
    repository went public the same day it was added, not refuted. The
    amendment holds only while the repository is public; if visibility ever
    flips to private, push triggers become a paid path again and this
    invariant is owed a revisit. Visibility is not readable from the tree,
    so no tree-gate can assert that condition. ROADMAP → Findings carries
    the amendment and its grounds. Where the tool is weaker than the rule,
    the mark is weakened and the rule is not.)

INV-6, INV-10, INV-11 and INV-12 staying visibly unenforced is deliberate. Do
not invent a gate to make the list look complete. INV-13 is different: its
readable half is enforced by `gate-runners` since 2026-08-03, and its
unreadable half never will be.

## Commands

```
scripts/dev/bootstrap.sh     install the hook path. Idempotent. Run once.
scripts/gates/all.sh         every gate. 0 clean, 1 findings, 2 no verdict.
scripts/gates/teeth.sh       prove each gate fails on a planted defect.
scripts/status.sh            regenerate the README status block from git.
swift build                  debug.
swift test                   Swift Testing.
```

Gate exit codes are `0` ran and found nothing, `1` ran and found something with
findings on stdout, `2` reached no verdict with a reason on stderr. Never 2 for
findings, and never 1 for a tool that could not look. ADR-0005.

## Working agreements

Conventional Commits, imperative mood, one concern per commit. Subject on one
line under 72 bytes, body wrapped at 72. No trailer of any kind.

Stage by path — `git add -- <paths>` — never `git add -A`.

`git commit --amend` repairs the commit you are standing on and nothing else. A
commit with a child is closed.

Before each commit, run the gate that covers it. Do not make a commit that
would fail its own gate.

A check earns trust by being watched go both ways. A check that has only been
seen passing, or only seen failing, proves nothing in either direction — the
observation is consistent with the check being broken. This is why
`teeth.sh` asserts a clean tree exits 0 before it plants anything, and it
applies to any assertion added later.

When a claim is disputed, measure it against the artifact rather than against a
rendering of the artifact.

A finding of absence is a claim and needs a positive control, exactly as a
finding of presence does. An empty result is not evidence until the same pattern
has been watched finding something it was supposed to find. `\b` is a literal
`b` to `git grep`, which is how an empty sweep retracted a correct claim here.

A sentence reporting what a command printed is a measurement: date it, keep it,
and append what no longer holds. A sentence asserting a general fact is a claim:
falsify it and record what falsified it. Deciding which kind a sentence is comes
before deciding how to correct it.

Every figure in the record names what it counted. Three incidents in one day
produced the rule: the About string measured 146 bytes by `wc -c` against 143
characters, an `awk length` width check read 83 bytes against 79 characters, and
`git grep -c` reports matching lines where the sentence around it meant
occurrences. Bytes, characters, lines, occurrences, files and forms are six
different counts, and a bare number picks one silently. A sentence in this
repository saying `/Users/` "appears four times" was wrong by that mechanism —
six occurrences, four forms, three files.

When quoting terminal output, quote the command and its output and never the
prompt line. A shell prompt carries the account name and the hostname in one
string, and this repository's method is to paste tool output verbatim, so the
prompt is the likeliest way either reaches a public tree. No gate catches it: a
prompt is not a `/Users/<name>/` path and, having no dot in the hostname, is not
email-shaped either. A one-line rule closes it more cheaply than a fiddly check.

When an approach is abandoned, record why.
