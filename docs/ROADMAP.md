# Roadmap

## Where this is going

Each rung is something the software can do, not something that was built. The
marker shows where it is now. This ladder is maintained by hand.

```
  can learn      signals captured, offline evaluation closes the loop
  can choose     work routed on device or to a server, one contract either way
  can run        a multi-step run executes and streams
> can recover    a killed run resumes from its journal
  can install    an app that launches on a device
  can build      the package compiles, the tests pass, the gates bite
```

Everything below the marker is done. Everything above it is not started.

## Findings

Dated, sourced to the unit that found them, with a disposition. Every entry
cites something re-runnable.

**2026-08-01 — INV-10 has no gate and cannot have one yet.** Unit 01. Every
step a run takes must be journalled before its effect is observable, and there
is no runtime to check. Disposition: revisit when the journal lands.

**Revisited, 2026-08-04.** The journal landed and the run engine followed
with the ordering test; the mark moved to PARTIAL in the commit carrying
the test (unit 04, ruling D6). Not a gate: `gate-test` runs the suite,
and the boundary — a test sees only the step types it drives — is stated
in the invariant's own row.

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

**2026-08-01 — three invariants marked enforced are not.** Unit 02. The review
covering all twelve invariant dimensions, left outstanding when unit 01 closed,
found that INV-2, INV-3 and INV-7 each carry a gate that one line of ordinary
Swift walks past. Every reading below was taken in a detached worktree, against
a control run the other way, and every planted line compiles.

`@_exported import UIKit` in `Sources/MidkeepKit/` is silent on all six gates;
plain `import UIKit` is a finding. `gate-arch.sh:89` matches `import` with no
attribute prefix, and the separate check at `gate-arch.sh:105` allows
`(@[A-Za-z]+[[:space:]]+)?`, which `_` does not match, so
`@_exported import MidkeepApp` passes as well. Three checks, one attribute,
all blind.

`@preconcurrency` on its own line above `import` is silent on `gate-hygiene`;
the same two words on one line are a finding. `gate-hygiene.sh:26` requires
`@preconcurrency[[:space:]]+import` and cannot see across a line break.

`@Test("...", .enabled(if: false))` over a body asserting `1 == 2` leaves
`gate-test` at 0 with the suite green; the same body with no trait exits 1 with
the finding. `gate-test.sh:32` names `.disabled(`, `XCTSkip` and
`withKnownIssue`, and `.enabled(if:)` is a fourth way to disable a test.

None of the three belongs under Known holes. A Known hole records something
nothing checks; these are three rows claiming a check they do not have, which
is the distinction that also decided the Xcode project.

Disposition: each is one line to plant.

```
@_exported import SwiftUI            in Sources/MidkeepKit/
@preconcurrency on its own line, import on the next
.enabled(if: false) on the single @Test
```

A mark returns to enforced when its plant exists and has been watched going
both ways. Until then the three are PARTIAL, and CLAUDE.md § Invariants owes
the same weakening: it carries a bare gate name for each, and its own rule is
to weaken the mark where the tool is weaker than the rule.

Unit 01 closed with this review outstanding rather than rounded off. Three
false enforced marks is what that decision bought — none of them is visible
from reading a gate's description, and all three came out of running it against
a control.

**2026-08-01 — INV-4's admitted range is wrong in both directions.** Unit 02.
CLAUDE.md and Known holes below both said the heuristic under-fires, naming
multiline strings, raw string delimiters and nested interpolation as the forms
that defeat it. Measured, it fails both ways, and neither is what was written.

`gate-hygiene.sh:61` strips `"[^"]*"` before scanning, which leaves the body
lines of a `"""` block bare, so a force unwrap written inside one is reported.
That is a false positive, and a multiline string is where the wording said the
opposite would happen.

`"value \(maybe!)"` is not reported, and it is a real force unwrap that INV-4
forbids without exception. `plant-force-unwrap.sh:42` plants that form as a
near-miss and its teeth case asserts exactly one finding, so the harness
certifies the blindness rather than merely failing to notice it.

Disposition: the Known holes wording is corrected below. The rule is not
softened. A syntax-aware check needs SwiftSyntax, which is a dependency and so
needs an ADR under INV-6.

**2026-08-01 — a generated block cannot describe the commit that carries it.**
Unit 02. `README.md:55` reads `commits | 11` against a twelve-commit tree, and
it is not a wrong digit. Commit 12 introduces `scripts/status.sh` and stages
the README that script generates, both in the one commit, so the run happened
with HEAD at Commit 11: `git rev-parse 1c16da5^` is `5ce894d`,
`git rev-list --count 5ce894d` is 11, and `git show 1c16da5:README.md` carries
the 11 as committed. Every generate-then-commit repeats it.

**Discharged after the host-path redaction, 2026-08-01.** Those three commands
name hashes that no longer resolve. The derivation above is a measurement and
is kept as taken; the successors come from `.git/filter-repo/commit-map` and
are appended rather than substituted. Re-run at this commit it reads `git
rev-parse ce1756b^` is `6ad1132`, `git rev-list --count 6ad1132` is 11, and
`git show ce1756b:README.md` still carries `| commits | 11 |`. The finding —
that a generated block cannot describe the commit that carries it — never
depended on which hashes name the commits, and survives both rewrites
unchanged.

This answers assumption 4 of unit 01's plan from the other side. That
assumption refused a hand-typed constant inside a generated block so the number
could not go stale. The commit count is derived rather than typed, and stale
regardless — the same failure by the opposite mechanism, and the reasoning that
caught the one missed the other.

Disposition: a decision rather than a fix, and none of the three is free. Say
in the block that it describes the parent commit. Drop the commit count. Or
generate after committing and amend, which puts `README.md` back into the
staging question § 1 of that plan spends a sentence on.

**2026-08-01 — the repository has a recorded procedure for duplicated
paragraphs and shipped another one.** Unit 02. `.claude/rules/gates.md:73` and
`:77` carry the same sentence twice — "If you are changing documentation, the
gates will stay green and will have told you nothing." — the first instance
alone continuing into a third line.

§ 6 correction 3 of unit 01's plan exists because Appendix B carried a
paragraph twice, verbatim; the transcription collapsed it and logged the
collapse under Falsified. That procedure governs the seed. Nothing governs the
tree, and the same defect landed in the one file whose subject is what the
gates do not read.

So this is a pattern rather than an item: duplication survives every check here
because no gate opens a document, which is what Things nothing reads below
records. Disposition: the duplicate is cut when unit 02's repairs land. Whether
anything can check for it is open; a duplicate-paragraph scan over `docs/` and
`.claude/` is the candidate.

**2026-08-01 — INV-5's second half has no check and is defended by a flag
conflict.** Unit 02. The invariant forbids a warning and a suppression
mechanism. `gate-build` enforces the first with `-Xswiftc -warnings-as-errors`;
nothing reads the manifest for the second. Measured: `MidkeepKit` given
`.unsafeFlags(["-suppress-warnings"])` beside an unused binding drives
`gate-build` to exit 2 — `cannot run: swift build failed with no parsable
diagnostics (debug 1, release 1)` — because swiftc refuses the pair with
`error: conflicting options '-warnings-as-errors' and '-suppress-warnings'`.
The same binding without the flag exits 1 with the finding.

Loud, and under the wrong code. The contract reserves 2 for "could not look",
and what happened is that the tree did what INV-5 forbids. A suppression route
that does not collide with `-warnings-as-errors` would meet no check at all.
Disposition: open. A manifest scan in `gate-arch`, beside the INV-1 opt-down
search, is the cheap shape; nothing is written.

**2026-08-01 — INV-1's negative check can fire on a clean tree, and that costs
teeth its premise.** Unit 02. `gate-arch.sh:62` flags any `swiftLanguageMode(`
line not carrying `.v6)`. It catches the opt-down wrapped as well as inline —
measured, both forms give one finding — and by the same reading it reports a
legitimate `.swiftLanguageMode(` broken before its `.v6`.

A gate that fires on a clean tree is the inverse of what this repository checks
for, and it is how a gate dies: false positive, exception added, exception
widened, nobody reads it. No step in that sequence gets recorded as a defect.

The collision with the harness is direct. Every teeth case asserts the clean
tree exits 0 before it plants anything, so one legitimate wrapped declaration
fails teeth's own baseline. What goes then is the premise the harness rests on,
not a check.

What it takes to trigger was measured rather than assumed, and it is narrower
than it looks. `swift format` will not produce the form: given a 120-column
target declaration carrying `.swiftLanguageMode(.v6)`, the formatter breaks at
the argument level and leaves the setting inline at 99 columns, after which
`gate-arch` and `gate-format` both exit 0. The wrap has to be hand-written.

Latent either way — `Package.swift` declares no `swiftSettings` today, and
unit 02 brings per-target configuration. Disposition: open, and it is the one
finding here that points at a gate rather than at a plant. Changing `gate-arch`
is a ratification stop, and `scripts/gates/**` is ask-gated, so it stops on its
own.

**2026-08-01 — all twelve commits were rewritten to a noreply address.**
Unit 02, done ahead of unit 02's driving prompt and without a ratification stop.
It is the second time that session acted outside a ratified plan.

Every author and committer moved from the author's personal address to
`Ben Koo <61488202+sebkoo@users.noreply.github.com>`, with
`git filter-repo --mailmap`. The mailmap was built from measurement rather than
expectation: author and committer matched on all twelve, so one line covered it.
Trees and full messages are byte-identical to a pre-rewrite copy pair by pair,
and `HEAD^{tree}` is unchanged at `6924f2e`.

```
 1  f22c608fd984 -> 1a132dd123a5     7  2fbbbec47c09 -> 127e82969b58
 2  334438db506a -> b50b9c529bd2     8  d419ef392411 -> eba72cb92366
 3  0d1904c155c2 -> 158ef7085403     9  346ca4785975 -> fa2ccde50001
 4  f0bbd8042049 -> ddea49c43085    10  a5696ed83a5f -> b0f69b59e589
 5  9cd8696d5794 -> 77607a8072af    11  5ce894d50d7f -> 39ae1360106c
 6  c5daa842cd8c -> 7ddc8809aced    12  1c16da5cfacb -> baf697c62af4
```

**Measured 2026-08-01, and this table is not to be regenerated.** It records the
email rewrite and was correct when taken. A second rewrite, the host-path
redaction, moves the right-hand column again; overwriting these values with those
would falsify a measurement rather than update it. **Owed: a second table beside
this one, derived from `.git/filter-repo/commit-map` and labelled for the
host-path redaction.** Rows 1 to 9 are expected to be identity — filter-repo
reproduces a hash when tree, parents and metadata are unchanged, and the redacted
text first appears in Commit 10 — so only 10, 11 and 12 should move. More than
three rows moving means something other than the redaction changed, and is a stop
rather than a surprise.

**Discharged, 2026-08-01.** The second table, read from
`.git/filter-repo/commit-map`. Rows 1 to 9 are absent from the map entirely,
which is filter-repo reproducing a hash when nothing in the commit changed, so
they are shown as identity. Exactly three moved, as predicted.

```
 1  1a132dd123a5  identity      7  127e82969b58  identity
 2  b50b9c529bd2  identity      8  eba72cb92366  identity
 3  158ef7085403  identity      9  fa2ccde50001  identity
 4  ddea49c43085  identity     10  b0f69b59e589 -> b853d54d044c
 5  77607a8072af  identity     11  39ae1360106c -> 6ad1132543ac
 6  7ddc8809aced  identity     12  baf697c62af4 -> ce1756b1b1c2
```

The full chain across both rewrites, for a reader holding any one of the three
generations of hash:

```
Commit 10   a5696ed -> b0f69b5 -> b853d54
Commit 11   5ce894d -> 39ae136 -> 6ad1132
Commit 12   1c16da5 -> baf697c -> ce1756b
```

A second pass repaired the hash citations in
`docs/prompts/01-repository-and-harness.md` inside Commit 10, which left Commits
1 to 9 unmoved and moved 10 to 12 a second time. Eight occurrences across six
lines, not the five first counted. `4d663458` was reworded rather than
renumbered: it was Commit 2 before its amend, already unreachable, and the
rewrite expired it.

This reverses a decision taken earlier the same day, when rewriting was ruled out
because it invalidates those citations and because unit 01 had already decided
the same trade by exempting Commit 1 from INV-12 rather than amending the root.
That reasoning is not withdrawn. It stands at
`docs/prompts/01-repository-and-harness.md:1800` beside the note recording the
override, so both readings are legible together.

**What it does not achieve.** The push had already landed —
`git ls-remote origin` returned `1c16da5` — so the personal address was in
GitHub's storage. A force-push makes those commits unreachable; it does not
delete them. GitHub retains unreachable objects and serves them by SHA to anyone
with read access. The editorial note holds the original hashes, which are exactly
the retrieval key, so recording the provenance and handing out the lookup are the
same act here. The note is not weakened to hide it. Disposition: see Repository
visibility below.

Measured after the push rather than predicted, at roughly 11:40 on 2026-08-01:
`gh api repos/sebkoo/midkeep/commits` reports the old address 0 times across all
twelve, and
`gh api repos/sebkoo/midkeep/commits/1c16da5cfacb083980c08b4448229ff5ccaeb29c`
still returned that commit carrying the personal address. Unreachable, retained,
served on request.

The address is not quoted anywhere in this file, and that is deliberate rather
than incidental. An earlier draft of these three paragraphs spelled it out
while describing the rewrite that removed it — the same mistake as naming the
host path in the record of redacting the host path, and it would have published
the address for the first time, since the public repository has never carried
it. Caught by `blob.old_email` in pre-flight v2, on `wip/unit02` before
anything was pushed, so it cost a hand edit rather than a fourth rewrite.

