# 8. The journal schema

Date: 2026-08-04

Status: Accepted

## Context

ADR-0002 decided that every step is journalled before its effect is
observable, that the journal is append-only, and that resume reads it
forward. It did not decide what the journal physically is. Unit 04 lands
the first journal, so the on-disk shape stops being deferrable:
`schemaVersion = 1` has been a committed claim since unit 01, in
`Sources/MidkeepKit/Placeholder.swift`, and the first byte written under
that number constrains every later reader.

Three constraints bind the choice, each already enforced or ruled. INV-3
as enforced: `gate-arch` allowlists `MidkeepKit`'s imports to
`Foundation|Dispatch|os|Observation`, so a storage engine beyond
Foundation widens a gate, which is a ratification stop. INV-6: a
third-party dependency needs an accepted ADR. And Swift 6 strict
concurrency: a C API pushes toward exactly the unsafe wrappers INV-2
bans. The deployment target is iOS 17 (ADR-0004).

This record carries unit 04's ruling D2 as amended at review, and its
sub-ruling on this record's own numeral, which is recorded in
`docs/ROADMAP.md` → Findings rather than argued here.

## Decision

The journal is a single append-only file of framed records: one JSON
object per line, UTF-8, newline-terminated, written by one actor, read
forward from the first line. Foundation only — `Codable` for the
framing, `FileHandle` for the appends.

The first record of every journal file is a header naming the schema
version it is written under. The file describes itself; no reader needs
outside knowledge to know what it is holding.

Records are appended and never rewritten. A step is recorded as
attempted, and its outcome is a later record rather than an edit of the
first — ADR-0002's words, now with a physical meaning: an edit would be
a seek backwards, and the writer never seeks.

A record is complete when its terminating newline is written. Two
failure shapes are distinguished, and the asymmetry between them is the
schema's central property:

**A torn tail** — the final line fails to parse or lacks its
terminator. Reconstruction drops it and reports the drop. This is safe
by ADR-0002's ordering argument: the journal write never returned, so
the effect that follows the write was never started, and re-attempting
the step is the recoverable direction.

**A corrupt non-final record** — a line that fails to parse with valid
records after it. That is not a torn tail; it is a different failure
class — a bug, bit rot, or a second writer — and no ordering argument
makes skipping it safe. Reconstruction refuses loudly and never skips,
because silently skipping would fabricate a shorter history than the
one on disk, and a fabricated history is the one thing a journal must
never produce.

## The durability boundary

Stated rather than implied. Appended bytes survive process death by
construction: the page cache belongs to the kernel and the kernel
outlives the process. Of the repository's four loss modes, only
termination destroys process memory — suspension keeps it, a network
drop kills a stream while the process lives, and a cancel is a
deliberate stop rather than a failure — and none of the four is a
power event. Page-cache survival is therefore the full durability
claim the repository's question requires. Power-loss durability is a
separate claim this schema does not make; making it needs
`F_FULLFSYNC` per record, and that is deferred until a unit needs the
claim and measures what it costs.

The corruption detector is JSON well-formedness, and that is a boundary
too: a corruption that preserves well-formedness passes it. No
per-record checksum is added — cost without a ruled need. The return
trigger is the day the journal claims integrity against bit rot rather
than survival of process death.

## Alternatives considered and rejected

**SQLite through the system library.** Not third-party, but measured
against the tree: `import SQLite3` is outside `gate-arch`'s allowlist
for `MidkeepKit`, so choosing it widens a gate, and the API it buys is
a C interface that fights strict concurrency. Real transactional
durability is not needed by an append-only log with one writer.
Revisit trigger: the signals-and-evaluation capability wants queries
over many runs, and SQLite re-enters then with its own ADR. The
deferred `sqlite` topic stays deferred until that day.

**GRDB.** A real dependency: an INV-6 ADR, an ask-gated
`Package.swift`, and a supply chain, purchased for ergonomics an
append-and-read-forward log does not use.

**SwiftData / Core Data.** An object graph is the wrong shape for an
append-only log — its natural operations are the mutations this schema
exists to forbid — and Core Data's concurrency model predates strict
checking.

## Consequences

Single-writer discipline is not a convention but a type: the journal is
an actor, and the file has exactly one handle. There are no queries and
no transactions, which is the price of Foundation-only, and nothing yet
needs either.

Both failure shapes are cheap to plant: a test truncates the file
mid-record for the torn tail and corrupts an interior line for the
refusal, so each direction of the asymmetry is watchable both ways —
the discriminating pair unit 04's ruling demands.

The journal file's location is not part of the schema. `MidkeepKit`
takes a URL and stays platform-neutral; the composition root decides
where the file lives on each platform.
