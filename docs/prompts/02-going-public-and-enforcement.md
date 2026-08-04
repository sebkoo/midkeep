# 02 — going public, and the enforcement the record owed

## Status

Closed, and filed after the fact. This record was written on 2026-08-04
UTC — the host reading 2026-08-03 — for work done from 2026-08-01
through 2026-08-04 UTC. Unit 01's record was transcribed before its
gates were written and governed them; this one was not, and saying so is
the condition of its integrity. The ordering is a deviation from the
unit-01 convention, recorded rather than repaired: a retrospective
record that admits its tense is evidence, and one that fakes foresight
is fiction. The deviation is spent here, once. Unit 03 opens in a new
session with its driving prompt filed before any work, which is the
convention this paragraph exists to make visible.

Because the record is retrospective, it contains no Predictions and no
Results marking them confirmed or falsified — that structure only means
something written blind. What it contains instead is an Acceptance list
written as what *was* accepted, each item citing the commit or run that
discharged it, and pointers into `docs/ROADMAP.md` → Findings, where the
measurements were recorded as they happened, dated, by the sessions that
took them.

## Intent

Unit 02 did not begin with this intent; it acquired it. It opened as a
review of unit 01's invariant marks and became, in order: the discovery
that history carried a personal address; the rewrites that removed it
and the host path; the decision to go public and the two deletions that
made generation 3; the no-paid-usage constraint (INV-13), its amendment
when the repository's visibility changed the facts under it, and its
enforcement; and the two prose gates the leak class had earned, landing
born enforced. What unit 02 set out to do, stated honestly, is: make
the repository safe to publish, publish it, and then make the harness
enforce every readable clause of what "safe" and "unpaid" mean here.

Unit 01 left a standing question that every later unit must answer in a
sentence before it starts. Unit 02 answers it late, like everything else
in this record: this unit lowered the cost of every future proof by
making the repository public — a proof nobody can read is a proof only
on trust — and by making the leak-and-cost rules self-enforcing; it is
still harness work, the ratio warning stands, and unit 03 owes feature
code.

## Non-goals

Still true at close, each measurable against the tree: no feature code —
`Sources/` holds three `Placeholder.swift` files and nothing else; no
Xcode project and no app target; no third-party dependency; no
`.claude/skills/` directory. The gate-workflow teeth plant was not
taken. The host-path segment class was not widened, and its named blind
spots — the wrapped line, the doubled slash, the non-ASCII account name —
were pinned by probes, not closed.

## Constraints

The owner's constraint, verbatim from `CLAUDE.md` § Invariants, INV-13:

> No paid GitHub usage.

Everything else in that invariant's text — the readable clauses, the
amendment history, the unreadable half that lives in account settings —
is the working-out of those four words against what a tree can and
cannot assert. The clause history and its grounds are in Findings
(2026-08-01 "INV-13 added", 2026-08-02 "replaced by amendment",
2026-08-03 "readable clauses gain their gate"). The constraint bound
every decision in this unit that touched CI: the visibility tripwire
sits exactly where the money would be spent, and the runner allowlist
is written so that growing it is a ratification stop.

## Acceptance

Written as what was accepted, each item citing what discharged it.

1. **History carries the noreply identity and no personal address.**
   Discharged by the mailmap rewrite of all twelve commits (Findings,
   2026-08-01, "all twelve commits were rewritten to a noreply
   address") and measured against generation 3: the current head
   resolves with `61488202+sebkoo@users.noreply.github.com`, and every
   pre-rewrite hash tested returns `No commit found for SHA`, with a
   resolving control so the test discriminates (Findings, "Discharged,
   2026-08-01").

2. **No absolute host path is reachable, and the class is now gated.**
   The redaction rewrite removed the two carrying lines from this
   file's sibling record; `gate-hostpath` (commit `b03e7fb`) enforces
   the segment class over the prose surface, ratified by an independent
   adversarial pass, green on run 30871618701.

3. **The repository is public, generation 3, with its About string and
   seven topics restored.** `created_at 2026-08-01T13:28:48Z`,
   `id 1319316813` (Findings, "Repository visibility").

4. **INV-12 is stated in bytes, with its revisit trigger.** Commit
   `c5ad430`; the measurement that nothing sits between bytes and
   characters in today's tree is the 2026-08-01 Findings entry.

5. **INV-13 is amended, tripwired, and enforced.** The amendment is
   commit `67b637b` with its grounds in Findings; the tripwire is
   `6f08ae6`, measured live on runs 30727083627 and 30727083599; the
   enforcement is `gate-runners` with two plants (commit `0f2e74b`),
   landed only after a five-finding review was fixed against
   measurements, green on run 30862749381.

6. **INV-14 and INV-15 exist and were born enforced** — row, gate and
   plant in one commit (`b03e7fb`), the first rows with no gap between
   rule and check, ratified on thirteen probes and five mutants, green
   on runs 30871618701 and 30871618710.

7. **Teeth grew from eight plants to twelve, and the timing series
   stands on one stated basis:** 42.249 s for nine cases local, 30 for
   nine on a runner, 28 for eleven, 26 for thirteen — each under its
   own conditions, no cause claimed (Findings, the three "Measured"
   entries of 2026-08-02 through 2026-08-04).

8. **The README tells the truth live.** Badges derived by machine ahead
   of static claims (`69ccdf9`), the status block regenerated in the
   commits that changed its numbers, and the ladder split from the
   driving-unit scheme with measurable statuses after the false row
   was caught (`5e8775e`; Findings, 2026-08-03, "two schemes shared
   the word unit").

9. **CI checks its own checkers.** actionlint pinned (`8161d2e`), the
   first green gates run recorded with its baseline (`dca03f1`).

The commit that files this record closes the unit; it is not cited
here, because a record cannot know a future commit's number.

## The record

The lab-notebook half of this unit is `docs/ROADMAP.md` → Findings, not
this file, and it is deliberately not duplicated: those entries were
written when the measurements were taken, and copying them here would
create a second copy that can drift. The unit-02 entries run from
"three invariants marked enforced are not" (2026-08-01) through "two
schemes shared the word unit" (2026-08-03), with the identity rewrites,
the INV-13 arc, the prose-gate pair and the teeth series between.

## Amendment log

This unit created one exception class: edits delivered by history
rewrite rather than by commit — meaning the change carries no commit of
its own, and a span derived from commits touching a file cannot see it.
Three were performed, counted as operations (the reconciliation of that
count against filter-repo invocations, which gives two, is in Findings):

1. The mailmap pass, rewriting the author identity of all twelve
   then-existing commits.
2. The citation repair, amending Commit 10 and replaying 11 and 12.
3. The host-path redaction, rewriting two lines of the unit-01 record.

Each is marked at its site in the Findings entries that record it, and
the status block's own caption carries the general caveat: a record
span counts commits touching the file, not the unit's whole work.