**Owed before any feature code, beside the host-path gate: a check for personal
addresses in committed text.** Shape rather than string, for the same reason —
an address that is neither `@users.noreply.github.com`, nor `noreply@…`, nor at
a reserved domain.

The reserved-domain exclusion is matched as a **suffix**, not a prefix:
`.example`, `.invalid`, `.test`, `.localhost` and `example.com`. Written as
`example.*` it would miss
`docs/prompts/01-repository-and-harness.md:771`'s `sam@opencodex.example`, which
*ends* in `.example` rather than beginning with it, and the gate would go red on
its first run against a clean tree.

The exclusions are load-bearing rather than defensive. `.githooks/commit-msg`
carries a family list, and unit 01's document quotes `noreply@anthropic.com` and
several `@example.invalid` addresses as the evidence that its hook discriminates.
All of that must stay.

**Discharged, 2026-08-03.** `scripts/gates/gate-address.sh` landed with the
exclusions as specified, one of them sharpened by a probe: the reserved
domain is matched as `@example.com` or `.example.com`, never as a bare
`example.com` suffix, which would also excuse a name merely ending in
those letters — probed both ways, the subdomain excluded and the
lookalike firing. Measured at landing: the scope held twelve distinct
email-shaped tokens, every one excluded, and a fabricated gmail control
fired. The `.test` and `.localhost` suffixes have no coverage in the
tree's own text, so the plant's fixture is the one place they are watched
excluding something; the other four exclusion classes are re-measured by
the clean-tree half of the teeth case on every run.

**A third shape, closed by a rule rather than a gate.** A shell prompt carries
the account name and the hostname in one string, and this project's method is to
paste tool output verbatim into the notebook. Neither owed gate would catch it:
a prompt is not a `/Users/<name>/` path, and a hostname without a dot is not
email-shaped. Measured as preventive rather than remedial — the hostname token
appears in 0 files reachable from local branches today. `CLAUDE.md` § Working
agreements now says to quote the command and its output and never the prompt
line. A gate is worth adding only if a cheap shape presents itself; inventing a
fiddly one to close a gap a single sentence already closes is not.

That reading was correct when taken and is kept rather than deleted, because a
measurement carries a timestamp and not an erasure. It stopped holding at
`created_at=2026-08-01T11:46:44Z`, when the repository was deleted and recreated
under a new `id=1319248773`. The same call now returns
`No commit found for SHA`, and `git fetch origin <sha>` returns
`upload-pack: not our ref`, for every pre-rewrite hash tested — with the current
`baf697c` resolving as a control, so the test discriminates rather than failing
on everything.

**Discharged, 2026-08-01.** `baf697c` was Commit 12 of the email rewrite and
moved again to `ce1756b`. The paragraph above is a measurement and is kept as
written; the successor is appended rather than substituted. Re-run against the
third-generation repository, `ce1756b` resolves and returns the noreply address,
and all four of `b0f69b5`, `39ae136`, `baf697c` and `1c16da5` return
`No commit found for SHA`. Four failures and one control that resolves, so the
test still discriminates.

The severity claim attached to these SHAs elsewhere was wrong and is corrected
here rather than left standing. The repository was private from its first push
until it was deleted at `11:46:44`, and the repository that became public was a
fresh one holding no pre-rewrite objects. A public repository, a published SHA
and a reachable object were never true at the same moment. The committed hashes
at `docs/prompts/01-repository-and-harness.md:1792` and `:1813` are dead
references — a record defect owed a correction — and were never a live lookup
key.

**2026-08-01 — the workflows ran, and one parked measurement cannot be taken as
`gates.yml` stands.** Unit 02. The first push executed both workflows. `ci`
succeeded. `gates` failed, and the failure is the contract working: `actionlint`
is not present on a GitHub macOS runner, so `gate-workflow` returned 2, `all.sh`
returned 2, and the step failed.

The consequence is structural rather than incidental. A failing step ends the
job, so the Teeth step never ran — GitHub reports `Gates -> failure`,
`Teeth -> skipped`. `teeth.sh` has still executed on exactly one machine, and it
cannot execute in CI while `all.sh` returns 2 ahead of it. The workflow blocks
the measurement it was written to enable.

The other parked measurement was taken. Under a real `actions/checkout` with
`fetch-depth: 0`, pushing to the default branch, `gate-hygiene`'s first line
reads — quoted at its own length, because re-wrapping captured output is the
rendering-versus-artifact failure this repository already logged once:

```
gate-hygiene: INV-8 over HEAD, 12 commits (origin/main..HEAD resolved empty, fell back to all of HEAD)
```

That is the shape unit 01 recorded locally under Prediction 3, so the zero-count
fallback behaves in CI as it does here, and the half unit 01 left open is closed.
`gate-hygiene: core.hooksPath check skipped under CI` was also watched firing for
the first time in the only place it was written for.

Disposition: open. Installing `actionlint` in `gates.yml` would let both steps
run; so would ordering teeth ahead of `all.sh`, which trades one problem for
another. Either is a workflow change, and `.github/workflows/**` is ask-gated, so
it stops on its own.

**2026-08-01, later the same day.** `gates.yml` now installs actionlint
v1.7.12 — the version `gate-workflow` was verified against locally — pinned by
version and sha256 from the upstream release's checksum file, the hash watched
going both ways before pinning: the true value passes `shasum -c` and a
corrupted control fails it. A pinned checksummed binary was chosen over a
marketplace action or an unpinned installer because either of those is a
dependency in all but name, and the install touches only the runner's `PATH`,
so `gate-workflow`'s contract is unchanged — a clone without actionlint still
gets 2 with the reason on stderr.

Predictions, written before the run they predict. `gate-workflow` no longer
returns 2 and reports 0 findings modulo shellcheck — actionlint 1.7.12 run by
hand over the post-edit pair of workflows exits 0 on a machine without
shellcheck integration, and whether the runner has shellcheck decides how much
that 0 covers. `all.sh` returns 0 if that holds, the first green Gates step on
CI. Teeth then runs for the first time on a cold runner, and that is the
parked measurement: nine cases, macos-15, from-scratch compiles, the same
compile scope as local. Its total wall time gets recorded beside the 42.249
local figure as a new baseline under new conditions, not a comparison.

**Measured, 2026-08-01, run 30724101184 — the run triggered by the push
carrying those predictions.** All hold, one by its modulo clause and one with
a surprise. The install verified the pinned hash on the runner —
`/Users/runner/work/_temp/actionlint.tar.gz: OK` — and the `--version`
tripwire printed 1.7.12 for darwin/arm64. `gate-workflow` reported
`shell blocks NOT checked (no shellcheck)`: the runner has no shellcheck, so
the modulo clause was load-bearing and the green covers the workflow schema
and not the `run:` blocks. The Gates step passed — the first green on CI —
and Teeth ran all nine cases: `plant cases 8, contract cases 1, failures 0`.

Teeth's wall time by step timestamps was 30 seconds, 23:50:54 to 23:51:24
UTC. The new baseline is faster than the 42.249 local figure, not slower as
the cold-runner reasoning expected; the two build plants dominate on the
runner as they do locally, plant-warning at about 17 of the 30 seconds and
plant-skipped-test about 11. The numbers are two baselines under two
conditions, and the surprise is recorded rather than explained — nothing
here was measured about why.

One prediction landed differently than worded. `gate-hygiene` on the runner
read `INV-8 over HEAD, 16 commits (origin/main..HEAD resolved empty, fell
back to all of HEAD)` — on a push to main the checkout's `origin/main`
equals `HEAD`, so the range resolves empty regardless of how many commits
the push carried. The `2 commits` reading happened exactly once, locally,
before the push, where it was measured at gate-hygiene exit 0.

**2026-08-01 — INV-13 added: no paid GitHub usage, and the tree does not meet
it.** Unit 02. The invariant is that no workflow carries a `push:` trigger and
that `runs-on: macos-*` appears only in a job needing a Swift or SwiftUI build.
Both workflows currently carry `push: branches: [main]`, so the first clause is
violated as the tree stands. The second holds: `macos-15` appears in `ci.yml`'s
build job and `gates.yml`'s gates job, both of which build, and `gates.yml`'s
`pull-request-body` job is on `ubuntu-latest`.

Two facts read from GitHub's own pages on 2026-08-01 rather than recalled:

> GitHub Actions usage is **free** for **self-hosted runners**

> free for **public repositories** that use standard GitHub-hosted runners

Neither applies here yet. `gh repo view --json visibility` reports `PRIVATE`,
and the runners are GitHub-hosted.

**What could not be verified, recorded as a question rather than an
assumption.** The default spending limit on this account is not stated on the
billing pages read, and the behaviour when included minutes are exhausted is
given only for one case — "If your account does not have a valid payment method
on file, usage is blocked once you use up your quota" — which leaves the
account-with-a-payment-method case unanswered. Whoever opens the billing page
should answer both and record what it said, with the date.

Usage so far is not readable from here either, and the reading is worth keeping
because it looks like an answer and is not one.
`repos/sebkoo/midkeep/actions/runs/<id>/timing` returns `billable` populated with
`MACOS` and `UBUNTU` entries whose `total_ms` is 0, against `run_duration_ms` of
31000 and 50000. The field is present rather than missing, so the 0 is what the
API says; what it means for included minutes cannot be determined from that
endpoint.

Disposition: open, and it is a ratification stop twice over. `gate-workflow`
gains the two assertions and `.github/workflows/**` loses the `push:` triggers;
both paths are ask-gated. When the gate goes red on the workflows, the workflows
change and the gate does not.

**2026-08-02 — overtaken in part by amendment.** The clause banning `push:`
triggers was replaced; push triggers stay. This entry is kept as the record
of the invariant as first written and of the conditions it was right under.
The amendment, its grounds and its revisit trigger are the 2026-08-02 entry
below. What stays open from this disposition is enforcement: `gate-workflow`
still asserts neither clause.

**2026-08-01 — INV-12's Commit 1 exemption outlived the reason given for it.**
Unit 02. `CLAUDE.md` justified the exemption by saying that amending the root
would rewrite the hashes of every commit after it, and that those hashes are
cited across `docs/prompts/01-repository-and-harness.md`. Unit 02 rewrote all
twelve commits for the author address and repaired the eight citations in a
second pass, so that reason is no longer true. It was falsified by action rather
than by argument.

The exemption stands, on what it actually rests on: Commit 1 predates INV-12,
which was adopted during Commit 2's amend. Its two over-72 lines, at 73 and 75
columns, are the only artifact in the tree recording that the rule arrived
mid-unit, and the `inv12.root.exempted` tripwire keeps them by expecting 2 rather
than 0 across the whole history.

Recorded rather than swapped in silently, because a conclusion that survives its
stated premise is worth an entry. Without one, the next reader finds a rule
resting on an argument this repository disproved and has no way to tell that the
rule was never resting on it.

Disposition: `CLAUDE.md` INV-12 now carries the reason the exemption depends on.
The prompt document is not edited again for this, and it is closed by search
rather than by edit.

The superseded wording survives in two places in
`docs/prompts/01-repository-and-harness.md`, both reachable by grepping
`hashes of Commits 2 and 3`:

```
:1802  amending it rewrites the hashes of Commits 2 and 3, and `1a132dd`, `b50b9c5` and `158ef70` are
:1852  # it would rewrite the hashes of Commits 2 and 3, which are cited across this
:1853  # document. Expecting 2 means "the exemption is intact". If this goes red,
```

The second is the one that matters. It sits inside an `sh` block three lines
above `chk inv12.root.exempted` at `:1855`, so a later session copying the
tripwire copies its comment, and the false reason enters the tree as code.

Leaving both unedited was argued at first on reading order — `:1852` sits below
the unit-02 editorial note at `:1807`. That argument does not hold: nobody reads
1,900 lines linearly, they grep and jump to a line number, and a reader landing
at `:1852` never passes `:1807`. Closing it by search removes the dependency on
reading order entirely.

The never-edit rule keeps its single exception. `:1800` earned one by becoming
self-contradictory — arguing against a rewrite while displaying post-rewrite
hashes. `:1852` is merely wrong, which is a lower bar, and the distance between
the two is worth preserving rather than spending.

**2026-08-01 — two checks reported what they had not measured, and one measured
the wrong moment.** Unit 02, during the delete-and-recreate.

`git grep -oE '\b(f22c608|334438db|…)\b' HEAD` returned nothing and was read as
absence. This `git grep` does not support `\b` in ERE — the control `\bDate\b`
returns 0 where the fixed string `Date` returns a hit — so the pattern could not
match and the empty result was consistent with the check being broken. It was.
Re-measured with `grep -F`, the committed document names five pre-rewrite hashes
at `:1792` and `:1813`. The cost is not that the search failed: the empty result
was used to retract a claim that was correct, so a broken check manufactured a
finding of absence that was then acted on.

`chk meta.captured 0 "$rc"` asserted that `gh api repos/sebkoo/midkeep` exits 0.
A freshly created repository satisfies that with a null description and no
topics, so the check passed while capturing nothing worth having. Asserting on
exit status where the subject is content is the shape unit 01 recorded as
`probe.D.exit1` — a name claiming more than its pattern.

The same pre-flight asserted its own ordering in a comment, "backups, before
anything destructive", rather than in a check. It ran after the repository had
been deleted and recreated and nothing in it noticed. The `created_at` reading
that settles the question belonged at line one as a guard, not in a follow-up
block.

**What that ordering cost.** The About string and seven topics existed on the
first repository and were destroyed with it. `midkeep-repo-meta.json` was written
after the recreation, so it holds the new repository's empty metadata and cannot
restore them. Repository metadata lives in exactly one place, outside the tree,
and a delete destroys it. Where it should live instead is a decision for unit 02.

