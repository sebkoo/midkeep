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

## Known holes

Three kinds, labelled: an invariant with no gate, a gate with no plant, and a
gate whose check is a heuristic that can be wrong. Then everything else that is
true and uncomfortable.

**Invariants with no gate.** INV-6 — nothing in the tree stops a dependency
being added; the ADR requirement is a habit until a gate reads the resolved
dependency list. INV-10 — cannot be gated until there is a runtime. INV-11 —
read by hand, and the line between "what this is for" and "what this does" is
where the hand review earns its keep. INV-12 — no gate reads commit message
shape. INV-13 — `gate-workflow` is named as its enforcement and does not yet
carry the check, so at this commit the readable half is unenforced too.

**INV-13's other half is outside the repository and always will be.** The two
clauses a gate can read — no `push:` trigger, `macos-*` only where a build needs
it — are a proxy for the thing that actually costs money, which is the account's
spending limit. That limit lives in GitHub account settings. Nothing in the tree
can read it, no gate can assert it, and a green `gate-workflow` will never mean
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
carries eight, and this would be the ninth. It lands with the gate, not before,
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
