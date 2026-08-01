# 2. The run is the unit of persistence

Date: 2026-08-01

Status: Accepted

## Context

Consider an assistant three steps into a job: rename two hundred photos by what
is in them, file them, then write the index. The third step has finished. Then
the phone rings, or the train enters a tunnel, or iOS reclaims the memory
because something else needed it.

Almost every client answers this the same way. It never happened. You come back
to a dead spinner, or to a screen that has forgotten there was a job at all,
and you start over.

That is not a model problem. The model did the work; the answer existed. What
failed was the client's willingness to write anything down before it had
everything. The interesting unit of state is not the finished result — that is
easy, because by the time it exists there is nothing left to lose. The
interesting unit is the run that is three steps in, and it is the one almost
nobody persists.

Four things follow from taking that seriously, and they are design constraints
rather than aspirations. A partway state has to be a named state the software
can describe, not a spinner standing in for the absence of one. A step that has
completed has to survive suspension, termination and relaunch, which means it
has to be somewhere other than memory before the process can be taken away.
Stopping has to actually stop, so that a cancelled run aborts its stream and
stops consuming battery rather than merely hiding its output. And every run has
to leave a record of what was attempted, what landed and what it cost, because
otherwise every claim about the software's behaviour is unfalsifiable.

The name follows from this: what is kept is the middle of the run.

## Decision

Every step a run takes is journalled before its effect is observable, and no
run state lives only in memory.

"Observable" means visible outside the run's own memory — a file written, a
message sent, a row inserted, a token delivered to the user. It does not mean
"decided" or "computed". A step may think as long as it likes; the record has
to precede the moment its thinking becomes something the outside world can see.

The journal is append-only. A step is recorded as attempted, and its outcome is
recorded as a later entry rather than by rewriting the first. Resume reads the
journal forward and reconstructs where the run got to.

## Alternative considered and rejected

The obvious alternative is to journal after the effect. It is cheaper — one
fewer write on the happy path — and it has a real advantage: the record always
describes something that actually happened, so the journal can never claim a
step the world did not see.

It was rejected because the failure it permits is precisely the failure this
repository exists to prevent. If the process dies between the effect and the
record, the step is invisible on relaunch and will be performed again. When the
step is idempotent that is waste. When it is not — a message sent, a file
moved, a charge made — it is a duplicate, and the user experiences the crash as
the software doing something twice.

Journalling first permits the opposite failure: a step recorded and then not
performed, because the process died in the window between. That failure is
recoverable. The record says the step was attempted, so resume can check
whether the effect landed and either finish it or mark it failed. The
write-behind failure is not recoverable, because nothing anywhere knows the
step happened at all.

Between a failure mode that leaves evidence and one that leaves none, this
repository takes the one that leaves evidence, and pays two writes per step for
it.

## Consequences

Every step pays for a durable write before it can do anything visible. On a
step that is itself cheap this is the dominant cost, and a run made of many
small steps will feel it. Whether that cost is acceptable is a measurement, not
an argument, and nothing here has measured it yet.

There is a window in which the journal is ahead of reality — a step recorded as
attempted whose effect never landed. Resume has to handle it, which means every
step needs a way to answer "did this already happen?" that does not depend on
the journal. Steps that cannot answer that question cannot be made safely
resumable, and the run engine will have to say so rather than pretend.

This is INV-10 in `CLAUDE.md`, and it is marked UNENFORCED. No gate checks it,
because at this commit there is no runtime to check. It is the invariant the
product rests on and the one nothing can verify yet, which is an uncomfortable
pairing and is recorded rather than hidden. It becomes enforceable when the
journal lands, and `docs/ROADMAP.md` carries that as a finding with the same
disposition.