**The replacement string, written down here rather than as an instruction to
write one.** An earlier version of this entry said the About string "has to be
reconstructed from `README.md`", which records a task and not an answer, so the
next delete would have had nothing to read:

```
Unfinished work as first-class data — a Swift 6 iOS project built harness-first:
gates, invariants and a teeth harness before any feature code.
```

Provenance, split because the halves differ. The first clause is `README.md:14-15`
in its own words and is a reconstruction. The second clause is **newly written**
and observed from the tree rather than recovered: `Package.swift` declares
`swift-tools-version:6.0` and `platforms: [.iOS(.v17), .macOS(.v14)]`,
`scripts/gates/` holds six gates and eight plants, `CLAUDE.md` carries thirteen
invariants, and `Sources/` holds three placeholders and no feature code. Calling
the whole string a reconstruction would be false.

It is 143 characters and 145 bytes in UTF-8, against GitHub's 350-character
limit. Both numbers are given because they differ: the em dash is three bytes,
and `wc -c` reports 146 by counting the file's trailing newline as well. A length
in the record should say which of the three it is, for the same reason a
`git grep -c` count has to say whether it counted lines or occurrences.

One word carries a load worth naming: **iOS** is a declared deployment target,
not a shipped surface. Nothing runs on a device, which `README.md` says plainly
and ADR-0004 records as never compiled for iOS anywhere in unit 01.

The seven topics, recorded for the same reason:

```
swift  swiftui  ios  swift6  swift-concurrency  swift-package-manager  spm
```

**2026-08-03 — the deferred topics, recovered to the tree.** The seven
live topics above were committed here; the thirteen deferred ones
existed only in the unit-01 session's closing hand-off — the same
outside-the-tree carry that lost the About string once, surfaced by an
owner's question. Recovered from that transcript verbatim, each with
the capability that makes it true:

```
state-machine       run engine (a static schemaVersion is not one)
resumable           journal + resume-after-kill test
offline-first       journal storage; no storage or network path today
workflow-engine     run engine
durable-execution   journal + resume-after-kill test
sqlite              journal storage
background-tasks    background continuation of a run
streaming           streaming contract
sse                 only if SSE is the transport that ships
on-device-ml        local-versus-server routing
coreml              first Core ML path
tensorflow-lite     second engine behind the same contract
feature-flags       remote-config-backed flag service
```

The release rule, stated by the owner with the recovery: a topic is
added when the capability it names lands, never before — topics follow
artifacts the way badges follow checks. Three of the thirteen —
on-device-ml, coreml, tensorflow-lite — assume on-device execution,
which the whose-server question (ADR-0007's open questions, the
deferred ADR-0008) has not decided; the rule already covers them, since
a capability that never lands releases no topic, and the assumption is
named so a later reader knows the three may expire rather than land.

**The three bundles and what each is for**, because a bundle whose purpose is
unwritten is a file nobody dares delete and nobody dares use. All three sit in
`$HOME` and none is committed.

**All three carry the unredacted host path**, and an earlier version of this
paragraph said only `~/midkeep-pre-public.bundle` did. That was false when
written and is falsified by a command already run: `git bundle list-heads` on
each shows `baf697c` — a pre-redaction commit — in all three, reaching
`post-e2` through `refs/remotes/origin/HEAD` and `refs/remotes/origin/main`,
because `git bundle create --all` sweeps remote-tracking refs and not only
branches.

This is a **disposal** defect rather than a security one. All three files are
local and none was ever pushed. But someone acting on the old sentence would
delete `pre-public` believing the last copy destroyed and be wrong, or keep it
and delete the other two believing them harmless and be wrong the other way.

The claims that survive are narrower and true. `~/midkeep-pre-e2.bundle` is the
only copy of snapshot `766d982`. `~/midkeep-post-e2.bundle` is the only copy of
snapshot `b02efdc`, which matters because the snapshot branch was deleted at E5
and `filter-repo --force` expired the reflog during E2, so there is no local
recovery path left.

Making `pre-public` the sole carrier is possible —
`git bundle create --branches` rather than `--all` would exclude the
remote-tracking refs — and was not done. With the reflog gone, holding the
pre-redaction state in more than one place is an advantage; it only had to be
stated accurately.

**2026-08-01 — INV-12 said columns and its checks count bytes; measured,
nothing sits between them.** Unit 02. A first measurement answered the wrong
question — 912 counted every line in every file against 82, mixing code, JSON
and URLs into one number. Redone, split by what each threshold governs:

```
A  INV-12, commit bodies over 72, all fourteen commits
     1a132dd            bytes=2  chars=2   the root commit, the recorded
                                           exemption
     the other thirteen 0 / 0

B  prose surface over 82
     README.md 9/9   ROADMAP.md 4/4   adr/0004 2/2   adr/0007 1/1
     adr/README 7/7  docs/prompts/01-… 842/842
     totals  bytes 865   chars 865

C  longest single line   bytes 379   chars 379
```

Each cell counts lines over the threshold, in bytes and in characters, at
the tree as it stood when measured; this file has since grown by the entry
recording it.

Bytes and characters disagree nowhere — not on one commit body, not on one
markdown file, at either threshold. The wording defect is real and has zero
measurable consequence in today's tree.

The fix is the wording, not the checks. In UTF-8 bytes are never fewer than
characters, so a line passing a byte limit always passes the same character
limit — a byte limit is strictly the more conservative reading and can never
admit something a character limit would reject. INV-12 now says bytes. No
enforcement changed, no verdict changed anywhere in fourteen commits, no
ratification stop.

The line rewrapped during this review measured 73 bytes and 71 characters, so
it passed both limits before the rewrap. The rewrap was harmless and it was
not the fix; the fix is the wording.

**The condition for revisiting, stated so the decision is not re-litigated.**
The three measures — bytes, characters, display columns — coincide today only
because the tree contains no wide characters. The first line of Hangul or CJK
breaks the coincidence: 82 bytes is roughly 27 Hangul characters and about 54
display columns, far stricter than any of the three readings intends. The
session that produced this entry was conducted in Korean, so a quoted line
entering the record is a live possibility rather than a hypothetical. Trigger:
the first substantially non-ASCII line in the tree.

**2026-08-02 — INV-13's first clause replaced by amendment; the motive and
the second clause stand.** Ratified by the owner. Dates in this entry are
UTC — the amendment landed at 2026-08-02 UTC while the host still read
2026-08-01 EDT, and a bare date here would pick a timezone silently.

What changed: the clause banning `push:` triggers is replaced by one
requiring every `runs-on` in every workflow to name a standard
GitHub-hosted runner label — the set that is free on a public repository —
never a large-runner or custom label. What did not change: the motive, no
paid GitHub usage, stated first as before; and clause 2, `macos-*` only in
a job that needs a Swift or SwiftUI build. Push triggers stay.

Why, on two measurements already in this file and nothing new: the
repository is public — generation 3, `created_at 2026-08-01T13:28:48Z`,
`id 1319316813` — and GitHub's page, quoted in the entry that added
INV-13, says Actions is free for public repositories on standard hosted
runners. And the Actions timing API read `billable.MACOS.total_ms` of 0
against non-zero `run_duration_ms` across 2026-08-01's runs.

The history, kept because the replaced clause was right when written.
Under a private repository — which this was when INV-13 was added —
`macos-*` jobs on push triggers were the one configuration that could
bill. The facts the clause was written against died at 13:28:48Z the same
day, when the repository went public. Overtaken, not refuted: dated and
kept, not erased.

The revisit trigger, the same shape as INV-12's wide-character trigger and
the exemption's return condition: the amendment holds only while the
repository is public. If visibility ever flips to private, push triggers
become a paid path again and INV-13 is owed a revisit. Stated honestly:
visibility is not readable from the tree, so no tree-gate can assert it. A
workflow can read it at run time — `github.event.repository.private` is
available on the runner — so a one-line tripwire step in `gates.yml`,
failing loudly if it is ever true, puts the machine check exactly where
the money would be spent: the run that would bill is the run that notices.
Cost if it ever fires: one run against the private tier's free allowance.
Taken; it lands with the enforcement commits rather than in this
amendment, which is docs only, and until it lands this paragraph describes
a design and not a file.

**Discharged, 2026-08-02 (UTC), stronger than drafted in two ways.** The
step as landed demands affirmative proof of public — anything but a
measured `"false"` fails the run, because `github.event.repository` can be
absent on event types these files might gain later, and an empty
interpolation would make a `== "true"` check pass silently on exactly the
run that would bill: the meta.captured defect, a check with a path on
which it cannot fail. And it guards every job that spins a runner, not
`gates.yml` alone — the `gates` job, `ci.yml`'s `build` job, which would
bill identically when private, and the `pull-request-body` job, whose 1x
ubuntu tier is cheaper when private, not free. The shell logic was watched
three ways before landing: `false` exits 0, `true` exits 1, and empty
exits 1 reporting `unreadable`. The interpolation itself is only testable
by a run; predicted, before the next push: all three copies pass, each
printing the repository-is-public line.

**Measured, 2026-08-02, runs 30727083627 (`gates`) and 30727083599 (`ci`) —
the push carrying the tripwire.** Confirmed for every copy the event could
reach, and the prediction overreached by one. Both executed copies passed
and printed `INV-13: repository is public; the amendment's condition holds`,
and the log's rendered script header reads `vis="false"` — the interpolation
resolving to a measured `"false"` on the runner, not an inference. The third
copy never ran: `pull-request-body` carries `if: github.event_name ==
'pull_request'`, so a push cannot exercise it, and "all three copies" was
unmeasurable by the run the prediction named. Falsified in the letter,
confirmed in what it meant; the third copy's live measurement waits for the
first pull request.

An amendment moves no mark — the INV-2/INV-3/INV-7 rule. INV-13 stays
PARTIAL, and moves when `gate-workflow` asserts both clauses and teeth
proves them going both ways.

**2026-08-03 — INV-13's readable clauses gain their gate; a review returned
five findings and every fix landed against a measurement.** `gate-runners.sh`
is the seventh gate: clause 1, every `runs-on` on an allowlist of the
standard hosted labels the tree uses — `macos-15` and `ubuntu-latest`, each
entry dated in the gate — and clause 2, `macos-*` only beside the literal
marker `# INV-13: needs a Swift build`. It is a grep over
`.github/workflows/` and needs only a checkout. The entry above named
`gate-workflow` as the mark's destination; the check landed as its own gate
instead, because `gate-workflow`'s tool is `actionlint`, which is optional,
and coupling the clauses to it would leave a fresh clone with no INV-13
verdict at all. Overtaken by a better shape, not refuted. Two plants land
with it, the ninth and tenth: `plant-runner-label.sh` for clause 1,
`plant-macos-no-marker.sh` for clause 2.

A multi-agent review of the diff refused ratification with five findings,
all verified — one by two adversarial refuters, four by direct measurement
after a usage limit stopped the refuter fleet. The aggregation first misfiled
those four as refuted on empty verdicts: absence read as a verdict, in the
reviewer's own tooling, the same defect class this file records elsewhere.
Kept because the reviewer is part of the measurement chain and its failures
are findings like any other.

The five, each with the measurement that decided it:

1. Flow-style YAML defeated both clauses: `{runs-on: macos-latest-xlarge,
   steps: [...]}` measured exit 0 against the anchored scan, and GitHub
   honours flow mappings. Fixed by unanchoring the key match; the flow form
   now reaches the label ladder with the rest of the mapping attached and
   fails the allowlist as junk — the conservative direction. The cost, a
   commented `# runs-on:` line read as a real one, is named in the gate's
   header beside the `run:`-block false positive. Four flow fixtures joined
   the probe battery — whole-job, jobs-level, mixed-realistic, and
   flow-style `macos-15` without its marker — and each measured exit 1.

2. The clause-1 plant proved nothing about the clause it names. Measured
   both ways: with the allowlist deleted from the gate, the plant's
   `macos-latest-xlarge` fixture still exited 1, because the marker clause
   fired at the same path and the teeth case counts findings by path; with
   the fixture relabelled `ubuntu-latest-xlarge` — a label clause 2 cannot
   see — the mutant exits 0 and the teeth case fails. The plant now carries
   the ubuntu label, and the mutation was re-run by hand after the fix,
   2026-08-03: allowlist deleted, `ubuntu-latest-xlarge` → exit 0, no
   finding, mutant caught; `macos-latest-xlarge` against the same mutant →
   exit 1, one finding at the same path, the shape that had made the plant
   blind.

3. An unreadable workflow file measured exit 0 — `grep: Permission denied`
   on stderr and a clean verdict the tool never earned. Under pipefail
   `scan_file`'s status is grep's, and grep's 1 is a legitimate no-match,
   so the fix discriminates: status above 1 is `die_cannot_run`. Probed
   both ways: a chmod-000 workflow → 2, a runs-on-free workflow → 0.

4. The plants' main-tree guard degraded silently on old git. The second
   `rev-parse` never checked its status, and rev-parse hands an option it
   does not recognise back on stdout with status 0 — measured:
   `git rev-parse --frobnicate-nonsense` prints it and exits 0 — so on a
   git without `--path-format` the two answers could never be equal and the
   guard waved the main tree through. Both calls in both plants now check
   status and require an absolute-path answer; any other shape refuses.

5. Zero workflow files measured exit 0 — the meta.captured shape, a clean
   verdict over an empty scan. One line closes it: zero files scanned is
   `die_cannot_run`. Probed: an empty workflows directory → 2.

The battery after the fixes, counted as probes: fifteen — the four flow
fixtures, both clauses block-style, an expression, a sequence, an empty
value, a quoted-and-markered clean case, a runs-on-free file, the
commented-line false positive, the unreadable file, the empty directory,
and the real tree's two workflows as the clean control — fifteen ok, zero
failures. `all.sh` exited 0 over seven gates on the real tree. Teeth ran
ten plant cases and the contract case with `failures 0`, in a scratch copy
whose HEAD carried the working tree, because a teeth worktree holds only
committed content — the same boundary the `status.sh` paragraph in Known
holes records — and an uncommitted gate is invisible to it.

Enforcement moved, so the mark moves — the same rule that held it still
through two amendments. INV-13 now reads (`gate-runners`, PARTIAL): PARTIAL
for the unreadable half, the spending limit and the visibility condition,
which no tree-gate will ever assert, and for what a gate with no YAML
parser cannot see — a reusable workflow's runner is chosen in the called
file, and the false positives are named in the gate's header.

**Measured, 2026-08-03 (UTC), runs 30862749381 (`gates`) and 30862749377
(`ci`) — the push carrying the gate.** Both green. The gates run printed
`gate-runners: INV-13 over 2 workflow files` and `gate-runners   0`, then
`all.sh: 0 — every gate ran and found nothing`, and teeth closed
`plant cases 10, contract cases 1, failures 0` — the first eleven-case
teeth run (ten plant, one contract) on a hosted runner, 28 seconds from
its first log line to its summary line by step timestamps, beside the
nine-case 30 of run 30724101184 as a baseline under its own conditions.
The series stands on one basis, plants plus the contract case: 42.249
seconds for nine cases local, 30 for nine on a runner, 28 for eleven on a
runner — each under its own conditions, no cause claimed for the
direction. The visibility tripwire printed
`INV-13: repository is public; the amendment's condition holds` again, and
`pull-request-body` skipped as before — its copy still waits for the first
pull request.

The badge rule, adopted with the README's two live workflow badges: a
badge is either derived live by a machine or a claim linking to its
committed evidence. Anything else is prose in a costume — the README's
status block sat at gates 6 and plants 8 against a tree carrying seven
and ten, which is what happens to numbers a machine derives only when
someone remembers to ask.

**2026-08-03 — the two prose gates land born enforced; ratified on an
independent adversarial pass.** `gate-hostpath.sh` (INV-14) and
`gate-address.sh` (INV-15), each with its plant and its invariant row in
one commit — the first rows for which rule and check have no gap between
their arrivals. The design was already in this file; the discharge
paragraphs beside each owed marker carry what sharpened in the landing.
Both gates enumerate committed text with
`git ls-files -co --exclude-standard`, scan the named prose surface, and
never print what they matched.

The author's battery, counted as probes: twenty across the two gates,
zero failures — must-fire, must-not-fire, no-verdict and blind-spot
cases, each direction watched. `all.sh` exited 0 over nine gates on the
real tree; teeth ran twelve plant cases and the contract case with
`failures 0`, in a scratch copy whose HEAD carried the working tree, the
same rig the INV-13 landing used.

The review ran thirteen probes and five mutants against the operative
code in an independent clone. The real tree read 0 findings over 15 and
16 files; every dangerous shape fired; an `example.com` subdomain and a
bare `@localhost` were exactly quiet. All five mutants were caught:
plus-to-star, the carve-out deleted, the exclusions deleted, and
always-clean twice — the exclusion deletion caught by the clean-tree
half of the teeth case, which is the mechanism the plant's own header
claims. All seven draft decisions were ratified, including reading the
old "carries the real path as a literal" sentence as real-shaped rather
than the redacted string, and the single commit, because the verified
tree is the one with both gates and a split manufactures a tree nobody
ran.

The review's one addition, landed in the same commit: a doubled slash —
`/Users//alice` — yields zero findings, because the class demands a
segment character immediately after the slash. Re-measured here before
recording: 0 matching lines. The gate's header names it beside the
wrapped-line hole, the same family on the same grounds.

An incident during verification, kept because the first reading was
wrong. A zero-byte `.git/index.lock` in the checkout rode a copy into
the teeth rig, the rig's scratch commit silently failed, and two plant
cases reported exit 127 — worktrees missing uncommitted gates, not gate
verdicts. The stale lock was removed per git's own remedy and the rig
rebuilt clean. The draft blamed the editor's git integration as the
likeliest origin; the review established it instead: the reviewer's own
device-bridge git reads, which cannot unlink the lock they create — a
relay hazard on the reviewer's record, not this tree's. The editor was
not the cause and the suspicion is withdrawn.

**Measured, 2026-08-04 (UTC), runs 30871618701 (`gates`) and 30871618710
(`ci`) — the push carrying the pair, while the host still read
2026-08-03.** Both green: the first CI run with nine gates and thirteen
teeth cases. The gates run printed `gate-hostpath: INV-14 over 15 files
in scope` and `gate-address: INV-15 over 16 files in scope`, each
followed by its 0 — the same scanned counts as the local landing — then
`all.sh: 0 — every gate ran and found nothing`, and teeth closed
`plant cases 12, contract cases 1, failures 0`. Teeth wall time, from
its first log line to its summary line by step timestamps: 26 seconds
for thirteen cases. The series on its one basis, plants plus the
contract case, each figure under its own conditions with no cause
claimed for the direction: 42.249 seconds for nine cases local, 30 for
nine on a runner, 28 for eleven, 26 for thirteen. The visibility
tripwire printed its public line again. This measurement closes unit
02's harness arc: every invariant whose readable half can be gated now
is, and the record of proving it is this entry and the two above.

**2026-08-03 — two schemes shared the word "unit", and the README stated
progress that was false as measured; observed by the owner, reading.**
The ladder's row "02 app shell — in progress" sat above a tree holding
zero feature code: `Sources/` is three `Placeholder.swift` files and no
Xcode project exists. The work actually in progress was harness — filed
by the ladder under row 01, marked landed — and the driving-unit
scheme's own 02 is that harness arc, closed by the entry above. So "02"
named app shell in one scheme and a harness session in the other, and
the false row is what the collision cost. The ladder had declared
itself hand-written and able to go stale without anything noticing;
this is that clause paying out, the badge entry's decay mode in its
prose form, caught by an owner's read rather than a check — which is
what INV-11's UNENFORCED mark has always meant in practice.

The fix, in the commit carrying this entry. The ladder now names the
two schemes apart and maps each row to its driving units in a last
column; `scripts/status.sh` derives the commit span of every filed
driving-unit record into the generated block — endpoints and count are
of commits touching the record file, the basis named in the block
itself because it is not the unit's whole work, which no derivation
can recover from git alone; and "in progress" is replaced by a
statement measurable against the tree: row 02 reads "not started — no
Xcode project exists". Unit 02's own record is still unfiled in
`docs/prompts/`; until it lands, its arc is prose in this file, the
block shows no span for it, and the ladder's row 01 says "record not
filed yet" rather than borrowing unit 01's.

**2026-08-03 — the collision survived its first repair twice; the
numerals leave the ladder.** Unit 03's opening commit. The first repair
(`5e8775e`, the entry above) had a structural half — the Driven-by
column and the derived spans — and an explanatory half, the paragraph
naming the two schemes apart. Three events now stand, all 2026-08-03 by
the host clock, all observed by the owner reading rather than by any
check:

1. The false row: "02 app shell — in progress" above a tree holding no
   Xcode project — the entry above, repaired by `5e8775e`.
2. After that repair landed: the owner read "01 landed / 02 not
   started" and asked why unit 2 never started. The number collision
   survived the Driven-by column.
3. With the explanatory paragraph on screen: the owner pointed at the
   table itself — column 1 headed "Unit" while column 4 reads "units 01
   and 02". One word, two namespaces, in one table.

The explanatory half is twice overtaken: both later events happened
with the explanation present. An explanation the reader must hold while
reading is not a repair — it is a dependency on reading order, the
shape the INV-12 exemption's closure already refused to rely on. The
repair in the commit carrying this entry removes the namespace instead
of explaining it: the ladder rows lose their numerals and stand on
their names, the first column is renamed "Capability", the word unit
appears in exactly one column — Driven by, whose numerals are anchored
by `docs/prompts/` filenames — and Next units below becomes Next
capabilities with its enumeration dropped, so the collision dies rather
than migrates.

The same commit regenerates the status block and measures the
prediction the first repair filed — that the block would show landed
units 2 and unit 02's record span. Confirmed in what it meant,
falsified in the letter. Unit 02's span appears, and the count reads 3,
not 2, because this commit also begins the convention of filing a
unit's driving prompt before its work: `docs/prompts/03-app-shell.md`
is counted the moment it exists, and `status.sh` counts record files,
not closed units. "Landed units" is false as worded over that count —
unit 03 has only opened — so the label now reads "unit records filed",
naming what the number counts. Two smaller facts ride along. The block
sat one commit stale between `286d55b`, which filed unit 02's record
without regenerating, and here — the badge entry's decay family, in the
generated block that rule was written about. And the block's footer now
carries the disposition the 2026-08-01 generated-block entry offered
and left open: it states that the block is generated before the commit
that carries it and describes that commit's parent, which is also why a
record filed in the same commit shows "file not committed yet" as its
span.

**Measured, 2026-08-04 (UTC), runs 30873597996 (`gates`) and
30873597904 (`ci`) — the push carrying `e9d923e`, while the host still
read 2026-08-03. The session's own push was declined at the permission
layer and the owner pushed by hand: the ask list working as the
ratification mechanism unit 03's prompt names it.** Both green. The
gates run printed `gate-hostpath: INV-14 over 17 files in scope` and
`gate-address: INV-15 over 18 files in scope` — two more each than the
prose gates' landing run, and the delta is exactly the two
`docs/prompts/` files filed since: unit 02's record and unit 03's
prompt. Then `all.sh: 0 — every gate ran and found nothing`, and teeth
closed `plant cases 12, contract cases 1, failures 0` — 34 seconds for
thirteen cases, first log line to summary line by step timestamps. The
series on its one basis, each figure under its own conditions with no
cause claimed for any direction: 42.249 seconds for nine cases local,
30 for nine on a runner, 28 for eleven, 26 for thirteen, 34 for
thirteen. The visibility tripwire printed its public line;
`pull-request-body` still waits for the first pull request. This run
discharges acceptance item 1 of unit 03's prompt, with the prediction's
split between letter and meaning recorded above.

**2026-08-03 — a fourth reader question refines the Driven-by cell.**
Unit 03, decided by the owner as a refinement rather than a repair, and
ridden into the next docs commit rather than taking one of its own.
Effort in flight was invisible: with the app-shell row reading "not
started" beside a bare "unit 03", nothing in the table said work was
under way. The cell now reads "unit 03, open", the word read from the
record file's own Status section in `docs/prompts/` — so the mark has a
file behind it, and an unmeasurable status stays out of the Status
column, which keeps the claim the first repair paid for. The mark is
maintained by the same hand that maintains the row words; when a unit's
record closes, the mark goes with it.

**2026-08-04 (UTC) — unit 03's five decisions ratified and the app target
lands born-enforced, in one commit.** The host read 2026-08-03 for most of
the work. The decision brief was delivered in-session and ruled on per
decision: all five ratified, two handbacks taken — the INV-3 amendment
reworded to permission form ("nothing in the package imports `MidkeepApp`;
only the app-shell layer may"), so the rule is true of a tree whether or
not the shim exists; and sequencing, where of the two admissible shapes
the one-commit form was chosen: both new gate clauses' subjects — `App/`
and the pbxproj — exist in the only tree the harness verified, the
INV-14/15 argument, and no commit boundary ever holds a clause scanning a
file the tree does not carry.

The generator probes, taken in a scratchpad project before the brief. A
hand-written pbxproj at `objectVersion 77` with one
`PBXFileSystemSynchronizedRootGroup` parses — `xcodebuild -list` reports
the target and an auto-generated scheme — at 150 lines for the probe; the
committed project is 196. Adding a source file left the probe's pbxproj
byte-identical by `diff`, which is the measurement that removed the
generator's reason to exist and decided against xcodegen (present on this
host) and tuist (absent): a dependency purchased for churn that no longer
occurs. A warning planted in the added file failed the build — one
measurement proving both that the synchronized folder compiles what is on
disk and that `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` promotes Swift
diagnostics to errors. The boundary it does not cover, found by the
probe's first run: a build-system warning (traditional headermap) built at
exit 0 under the same setting; `ALWAYS_SEARCH_USER_PATHS = NO` silences
that one, measured. And the probe built for the simulator with
`CODE_SIGNING_ALLOWED=NO` — a simulator build needs no signing, as a run
rather than a doctrine.

The target as landed, measured on this host, Xcode 26.6 (17F113):
`xcodebuild build` for the generic simulator destination printed zero
`warning:` or `error:` lines and `BUILD SUCCEEDED`; the app installed and
launched on an iPhone 16 Pro simulator, iOS 18.0 runtime against the
`.v17` deployment target — no iOS 17 runtime is installed here, the
2026-08-01 finding — and rendered the honest screen, captured as a
screenshot. The three lines and their derivations: "midkeep", the bundle
display name; "No journal yet. No runs yet.", from
`Sources/MidkeepKit/Placeholder.swift` naming the journal as future and
`Sources/` holding no run type; "This screen is the whole app.", true by
construction and self-enforcing — the diff adding a second screen must
remove it. No gate reads screen text: that removal is enforced by diff
review, by convention, stated INV-11 style rather than implied.

The harness delta, each direction watched. `gate-arch` grew the `App/`
import allowlist (`SwiftUI|MidkeepApp`) and the app-project clause —
`SWIFT_VERSION` 6 and `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES`, presence
and value both ways, with a missing project a finding rather than a skip.
Probed against a clean control (0 findings) and five mutants: a UIKit
import in `App/` → 1, `SWIFT_VERSION = 5.0` → 3, the
warnings-as-errors lines deleted → 1, switched to `NO` → 3, the project
deleted → 1 — the 3s are the presence and value checks overlapping, the
conservative direction. Two plants landed in the same commit,
`plant-app-import` and `plant-project-settings`, the latter planting the
deletion the ruling named load-bearing. In a scratch copy whose HEAD
carried the working tree — the rig the INV-13 and prose-gate landings
used — teeth closed `plant cases 14, contract cases 1, failures 0`, and
`all.sh` exited 0 over nine gates.

The boundary that stays open, named rather than implied: `gate-hygiene`
and `gate-format` scan `Sources/` and `Tests/`, so INV-2, INV-4 and the
format rule are unenforced in `App/`. The shim is a handful of lines
partly for that reason; Known holes carries it.

Predictions, filed before the push that carries this entry. Both
workflows green. The `ci` run's new step prints the runner's
`xcodebuild -version` — recorded as the first CI app-build toolchain,
value unknown until measured — and the step's duration joins the record
as a new baseline under its own conditions. The gates run prints
fourteen plant cases, `plant cases 14, contract cases 1, failures 0`,
and its teeth wall time joins the series on the stated basis. The prose
gates' counts stay 17 and 18 — this commit adds no prose file, and
neither `App/` nor the pbxproj is in their scope. The visibility
tripwire prints its public line; `pull-request-body` still waits for the
first pull request.

**Measured, 2026-08-04 (UTC), runs 30877538830 (`gates`) and 30877538825
(`ci`) — the push carrying `56621c4`, pushed by the owner.** Every
prediction held, and the two unknowns are now values. The runner's app
build toolchain: Xcode 16.4 (16F6), printed by the step itself — against
Xcode 26.6 (17F113) locally, and the objectVersion-77 project built under
both without translation. The step ran 30 seconds by step timestamps
(04:24:10 to 04:24:40), package resolution and build included, with zero
`warning:` or `error:` lines anywhere in the run's log — the first CI
build of the app target, and a new baseline under its own conditions.
The gates run printed the same 17 and 18 prose-gate counts, then
`all.sh: 0 — every gate ran and found nothing`, and teeth closed
`plant cases 14, contract cases 1, failures 0` — 31 seconds for fifteen
cases, first log line to summary line by step timestamps. The series on
its one basis, each figure under its own conditions, no cause claimed:
42.249 seconds for nine cases local, 30 for nine on a runner, 28 for
eleven, 26 for thirteen, 34 for thirteen, 31 for fifteen. The
visibility tripwire printed its public line; `pull-request-body` still
waits for the first pull request. Acceptance items 2, 3 and 5 of unit
03's prompt are discharged — the simulator build locally and in CI, the
launch rendering the honest screen, and the harness green at fourteen
plants with the scope growth's plants in the same commit. Items 4 and 6
remain: the phone install is the owner's act at the unit's end, and
item 6 is a standing property, not a one-time check.

**The harness badge, landed with this record; its two flagged defects
were ruled remedied at review, before the commit.** `scripts/status.sh`
now also writes `docs/harness-badge.json` — shields endpoint schema,
label "harness", message "gates 9 / teeth 14+1", every figure derived —
and the README badge row gains one endpoint badge reading that file from
`main`, placed after the two live workflow badges. It is machine-derived
under the same one-behind convention as the block, which the badge rule
requires; nothing else qualifies today — coverage has no measurement,
and CodeQL is a checker decision, not a badge decision. The color field
is omitted with its reason stated in the script: counts, not verdicts.

The two defects the first draft carried, both caught at review as
already-ruled items shipping unfixed. A middle dot as the separator
would have been the tree's first non-ASCII character in a generated
string, spent on a glyph; the ruling was an ASCII separator, and the
message uses "/". And the draft's "+1" was a hand constant inside a
derived sentence — the constant-in-generated-block class the 2026-08-01
status.sh finding names, and the day a second contract case landed the
badge would have lied silently. The count is now derived from teeth.sh
itself, with one correction taken by measurement rather than from the
review's example: the pattern `^run_contract_case` also matches the
function definition line and reads 2 against a true 1, so the landed
pattern anchors both ends, `^run_contract_case$`, counting argument-less
call lines only — the script's comment carries the measurement. One
source of truth, zero typed figures.

The status.sh write boundary widened from README.md alone to README.md
plus the badge file; the script's header says so, and the boundary stays
verified at the commit that changes it, not by teeth. The badge file
itself sits in `docs/` and so enters the prose gates' scope: their
counts move to 18 and 19, measured locally at this commit, which is what
the next CI run should print.

**Measured, 2026-08-04 (UTC), runs 30878062468 (`gates`) and 30878062498
(`ci`) — the push carrying `08f45eb`, pushed by the owner.** Both green.
The gates run printed the predicted 18 and 19 prose-gate counts, then
`all.sh: 0` and `plant cases 14, contract cases 1, failures 0`. And the
badge is live end to end: shields' endpoint, given the raw `main` URL,
returned a rendering carrying `gates 9 / teeth 14+1` — read by `curl`
from the published service, not inferred from the JSON.

**2026-08-04 — unit 03 closes: the install measured on the phone, the
About string refreshed, the deferred topics re-audited.** Clock readings
at the measurement, both per the dating rule: 2026-08-04T05:05Z UTC,
2026-08-04 01:05 EDT on the host.

The install, acceptance item 4, performed by the owner with free
personal-team signing — by design: the first install was measured by
its owner, and the regressions belong to machines. The facts are
derived from the connected device rather than transcribed from the act:
`xcrun devicectl list devices` reports the phone connected as an
iPhone 16 Pro Max (iPhone17,2), `devicectl device info details` reads
iOS 26.5.2 (23F84), and `devicectl device info apps` lists
`Midkeep dev.midkeep.Midkeep 1.0 (1)` installed — the install read back
from the device itself. Three lines rendered on launch, reported by the
owner. iOS 26.5.2 runs an app declaring `.iOS(.v17)`, so the deployment
target is now exercised on hardware two majors ahead of it; a 17.x
device has still never run it, the same boundary the simulator
measurement carries. The ladder's marker moves to "can install", the
app-shell row flips to landed citing these facts, and the "unit 03,
open" mark leaves the Driven-by column — the rule that the mark goes
when the record closes, paying out for the first time.

The About refresh, owed since `56621c4` falsified its closing clause.
The string that stood, from the 2026-08-01 recovery entry above:

```
Unfinished work as first-class data — a Swift 6 iOS project built
harness-first: gates, invariants and a teeth harness before any feature
code.
```

"Before any feature code" stopped being true when the app shell landed.
The replacement, applied with `gh repo edit` and verified by reading the
description back through `gh api`:

```
Unfinished work as first-class data — a Swift 6 iOS app built
harness-first: nine gates and a teeth harness landed before the app
shell that now installs on a phone.
```

165 characters, 167 bytes in UTF-8 with no trailing newline counted —
the em dash is the difference — against GitHub's 350-character limit.
Provenance split as before: the first clause is `README.md:13-15`'s
reconstruction, unchanged; the remainder is observed from the tree —
nine gates counted from `scripts/gates/gate-*.sh`, the ordering from
units 01 and 02 preceding `56621c4`, the install from this entry's
measurement.

The deferred-topics re-audit against the new tree: none of the thirteen
names the app shell, so **zero topics release** — the rule ran and
released nothing, recorded rather than skipped. What the landing does
discharge is the caveat the 2026-08-01 About entry attached to the live
topic `ios` — "a declared deployment target, not a shipped surface" —
which stops holding at this measurement: the topic now stands on an
installed artifact. The thirteen stay deferred, each still waiting on
the capability that names it.

**The signing session rewrote the project file, and one line of it is
withheld from the tree.** Opening the project to select the personal
team made Xcode reserialize the pbxproj — its canonical formatting, a
Products group, `objectVersion` rewritten to 71 — and insert
`DEVELOPMENT_TEAM` with the owner's personal team identifier in both
configurations. The normalization is committed, so later Xcode sessions
stop churning the file; the identifier is not, and it is described here
rather than quoted, the same rule the address and host-path records
follow. It is a stable identifier of the owner's Apple account, headed
for a public tree, and neither prose gate can see it — not path-shaped,
not email-shaped — so nothing but review stands between it and a push.
Withholding is reversible in one commit if the owner rules the other
way (the identifier ships inside every distributed binary, so the case
is arguable); publishing is not, and this repository has paid for that
asymmetry three rewrites' worth. Until ruled on, selecting the team
again on the next device deploy re-adds the line locally, and an
untracked xcconfig is the candidate mechanism if the friction earns a
fix. gate-arch re-run against the normalized file: exit 0, both
clauses intact.

**A unit 04 prelude, filed now because the journal needs it.** Device
verification is automatable locally and not on CI. Locally: XCUITest
against a device destination, and `devicectl` scripts the
install-launch-read loop this entry used by hand. On CI: hosted runners
carry no physical devices, and paid device farms are excluded by the
standing constraint — no paid charges, ever. The journal's
kill-and-relaunch measurements need exactly the local rig, so unit 04
inherits this boundary on its first day: its device measurements run on
the development host and are recorded here, and CI covers everything up
to the device.

**Measured, 2026-08-04 (UTC), runs 30924525654 (`gates`) and 30924525125
(`ci`) — the push carrying `24b254a`, unit 04's opening docs commit,
pushed by the owner.** Both green, and every prediction the prompt filed
holds. The gates run printed `gate-hostpath: INV-14 over 19 files in
scope` and `gate-address: INV-15 over 20 files in scope` — the move from
18 and 19 the prompt predicted, the delta exactly the filed record —
then `all.sh: 0 — every gate ran and found nothing`, and teeth closed
`plant cases 14, contract cases 1, failures 0` — 48 seconds for fifteen
cases, first log line to summary line by step timestamps. The series on
its one basis, each figure under its own conditions, no cause claimed
for any direction: 42.249 seconds for nine cases local, 30 for nine on
a runner, 28 for eleven, 26 for thirteen, 34 for thirteen, 31 for
fifteen, 48 for fifteen. The visibility tripwire printed its public
line; `pull-request-body` still waits for the first pull request. The
block predictions — records filed 4, the unit 04 span row reading "file
not committed yet" — stand confirmed in the committed block. This
discharges acceptance item 1 of unit 04's prompt.

**2026-08-04 — ADR-0008 is the journal schema; the numeral the
deferred-topics entry had informally reserved for whose-server moves.**
Ruled at unit 04's decision brief. The 2026-08-03 deferred-topics entry
above says "the deferred ADR-0008" of whose-server; acceptance order
wins, and a deferred marker reserves no numeral — reserving a number
for an unwritten record is the forward-reference defect class in
another artifact, the same reason a record never names a future
commit's number. That entry is a kept finding and is not edited;
whose-server takes its own numeral the day it is accepted.
`docs/adr/0008-the-journal-schema.md` carries unit 04's ruling D2 as
amended at review — the framed-record file, the torn-tail/corrupt-middle
asymmetry with the refusal's fabricated-history argument, and the
durability boundary stated in both directions.

**2026-08-04 — the journal lands, and every test was watched failing
before its green was trusted.** Unit 04, rulings D2 as amended and D3.
`Sources/MidkeepKit/Journal.swift`: an actor generic over its entry
type, ADR-0008 made code — header record first, torn tail dropped,
reported and physically truncated so the next append cannot merge with
its bytes, corrupt non-final record refused, unknown schema version
refused. The URL is injected; the type is platform-neutral.
`Placeholder.swift` died absorbed, its `schemaVersion` now
`JournalSchema.version`, and the shell's second line moved to "A
journal exists. No runs yet." — the derivation being that `MidkeepKit`
holds `Journal.swift` and still no run type. INV-10's mark does not
move here: the ordering test needs a step executor to instrument, and
that is the run engine's commit (ruling D6).

The watched-both-ways measurements, counted as full runs of the
seven-test suite against seven mutants of `Journal.swift`, planted one
at a time and reverted before the next: no header written → 5 tests
failed; append skips memory → exactly 1, its target; replay discards
entries → 3; torn tail refused instead of dropped → exactly the two
drop tests, the refusal test green; corrupt middle skipped instead of
refused → exactly the refusal test, the drop tests green — the
discriminating pair ruled in D2, watched discriminating in both
directions; version guard removed → exactly 1; truncation removed → 2,
the physical-drop assertions. Every test failed under at least one
mutant, every mutant was caught, and the restored implementation ran
7 of 7 green with `all.sh` at 0 over nine gates before the commit.
The reopen-as-relaunch test carries its label in its own comment:
relaunch minus the kill, blind to a write held in process memory,
which is the rig's job and the deferred kill test's return trigger
(ruling D4).

**2026-08-04 — the run engine lands with INV-10's first test, and the
mark moves to PARTIAL in the same commit.** Unit 04, ruling D6 and the
engine half of D1. `Sources/MidkeepKit/RunEngine.swift`: `RunEntry` —
attempted, then completed carrying the step's product, ADR-0002's
two-record shape; `RunStep`, whose doc states its work must be safe to
re-run and why; `RunEngine.run()`, which journals the attempt before
the work and the completion after the product exists, skips steps the
journal shows completed, and re-attempts an attempted step whose
completion never landed, keeping both attempts in the history. The
ordering test asserts INV-10's own wording from inside a step's work:
the work reads the journal file from disk — not the actor's memory —
and records whether the attempted record preceded it. Five engine
tests, twelve in the suite. Three mutants, each planted alone and
reverted before the next, counted as full-suite runs: attempted
appended after the work → 2 tests failed, the ordering test reading
"work-first" and the failing-step test; the completed-skip removed →
exactly the resume test; the completion append removed → 3 tests.
Every engine test failed under at least one mutant, every mutant was
caught, and the restored suite ran 12 of 12 green with `all.sh` at 0
over nine gates before the commit. The mark move rides the same
commit, the D6 ruling: CLAUDE.md's row reads PARTIAL naming the test
and its boundary, INV-10 leaves the visibly-unenforced list it
opened, and the 2026-08-01 finding's disposition is discharged at its
entry.

**2026-08-04 — the rehearsal job lands with its screen, and
kill-and-relaunch was measured end to end on a simulator.** Unit 04,
ruling D1 with all three riders, and D5's entry point.
`RehearsalRun.swift`: four steps counting primes by sieve below 2000,
4000, 8000 and 16000 — real, tiny, deterministic — each product
appended to an artifact file distinct from the journal entry that
records it, with the step's own did-this-already-happen check read
from the artifact, never the journal: ADR-0002's demanded shape, so a
step killed between effect and completion re-attempts without
duplicating. The four expected counts were measured with an
independent sieve before the fixtures were written — 303, 550, 1007,
1862 — so the test compares the implementation to a measurement, not
to itself. Pacing is presentation, not work, and its doc says so. The
engine gained `afterEachRecord`, reporting reconstructed states after
every append so the screen shows exactly what the journal holds;
`RunView` and `RunScreenModel` render it, `ShellView` and the UI
placeholder die, and D1's third rider is discharged: "This screen is
the whole app." leaves in this diff, the new screen carrying its own
form of the claim. A corrupt journal renders its refusal on screen —
"nothing was skipped and nothing was guessed". `--start-job` is the
rig's entry point, standing in for the tap a person gives Start;
resume needs no argument and no tap, which is the capability itself.

Three more mutants, full-suite runs, each reverted: the sieve made to
skip 2 → the fixture test read 471, 853, 1557, 2869 against the
measured counts, 2 tests failed; the idempotence check removed →
exactly the duplication test, the duplicate line observed; the hook
made silent on attempted records → exactly the hook test. Restored:
15 of 15 green.

The simulator measurement, instruments named. Built with `xcodebuild`
for an iPhone 16 Pro simulator, iOS 18.0 runtime, exit 0 with zero
`warning:` or `error:` lines. Launched by `simctl launch` with
`--start-job`; killed by `simctl terminate` at +5 seconds; the journal
read back from the app container held the header, steps 0 and 1
completed, and `attempted(2)` with no completion — the kill window
ADR-0002 names, caught live. Relaunched with no argument; the journal
then held `attempted(2)` twice, its completion, and step 3's pair;
steps 0 and 1 were not re-run; the artifact held exactly four lines,
no duplicate; the screen read "Resumed from the journal: finished
steps were not re-run." — screenshot taken. The kill channel and its
semantics, per D5's rider: `simctl terminate`, process death as the
simulator delivers it, which is not the phone. The phone measurement
with its own channel record remains, and only it flips the ladder
row.

**2026-08-04 — the rig lands and the ladder capability is measured on
the phone: a job killed mid-flight carried on.** Unit 04, ruling D5 and
acceptance item 4. `scripts/dev/device-rig.sh` — not a gate, `all.sh`
stays device-free, device state not being a tree property. The two
channels, measured against Xcode 26.6's devicectl before use: the kill
is `device process signal --signal SIGKILL` — kill-mid-foreground, no
suspend ceremony, the strong semantics D5's rider required the record
to name; verification is `device copy from --domain-type
appDataContainer` — journal and artifact read off the device by the
host, never a screen. The signing team identifier is derived at run
time from the local certificate and never committed, the unit-03
withholding rule extended to the rig.

The judge was watched three ways against fixtures extracted from the
committed script before any live run: an honest resume exits 0; a
wiped-and-replayed journal exits 1; a rewritten journal exits 1. One
sharpening came out of the fixtures, recorded because the review that
demanded the prefix check deserves the measured answer: a wiped journal
replaying deterministic steps is byte-identical to a true resume's
prefix, so the prefix check alone stays quiet there — it is the
one-more-attempt check that catches the wipe, and the rewritten journal
is caught the other way around. The two checks cover each other's
blind sides, and neither alone suffices.

Two live runs failed before the pass, both at exit 2 — could not
measure, not capability failure — and each left a finding. Trust: iOS
denies the launch until the developer profile is trusted on the phone,
and an uninstall drops that trust — measured twice, a `--fresh` run
costs a new trust tap in Settings. Suspension: with the screen
auto-locking during the rig's minute-long build, the resumed job froze
mid-step — `attempted(2)` then silence, the journal unchanged when
re-read after the run — loss mode one intruding on the measurement of
loss mode two, and the judge refused it correctly. The run condition:
screen on and unlocked for the whole run.

The passing run, every fact derived from the device. iPhone 16 Pro Max
(iPhone17,2), build 23F84 — the unit-03 phone — pid 2708 SIGKILLed at
+5 seconds. The journal at the kill: steps 0 and 1 completed,
`attempted(2)` with no completion — the kill window, caught live on
hardware. After the plain relaunch: `attempted(2)` twice, its
completion, step 3's pair, the artifact at exactly four distinct
products, and the post-kill journal a byte-prefix of the final one.
Judge exit 0. The ladder row flips on this measurement, in the closing
commit that cites it.

**2026-08-04 — six plants went silently red when the file they anchored
on died; caught at close, not at the landings.** Unit 04. The
mechanism: harness fixtures coupled to feature-file identity. Six
plants appended their defects to `Sources/MidkeepKit/Placeholder.swift`
or edited `Tests/MidkeepKitTests/PlaceholderTests.swift`, then asserted
those files' own members afterwards — and `48122a8` deleted both files.
From that commit through `fbf6fa9` and `ac04756`, `teeth.sh` read
`failures 6` — plant-unchecked-sendable, plant-ui-in-kit,
plant-force-unwrap, plant-warning, plant-skipped-test,
plant-bad-format, each "refused or failed to plant" — while `all.sh`
read 0 at every landing. The two instruments measure different things:
gates measure the tree and teeth measures the gates, and only one was
run. Acceptance item 5 promised teeth green at every landing; unit
04's Results marks it falsified in part at those three SHAs. The red
was measured before the repair — failures 6, twice, consistently — and
stands as the repair's own positive control.

The repair, ruled Option B at a ratification stop: self-contained
plants. Each of the six now writes its own planted file —
`Sources/MidkeepKit/PlantedDefect.swift`,
`Tests/MidkeepKitTests/PlantedDefectTests.swift` — the harness's own
namespace, the shape every plant added since INV-13 already used: the
six were the old exception, not the rule. The near-miss forms moved
unchanged; every case still asserts exactly one finding at its planted
path; the clobber tripwires retired with the append hazard they
guarded. Repointing was rejected because it moves the coupling to the
next filename and the class recurs silently on the next rename — the
mechanism just measured. After the repair: `plant cases 14, contract
cases 1, failures 0`.

Deferred, named rather than built: "teeth at every landing" is a
promise with no mechanism, and this miss shows habit does not suffice.
A hook under `.githooks/` is the named candidate, its own ratification
stop when a unit takes it up.

**Discharged, 2026-08-04.** Unit 05, ruling D6: `.githooks/pre-push`
landed as its own commit at the ratification stop this marker named,
with the three riders the ruling attached — the install boundary in
the hook's own header, `--no-verify` written down rather than
discovered, and refusal always carrying teeth's own output. The
mechanism guards the push, not the commit: landings between pushes
still rely on the habit this unit has kept by hand, and CI remains
the enforcement a contributor cannot switch off.

**2026-08-04 — unit 04 closes: the journal row flips on the phone
measurement, the ladder reorders, and the release rule frees four
topics with one held by ruling.** The row flip cites the rig entry
above and nothing else; the "unit 04, open" mark leaves the Driven-by
cell — the close rule paying out a second time.

The ladder's rung order was a prediction and this unit falsified it:
"can recover" sat above "can run", and recovery landed while
streaming — half of "can run"'s own sentence — does not exist. The
rungs reorder rather than leaving the marker pinned under a false
ordering, and the marker moves to "can recover". The ladder is
hand-maintained, as its caption has always said.

The deferred-topics re-audit, against the release rule. Four released,
each by its committed truth-maker, applied with `gh repo edit` and
read back at eleven topics total: `state-machine` and
`workflow-engine` by the run engine, `resumable` and
`durable-execution` by the journal plus the resume-after-kill measured
on the phone. One held by ruling, recorded the way sqlite's hold was —
a coarse unit-01 mapping superseded by a specific decision:
`offline-first` maps to "journal storage" in the recovered list, but
that mapping was recovered verbatim after ADR-0007 had ruled
authoritative execution onto a server, and the capability the topic
names to a reader is the not-started "keep a job moving with no
signal" row, not the journal row. It joins the
on-device-ml/coreml/tensorflow-lite cluster on the undecided
whose-server assumption and may land or expire with it. The remaining
nine stay deferred, `sqlite` among them per ADR-0008.

Predictions, filed before the push that carries this close. Both
workflows green. The gates run prints `gate-hostpath: INV-14 over 20
files in scope` and `gate-address: INV-15 over 21 files in scope` —
the counts measured locally at this commit — then `all.sh: 0`, and
teeth closes `plant cases 14, contract cases 1, failures 0` with the
six repaired plants running on a hosted runner for the first time.
`ci.yml`'s simulator build stays green with the run screen in place of
the shell. The visibility tripwire prints its public line;
`pull-request-body` still waits for the first pull request. The teeth
wall time joins the series on its stated basis, no cause claimed for
any direction.

**Measured, 2026-08-04 (UTC), runs 30940587990 (`gates`) and
30940588095 (`ci`) — the push carrying `ac82cd0`, unit 04's close,
pushed by the owner.** Both green, every prediction held. The gates
run printed `gate-hostpath: INV-14 over 20 files in scope` and
`gate-address: INV-15 over 21 files in scope` — the counts predicted
from the local measurement — then `all.sh: 0 — every gate ran and
found nothing`, and teeth closed `plant cases 14, contract cases 1,
failures 0`: the six self-contained plants green on a hosted runner
for the first time, one push after their repair. Teeth wall time, 51
seconds for fifteen cases by step timestamps, joins the series on its
one basis, each figure under its own conditions, no cause claimed:
42.249 seconds for nine cases local, 30 for nine on a runner, 28 for
eleven, 26 for thirteen, 34 for thirteen, 31 for fifteen, 48 for
fifteen local, 51 for fifteen. The `ci` run built the run screen for
the simulator with zero `warning:` or `error:` lines. The visibility
tripwire printed its public line; `pull-request-body` skipped, still
waiting for the first pull request. This run is the CI half of
acceptance item 3's discharge, and unit 04's record owes nothing
further.

**2026-08-04 — unit 05 opens; the opening's own figure takes a
correction from the owner's side.** The driving prompt delivered to
the session said main stood at 44 commits; `git rev-list --count HEAD`
at `d957c86` reads 43, `scripts/status.sh` derived the same 43 into
the committed block, and the prompt's own source-of-truth clause —
the repository's records win over the prompt — caught its author. The
correction was the owner's first ruling on the unit, filed here as
directed. The opening commit `f88e700` landed with both instruments
read before it: `all.sh` at 0 over nine gates, teeth at
`plant cases 14, contract cases 1, failures 0` — the unit 04 lesson
applied at the first landing it binds.

**2026-08-04 — unit 05's decision brief ruled, six decisions, riders
recorded with the rulings they bind.** Every implementation commit of
this unit traces to one of these.

**D1 — both sources, one contract.** The streaming contract lands in
`MidkeepKit`; recorded fixtures drive the tests, and the rehearsal
gains a streaming step whose chunks are its own real local work. The
rider, on fixture provenance: a committed fixture must be honest
about what it is a recording OF — it is recorded from the rehearsal
streaming step's own real output, so the recorded-fixture test
inherits provenance from a real source and the tree carries no
invented "model output" text. The screen says what the stream is.

**D2 — the strict reading.** A chunk-offset record is journalled
before the chunk is displayed, and the cost of that choice is
measured and recorded this unit — chunk rate, journal growth, wall
overhead, each figure naming its instrument — so a later unit that
relaxes to watermarks rules against a figure, not a guess. Schema
version stays 1: the version names the framing contract — one JSON
object per line, header first, the torn-tail/corrupt-middle
asymmetry — and none of that changes; entry vocabulary grows within
it. The hole that creates is named rather than hidden: a version-1
reader older than the entry vocabulary refuses a newer file as
corrupt-record, which is the wrong word for "newer than me" —
tolerated while no build ships and every journal is discardable
rehearsal data; revisit trigger, the first journal that must outlive
a build boundary. ADR-0008's "the file describes itself" is weakened
by exactly that much, and ADR-0008's amendment says so.

**D3 — resume as reconstruction.** Re-display of journalled content
is reconstruction, not a duplicate effect; `resumed(fromOffset:)`
makes ADR-0007's sentence literal in the schema; the resumed record
lands before any continued chunk is displayed — the same orientation
as every other record.

**D4 — the rig measures, records stay clockless.** The streaming
measurement gains an uninterrupted control run — the rig's own
positive control. Timing is external, by the rig, instrument named:
determinism is load-bearing — the fixture tests and the byte-prefix
discriminator both lean on reproducible bytes, and a timestamp per
chunk would spend that for a figure the rig can take from outside.
Revisit only if a future unit needs in-record time, as its own
schema decision.

**D5 — the ordering test grows, the mark stays.** The INV-10
ordering test drives the streaming step, watched failing under a
reordered mutant before its green is trusted; the mark stays PARTIAL,
the row names the second driven step type, and the boundary sentence
stays — driving two types does not falsify "a test sees only the
step types it drives".

**D6 — the pre-push teeth hook, with three riders.** Ruled in: a
`.githooks/pre-push` hook running `teeth.sh`. One, the install
boundary is named in the hook's own header — `.githooks/` binds only
where `core.hooksPath` points at it, a fresh clone is unbound until
`scripts/dev/bootstrap.sh` runs, so the hook is a local seatbelt and
CI remains the public enforcement. Two, `--no-verify` exists and the
record says so: the hook raises the cost of an unwatched landing and
does not make one impossible. Three, on red teeth the push is
refused with teeth's own output visible, never a bare failure. The
hook lands at a ratification stop as its own commit; the unit-04
deferred marker is discharged by annotation when it does.

**2026-08-04 — the streaming contract lands with per-chunk
journalling, and every new test was watched failing before its green
was trusted.** Unit 05, rulings D1, D2, D3 and D5.
`Sources/MidkeepKit/Streaming.swift`: `StreamChunk` and `StreamSource`
— an answer delivered from any byte offset, in order, never a byte
before it — and `FixtureStreamSource`, whose fixture format opens with
a provenance record naming what the recording is OF, writer and parser
one contract. `RunEntry` grows `streamChunk` and `streamResumed` under
schema version 1; ADR-0008 takes the repository's first ADR amendment,
appended below the accepted text — the position ruled at the landing
as the precedent every later amendment inherits — naming both faces of
the vocabulary hole, including the one found by reading the replay
path rather than predicted by the ruling: an older build destroys a
newer final record as a torn tail, truncation and all. The engine
journals each chunk before its effect, appends the resumed record
before any continued chunk, and re-delivers journalled chunks as
reconstruction against the effect's own artifact check — D3's
orientation throughout, and the healing path for a chunk recorded
whose effect never ran.

The watched-both-ways measurements, counted as full runs of the
22-test suite against nine mutants of the contract and engine,
planted one at a time and reverted before the next:

```
1  effect before chunk record      the streaming ordering test, "effect-first"
2  resumed record removed          the resume test
3  resume streams from zero        the resume and reconstruction tests, 2 failures
4  reconstruction removed          the resume and reconstruction tests, 3 issues
5  states ignore chunk text        the partial-states test
6  fixture trim off by one         the trim test
7  product loses its prefix        the resume test, "5" against "2 3 5"
8  chunk records never journalled  4 tests, both ordering families among them
9  parser tolerates malformed      the refusal test
```

Every new test failed under at least one mutant, every mutant was
caught, and the restored suite ran 22 of 22 green. One repair inside
the measurement, recorded rather than smoothed over: mutant 4's first
run crashed the test helper — `dropFirst` handed a negative count when
the artifact met a gap the mutant created — which is a process death,
not a failed expectation, and it hides every other test's verdict. The
helper was repaired to refuse a gap cleanly and the mutant re-measured
as two clean test failures. `all.sh` exited 0 over nine gates after
one `gate-format` finding was fixed at the gate's direction; teeth
closed `plant cases 14, contract cases 1, failures 0` at the landing.

**2026-08-04 — the rehearsal streams, and the fixture is provably a
recording.** Unit 05, ruling D1 with its rider, and the screen half of
the honest-stream requirement. `PrimeStreamSource`: the primes below
300, found by trial division and emitted as each one is found — the
text exists only as the search produces it, so watching it arrive is
watching the work happen. 62 chunks, 218 bytes, and the answer was
measured with a Python trial-division loop before the Swift source was
judged against it — the unit-04 fixture discipline, applied to an
answer instead of a count. The streaming step is the rehearsal's
fifth; its bytes land in a second artifact whose appender holds the
idempotence check in offset form and refuses a gap rather than
fabricating bytes. The screen's intro names the streaming step and
the ordering it rides on, per the honest-screen rule.

The fixture, `Tests/MidkeepKitTests/Fixtures/rehearsal-stream.jsonl`,
was recorded from the live source by a throwaway recorder test that
was deleted after the one run that recorded it; its first line names
the source it records. The provenance test re-records that source on
every suite run and holds the committed bytes equal — the D1 rider as
a check that runs forever, not a claim made once. The recorded-fixture
test the ROADMAP bullet has named since unit 01 drives a killed stream
back to the measured answer from the fixture alone. `Package.swift`
gains the test-resource declaration — a resource, not a dependency;
INV-6 is untouched.

The watched-both-ways measurements, counted as full runs of the
27-test suite against four mutants, planted one at a time and
reverted before the next:

```
1  the search skips 2          answer, provenance and full-run tests
2  effect idempotence removed  the redelivery test
3  gap guard removed           the gap test
4  a fixture line deleted      both fixture-driven tests
```

Mutant 4 tampers with committed evidence rather than with code — the
direction the provenance check exists for, watched catching it. Every
new test failed under at least one mutant, 27 of 27 green restored,
`all.sh` 0 over nine gates, teeth `failures 0` at the landing.

**2026-08-04 — the D2 cost measured: what per-chunk journalling costs
on this host.** Unit 05, the measurement ruling D2 demanded with the
choice it prices. Instrument: a throwaway measurement test — deleted
after its runs, the fixture recorder's convention — under
`swift test -c release`, timed by `ContinuousClock`, on the
development host, an Apple Silicon Mac with a warm toolchain; three
runs, all quoted. The subject: a synthetic 10,000-chunk stream, 6
payload bytes per chunk, consumed twice — bare, and through the
engine with one record per chunk before its effect.

```
bare consumption   8.4 / 8.7 / 9.1 ms        the source alone
journalled         78.4 / 81.5 / 83.1 ms     one record per chunk
chunk rate         120,000–128,000 chunks/s  n over journalled wall
wall overhead      7.0–7.4 us per chunk      (journalled - bare) / n
journal growth     62.8 bytes per chunk record, 6 payload bytes each
```

The growth arithmetic, so the figure names what it counted: 688,240
bytes on disk, minus the header at 20, the attempted record at 30 and
the completion record at 60,049 — it carries the whole answer — is
628,141 bytes across 10,000 chunk records, 62.8 average. Framing
dominates at this chunk size and shrinks as chunks grow. The
rehearsal's own five-step run journals 4,280 bytes total, its
streamed answer 218.

Two observations, named rather than ruled. First: the journal holds a
streamed answer twice — once as chunk records, once inside the
completion product. Trivial at rehearsal scale; doubling at any
scale. Whether a streaming step's completion should carry its full
product is a question for the first unit that meets a big answer.
Second: the strict reading's price on this host is microseconds per
chunk against the 125 ms presentation pacing the rehearsal runs at —
four orders apart — so the watermark relaxation has no case today,
which is exactly what these figures exist to decide when someone
proposes it (ruling D2's purpose). Host figures, named as such: the
phone's own cost is the rig's business, timed externally per D4.

**2026-08-04 — the rig learns the stream, and its judge was watched
nine ways before any live run.** Unit 05, ruling D4 with all three of
its parts. `scripts/dev/device-rig.sh` gains `--stream`: the kill
lands mid-answer (KILL_AFTER defaults to 11 in stream mode, set only
inside the mode conditional so the stream default cannot be shadowed —
a pre-run check the owner filed and the file passed), and the judge
demands exactly one `streamResumed` carrying the offset the kill's
journal adds up to, contiguous continuation offsets after it, and no
re-emitted byte. Every rig run now begins with an uninterrupted
control run in a reset container — the positive control D4 ruled —
and "carried on" means byte-equal to what the control produced, never
to a constant. Time to first token is measured on the control run by
the rig, externally: a poll loop over `devicectl copy from`, reported
as an interval whose width is the poll period, with presentation
pacing named as the dominant term. Records stay clockless, per D4.

Two operational changes ride along, both bought by unit-04 findings:
the container is reset by overwriting the three run files over
`devicectl device copy to` — verified empty by reading one back —
instead of uninstalling, because an uninstall drops the phone's trust
and costs a tap per run; and the judge now reads a torn journal tail
the way the app does, dropping it and saying so, because a SIGKILL
can land mid-append and the old judge would have crashed on the very
evidence the kill is for. `--fresh` still uninstalls, at its price.

The judge, extracted verbatim from the committed script and driven
with hand-built fixture journals before any device saw it — nine
cases, each watched returning the verdict its direction demands:

```
1  honest stream resume                 0
2  wiped and replayed journal           1
3  resumed record with the wrong offset 1
4  a re-emitted byte after resume       1
5  stream artifact differs from control 1
6  torn tail at the kill, honest resume 0, tear named in a fact line
7  honest unitary resume, five steps    0
8  unitary wiped                        1
9  no step mid-flight at the kill       2
```

The unitary mode's judge changed with the tree — five steps complete
now, and both artifacts must match the control — so its clean case
was re-watched rather than assumed (case 7), and the window-miss path
now exits 2 through the judge itself (case 9). One line of dead code
found by shellcheck at this landing was removed rather than shipped.

**2026-08-04 — the pre-push hook lands, watched four ways on stubs
before it guards anything.** Unit 05, ruling D6 with its three riders,
discharging unit 04's deferred marker by annotation at that marker.
`.githooks/pre-push` runs `scripts/gates/teeth.sh` and refuses the
push on anything but teeth's 0 — red refuses, exit 2 refuses too,
because an unverified landing and a failed one are different facts
but neither is a verified one, and a missing or non-executable
teeth.sh refuses on the same ground. The hook's header carries the
install boundary (bound only where `core.hooksPath` points, which
`bootstrap.sh` sets; a fresh clone is unbound) and names
`--no-verify` so the bypass is documentation, not a discovery.

Watched before landing, in a scratch repository with `teeth.sh`
stubbed to each verdict — the hook relays, so the stub isolates the
relay itself:

```
teeth exits 1 (red)        push refused, stub's output in the refusal
teeth exits 0 (green)      push proceeds
teeth exits 2 (no verdict) push refused
teeth.sh missing           push refused
```

The green path through the real teeth runs on the owner's next push —
the hook's first live firing is that push, and this entry predicts it
prints `pre-push: teeth green; the push proceeds` after teeth's own
summary line.

**2026-08-04 — the streaming capability measured end to end on a
simulator; the phone run stopped at the lock screen and was refused
correctly.** Unit 05, the simulator half of acceptance item 4's
pattern, instruments named. Built with `xcodebuild` for an iPhone 16
Pro simulator, iOS 18.0 runtime, zero `warning:` or `error:` lines.
The control run, polled directly in the app container at 50 ms: first
streamed byte 9.44 s after `simctl launch` — presentation pacing
dominates by design, four unitary steps at 2 s each precede the
stream — and the run complete at 17.35 s, the stream artifact at the
measured 218 bytes. The measured run: killed at +12.7 s by
`simctl terminate`; the journal then held steps 0–3 completed, 28
chunk records carrying 82 answer bytes, no completion for the
streaming step, and the stream artifact held exactly 82 bytes —
record and effect in step at the kill, caught live. The plain
relaunch finished the job and six checks passed: the run completed,
the post-kill journal a byte-prefix of the final one, exactly one
`streamResumed(fromOffset: 82)`, contiguous offsets after it with no
re-emitted byte, the final stream artifact byte-equal to the control
run's, and the journalled product equal to the artifact. 62 chunk
records total — 28 before the kill, 34 after. Screenshots taken
mid-stream (the partial answer through 97 on screen under the honest
words) and after the resume. The kill channel and its boundary, per
unit 04's rule: `simctl terminate` is process death as the simulator
delivers it, which is not the phone; the phone measurement alone
flips the row.

The phone run was attempted the same hour and exited 2 at the control
launch: the device was locked —
`FBSOpenApplicationErrorDomain error 7, Locked`, quoted from the log
the rig kept — which is could-not-measure, not capability failure,
and the rig refusing rather than judging is the contract working.
The run condition stands as unit 04 wrote it: screen on and unlocked
for the whole run. The phone measurement remains owed, and only it
flips the ladder row.

## Known holes

Three kinds, labelled: an invariant with no gate, a gate with no plant, and a
gate whose check is a heuristic that can be wrong. Then everything else that is
true and uncomfortable.

**Invariants with no gate.** INV-6 — nothing in the tree stops a dependency
being added; the ADR requirement is a habit until a gate reads the resolved
dependency list. INV-10 — left this list on 2026-08-04, moved to PARTIAL by
the run engine's ordering test, the boundary in its row. INV-11 —
read by hand, and the line between "what this is for" and "what this does" is
where the hand review earns its keep. INV-12 — no gate reads commit message
shape. INV-13 left this list on 2026-08-03, when `gate-runners` landed with
both readable clauses and their plants; its unreadable half never will.

**INV-13's other half is outside the repository and always will be.** The two
clauses a gate can read — every `runs-on` a standard GitHub-hosted label,
`macos-*` only where a build needs it — are a proxy for the thing that actually
costs money, which is the account's spending limit. That limit lives in GitHub account settings. Nothing in the tree
can read it, no gate can assert it, and a green `gate-runners` will never mean
"no paid usage" — only "the workflows are shaped so that paid usage is less
likely". The mark is PARTIAL for that reason, in the same way INV-4's names what
a line-level grep cannot see, and the rule is not narrowed to what the tool can
reach.

**Gates with no plant.** INV-1's positive direction: the plant exercises the
opt-down, which is what happens when somebody silences a concurrency error, and
nothing exercises a manifest that declares no tools-version at all.
`gate-test`'s running half: `plant-skipped-test.sh` covers the text scan that
finds a disabled test, and nothing plants a *failing* test, which the gate finds
by a different mechanism. Both are asserted at the gate's own verification and
neither is watched by the harness.

**`App/` is read for imports and nothing else.** `gate-arch`'s allowlist
is the only check that opens the shim; `gate-hygiene` and `gate-format`
scan `Sources/` and `Tests/`, so INV-2's and INV-4's bans and the format
rule are unenforced there. Deliberate at this size — the shim is a
handful of lines and real code belongs in the package, where the gates
read it — and the boundary is restated in `.claude/rules/gates.md`.
Widening either gate's scope is a ratification stop and takes its plant
with it, the born-enforced convention.

**Heuristics that can be wrong.** `gate-hygiene`'s force-unwrap check is
line-level and cannot find Swift's literal boundaries. It fails in both
directions, measured rather than assumed and sourced to unit 02 in Findings: it
reports a force unwrap inside a `"""` block, which is text and not one, and
does not report `\(maybe!)` inside an interpolated string, which is one. The
rule is not softened to match the tool. A syntax-aware check needs SwiftSyntax,
which is a dependency and so needs an ADR under INV-6.

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
has no plant in `scripts/gates/teeth.sh`. The plant count stayed at eight while
Acceptance named that number; INV-13's two plants took that delta on 2026-08-03,
and INV-14's and INV-15's brought the count to twelve the same day.
`gate-workflow` still has no plant, and a later unit that wants one takes its
own delta.

**`actionlint` is optional, not a precondition.** Without it `gate-workflow`
returns 2 and so does `all.sh` — the contract's third code rather than a
failure, and the same shape as a host with no Swift. The cost is that a fresh
clone's `all.sh` reports "could not run" rather than green until the tool is
installed.

**Things nothing reads.** Three paths in the tree are read by no gate:
`LICENSE`, `.gitignore` and `scripts/dev/bootstrap.sh`. This paragraph
counted sixteen until 2026-08-03, when the two prose gates landed and
thirteen of the sixteen — every ADR, both README files, `CLAUDE.md`, this
file, `.claude/settings.json` and `.claude/rules/gates.md` among them —
fell inside their scope. Read for two leak shapes, which is not review:
INV-11 stays checked by hand. Of the three, `.gitignore` is still the one
worth naming, because something other than a human acts on it: it is read
by git, so a wrong line either commits a per-machine override or silently
hides a tracked path, and no gate would notice either.

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

**The teeth harness has run on one machine.** The figure is 42.249 seconds
wall for nine cases, quoted from `time` output at
`docs/prompts/01-repository-and-harness.md:1312` — taken locally on the
development host, an Apple Silicon Mac. The host was warm — toolchain and
OS file caches hot — but each case compiles from scratch in a fresh
worktree by design (`:1315`), so the build cache itself was cold per case.
Those are the baseline's conditions, stated because a figure names what it
counted and a comparison names the conditions both figures were taken
under. A GitHub runner performs the same from-scratch compile — the Teeth
step sits in the `macos-15` job at `gates.yml:12`, so the toolchain is
Apple's, hosted and virtualized, not Linux's — and what differs is the
machine, the toolchain version, and runner setup overhead, not compile
scope. The first CI timing is therefore a new baseline under new
conditions, not a comparison against this one.
Whether teeth can run on every push is a measurement for whichever unit
first gets both workflow steps to execute.

**Discharged, 2026-08-01.** The paragraph above is kept as taken; the second
machine arrived. Run 30724101184, triggered by the push installing pinned
actionlint, executed Teeth on a `macos-15` runner: nine cases, `failures 0`,
30 seconds by step timestamps — faster than the local 42.249, not slower.
Both figures stand as baselines under their own conditions; Findings carries
the full reading. Teeth can run on a push for this tree size, measured once.

**Repository visibility.** `github.com/sebkoo/midkeep` is public. Three
generations exist and the record distinguishes them by `created_at` and `id`,
because "the repository" alone is ambiguous across a day with two deletes:

```
gen 1  private, then deleted            (metadata lost with it)
gen 2  2026-08-01T11:46:44Z  id=1319248773   public, carried the email rewrite
gen 3  2026-08-01T13:28:48Z  id=1319316813   public, carries the host-path redaction
```

Gen 2 was established as a recreation rather than a flip two ways: the creation
timestamp was minutes old, and its Actions history held nothing older than its
first push — the runs at 11:11 and 11:33, read earlier the same day, were gone.
Gen 3 carries the description and all seven topics, restored from
`~/midkeep-about.txt` and the list recorded above.

**The residue cleared on the push, not on the garbage collection**, and the
attribution matters because a later reader would otherwise reason wrongly about
the next such case. `git push -u` moved `refs/remotes/origin/main` from `baf697c`
to `ce1756b`, and the pre-redaction objects became unreachable at that instant.
Measured: the sweep across `--all` read 0 **before** `git gc --prune=now` ran.
The gc reclaimed 9 loose objects and took the pack from 120 to 111 — disk, and
nothing else. A ref holding an object is what blocks pruning, so the ordering
requirement is that the ref moves first; `scripts/gates` has no part in it and
`e5-cleanup.sh` asserts it rather than assuming it.

An earlier version of this entry said that only a garbage-collection request to
GitHub Support could remove the pre-rewrite objects, and that the request had to
come before any flip to public. **That sentence was wrong when written, not
overtaken by events.** Delete-and-recreate removes them, which is why it was the
recommendation in the same breath; the sentence asserted a constraint the
recommended remedy already contradicted. Falsified by the acceptance test above:
four pre-rewrite hashes now return `No commit found for SHA` and
`upload-pack: not our ref`.

What that entry got right is that the SHAs are recorded in a committed document,
at `docs/prompts/01-repository-and-harness.md:1792` and `:1813` — `f22c608`,
`334438d`, `334438db`, `0d1904c` and `4d663458`. On a public repository a
committed SHA is a lookup key anyone can use, so the two facts together are what
made delete-and-recreate the remedy rather than a force-push. The pre-rewrite
HEAD `1c16da5` is not among them; the argument rests on `f22c608`, the
pre-rewrite root, which carried the old address.

**An absolute host path is still in reachable history.** It appears at
`docs/prompts/01-repository-and-harness.md:403` and `:1363`, in the three commits
carrying that file — the host's local account name, inside a `/Users/…` path
quoted from tool output. It is reachable rather than orphaned, so neither the
email rewrite nor the delete touched it, and the push republished it.

The host-path redaction is the third rewrite and exists to remove those two
lines. It is scoped to exactly them: the six sites in this file that once named
the string were rewritten by hand beforehand, so `git filter-repo --replace-text`
changes two lines in one file and `commit-map` is auditable by reading it.

**"Third" needs its basis stated, because two counts of the same events are
both defensible and they differ.** Counting rewrite *operations* gives three:
the `--mailmap` pass over all twelve, the citation repair that amended Commit 10
and replayed 11 and 12, and this redaction. Counting `git filter-repo`
*invocations* gives two, because the citation repair used `commit --amend` and
`cherry-pick` instead. The commit subject carrying this record uses the second
basis and says two; this paragraph uses the first and says three. Neither is
wrong and the reconciliation is here rather than left to a reader.

The ambiguity has already produced one wrong reading in the session that created
this entry — "three rewrites" was written without a basis and read as a count of
filter-repo runs. That is why the basis is now named at the point of use.

Two traps, recorded so they are not rediscovered. The backup bundle's **absolute**
path contains the string, so committed text refers to it only as
`~/midkeep-pre-public.bundle` — never expanded. And the string is described here
as the host's local account name and no more precisely, because further detail
adds correlation signal and no record value.

**Owed before any feature code: a gate for absolute host paths.** Pattern
`/(Users|home)/<segment>/`, under the same exit contract as every other gate —
0 none found, 1 found with `path:line:` on stdout, 2 could not look.

**Ship the segment class alone. Do not ship an exemption list.** The published
tree carries six occurrences of the literal `/Users/`, in four distinct forms —
counted as occurrences, not as forms or as files:

```
1  /Users/                        this file, in the sentence specifying the gate
2  /Users/<name>/                 CLAUDE.md's prompt-line rule, and this file
2  /Users/<redacted>/dev/midkeep  the prompt document, :403 and :1363
1  /Users/…                       this file
```

Not one is a real path, and the segment class decides all six on its own.
Measured against those forms plus a real-path control, the two candidate
patterns differ by one character and disagree completely:

```
/(Users|home)/[A-Za-z0-9._-]+   matched the real-path control, none of the six
/(Users|home)/[A-Za-z0-9._-]*   matched all six placeholders as well
```

`+` is the pattern; `*` is the defect, and it would go red on this very
document.

**The control is not reproduced here, and that is the point.** A real path
written into this file would match the pattern being shipped, so the gate would
fire on the paragraph proving the gate correct and `all.sh` would sit at 1
permanently. Exempting it would be the string blocklist removed two paragraphs
above, and a control the gate ignores demonstrates nothing about the gate's live
behaviour.

The control belongs in `scripts/gates/teeth/plant-hostpath.sh`, where being
flagged is the desired outcome. **That plant does not exist yet** — the tree
carries ten, and this would be the eleventh. It lands with the gate, not before,
and until then this paragraph describes a design and not a file.

It will carry the real path as a **literal**, the way
`plant-unchecked-sendable.sh` carries `@unchecked Sendable`, rather than
assembling it from fragments to dodge the pattern. Assembly would be the wrong
fix and is recorded as rejected: a plant whose defect the gate cannot match is
a plant landing something other than what it names, the teeth run goes green,
and the harness certifies a tooth that is not there. The named scope is what
makes the literal safe, and it is the mechanism doing the work. That follows
the convention already in the tree rather than a new one: every existing gate
scans named source directories — `gate-hygiene` scans `Sources` and `Tests`,
`gate-format` scans `Package.swift Sources Tests` — so `scripts/gates/teeth/`
is outside every scan by construction. It is why `plant-unchecked-sendable.sh`
can contain the literal `@unchecked Sendable` without tripping the gate it
exercises.

This gate takes the same shape: a named scope over the prose surface where the
leak class lives — `docs/`, `CLAUDE.md`, `README.md`, `.claude/` — which puts the
plant out of scope without an exclusion list. The cost is stated rather than
hidden: an absolute host path inside `scripts/` or `Sources/` would not be
caught, and closing that needs a wider scope and a decision about the plant.

A directory scope is not a string exemption, and the difference is that it is
testable both ways: a real path in `docs/` must fire, the plant's own copy must
not. No unexercisable branch returns.

So an exemption list for `<name>`, `<redacted>` and `…` **can never fire** — the
class already excludes every one of them. Shipping it would be shipping a branch
that cannot execute, which is the same shape as a check that cannot fail: it goes
untested, rots quietly, and becomes load-bearing the day someone widens the class,
at which point nobody knows whether it was ever right.

The condition for its return, stated so the decision is not re-litigated: if the
segment class is ever widened to admit `<`, `>` or `…`, the exemption comes back
**in the same commit as a plant that exercises it**. Not before, and not against
a hypothetical.

The bare `/Users/` earns a place in teeth as a **negative** case — a line that
must not trigger. That is this session's absence-needs-a-positive-control rule
turned on the gate itself: without it, `+` and `*` are indistinguishable from a
green run.

It searches for a **shape** and not for the string, which is the whole reason it
can exist. A gate that looks for a secret has to contain the secret; this one
carries nothing, needs no ignore file, and would have caught the original
occurrence at Commit 10. It lands before any feature code rather than somewhere
in unit 02, because the string has cost three rewrites and this is what stops a
fourth. The commit that discharges this marker cites it; the marker does not
name that commit, because a record cannot know a future commit's number.

**Discharged, 2026-08-03.** `scripts/gates/gate-hostpath.sh` and
`scripts/gates/teeth/plant-hostpath.sh` landed as specified: the segment
class with `+`, the plant carrying a fabricated real-shaped literal as its
must-fire control, and the bare `/Users/` line as the negative case this
record demanded. Two things sharpened in the landing, both ratified. A
carve-out for the hosted runner's home — one occurrence in scope at the
time, this file quoting an actionlint checksum line — enters with a
must-not-fire plant line in the same commit, which is the exemption
rule's own condition; it is removed from a line per occurrence rather
than exempting the line, and a probe proved a real path written
immediately after a runner path still fires. And files are enumerated
with `git ls-files -co --exclude-standard` rather than a bare recursive
grep, because `.gitignore` documents a per-machine file inside `.claude/`
and a finding on ignored text would be a verdict about something git will
never record. Twenty probes across the two prose gates, zero failures;
the tree's own scan read 15 files and found nothing. INV-14 and INV-15
are the first invariant rows born enforced — the row, its gate and its
plant landing together rather than the rule arriving before the check.

## Next capabilities

In ladder order, unnumbered: the driving units in `docs/prompts/` hold
the only numeral namespace, per the 2026-08-03 collision entry in
Findings.

- **App shell.** An Xcode project wrapping the SPM modules, with the
  Info.plist, entitlements and background-task identifiers later units
  need. Until this lands, nothing runs on a device and no launch, memory
  or UI measurement is possible. Driven by unit 03, opened 2026-08-03.
- The journal, and a test that kills the process and resumes from it.
  Driven by unit 04, opened 2026-08-04.
- The streaming contract, with a recorded-fixture test. Driven by
  unit 05, opened 2026-08-04.
- The on-device gate that decides local against server, and a second
  engine behind the same contract.
- Signal capture and an offline evaluation loop.
- Performance and memory instrumentation.
- A remote-config-backed feature flag service.
- An `EntitlementProviding` protocol with an always-entitled stub, decided
  while the module boundaries are still soft rather than retrofitted
  through call sites later.
