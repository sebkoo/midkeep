# 7. The server executes a run; the device participates

Date: 2026-08-01

Status: Accepted

## Context

Three commitments already in this repository point in two directions, and the
Info.plist that unit 02 is about to write is where the contradiction stops being
theoretical.

INV-10 and ADR-0002 say every step is journalled before its effect is
observable, and that a run three steps in survives suspension, termination and
relaunch. Read casually, that describes a device that keeps working while it is
in the background.

iOS says otherwise. The deferred topics in ROADMAP — on-device routing, a Core
ML path, a second engine behind one contract — assume a device that can execute
a long run. Nothing has yet asked whether it can.

The answer is a property of the platform at the deployment target ADR-0004
declares, so it was read from the installed SDK rather than recalled.

## What was measured

Read from `iPhoneOS26.5.sdk`, `BackgroundTasks.framework`, on 2026-08-01.

```
BGTaskScheduler                     API_AVAILABLE(ios(13.0))
BGAppRefreshTask                    API_AVAILABLE(ios(13.0))
BGProcessingTask                    API_AVAILABLE(ios(13.0))
BGProcessingTaskRequest             API_AVAILABLE(ios(13.0))
    requiresNetworkConnectivity, requiresExternalPower   — requests, not guarantees
BGContinuedProcessingTask           API_AVAILABLE(ios(26.0))
BGContinuedProcessingTaskRequest    API_AVAILABLE(ios(26.0))
```

`BGContinuedProcessingTask` is the only one of these built for work a person
started and expects to finish: it conforms to `NSProgressReporting` and the
system shows the progress. It is iOS 26.0. The deployment target is iOS 17.0.

Below iOS 26 the app cannot ask the system to keep running work the user
started. It can only submit a `BGProcessingTaskRequest` and be scheduled at the
system's discretion, on the system's timing, under conditions the request may
ask for and cannot require.

So on the platform this product targets, "the device keeps working while
backgrounded" is not a guarantee that can be made. It is a hope with an API
attached.

## Decision

A run's authoritative execution happens on a server. The device starts runs,
streams them, displays them, and stops them. It is a participant in a run and
never the thing a run depends on.

No run requires the device to be awake, foregrounded, or scheduled by
`BGTaskScheduler` in order to make progress.

The device may still execute steps: in the foreground, and wherever the routing
decision deferred to a later unit chooses local. That is a capability, not the
mechanism that makes a run survive being backgrounded.

## What this does to INV-10

Nothing. INV-10 is about the durability of the record, not the location of the
compute, and the two were being conflated.

The device journals what the device knows — a step dispatched, a step observed
complete, the offset a stream resumed from — before any of it is observable in
the interface. Where the device produces an effect of its own, INV-10 binds that
effect exactly as before. The server keeps its own record; the device's journal
is what lets the device rejoin a run it was absent for.

The demand ADR-0002 makes is met more literally under this decision than under
the alternative. `README.md` promises that coming back means continuing rather
than restarting. With the server executing, the work actually continued while
the app was gone. With the device executing, the work would at most have paused.

## Alternative considered and rejected

Execute on the device across background windows, and raise the deployment target
to iOS 26 so that `BGContinuedProcessingTask` is available.

Rejected on two grounds. It supersedes ADR-0004, which chose iOS 17 to reach
hardware in current use, and that is a product decision this one has no standing
to overturn as a side effect. And it would not deliver the guarantee anyway:
`BGContinuedProcessingTask` grants a system-managed budget with system-managed
termination, so the run still cannot be promised to finish. The alternative
trades a large amount of reach for a weaker version of the same uncertainty.

Worth revisiting if the floor moves for an unrelated reason. It is not worth
moving the floor for.

## Consequences

A server becomes a hard dependency of the product's central promise. Offline
means new runs cannot start, not that running work continues. That is a real
reduction in what the app can claim and it belongs in `README.md` when the
capability lands rather than in a footnote afterwards.

User content leaves the device by default. Whatever is decided about that is a
separate record and has to be made before the first real engine, not after.

The routing decision deferred to a later unit becomes a genuine choice between
two working paths rather than a fallback for when the network is missing. The
Core ML path keeps its reasons — latency, privacy, cost — and loses the one it
never had, which was rescuing a run from suspension.

`UIBackgroundModes` does not gain `audio`, `location` or `voip`. Those are the
modes an app reaches for to stay alive when the platform did not intend it to,
and declaring one is how this decision would be reversed by a setting rather
than by a record. That much is decided here. Which modes the Info.plist does
declare is an open question below, because this record's own reasoning changes
the answer and an earlier draft of this paragraph asserted a set it had no
grounds for.

One claim here is unverified and is marked rather than assumed: that a
background `URLSession` transfer needs no `UIBackgroundModes` entry, only the
delegate hook for resumed sessions. It is checkable once an Xcode project
exists, and `gate-project` is where it should be checked.

## Open questions this record raises and does not answer

Both are named because this record's own reasoning raises them, and because
Info.plist is where each becomes expensive to reverse. Neither is resolved here.

**Whose server.** "The server" above is unqualified, and the two candidates are
different products rather than different deployments of one. Infrastructure this
project runs carries a per-run cost for as long as the product exists, which
points at a usage-capped subscription. A provider the user brings keeps marginal
cost at zero and leaves a one-time purchase open.

The choice also decides what the deferred Core ML path is for. Under a
user-supplied provider it is a routing preference. Under project-run
infrastructure it is a cost-reduction lever. Those are not the same feature and
they would not be built the same way.

It sits against INV-13 as well, added the same day, which says no paid usage.
That invariant is scoped to GitHub Actions. The same sentence applied to the
product points the other way, and a record that decides cost structure should say
that it is doing so rather than let it follow silently.

This record does not decide it, and should not. It belongs in its own ADR, on the
same ground that stopped this one superseding ADR-0004: it decides revenue shape,
and that is not a consequence to inherit from a decision about where compute
happens.

**Which background modes, in both directions.** The Consequences above name what
is not declared and stop short of naming what is, and the reason is that this
record moves the answer both ways.

It removes the argument for `processing`. If the server executes, the device's
background work is journaling and stream-offset reconciliation on resume, which
is sub-second rather than background processing. A background mode whose purpose
the app cannot state is what App Review asks about, and `processing` was carried
over from the assumption this record rejects. Whether `BGTaskScheduler` is used
at all, and so whether `BGTaskSchedulerPermittedIdentifiers` has any entries,
follows from the same question.

In the other direction, if the server pushes run progress for the device to
journal rather than the device reconciling on resume, `remote-notification` is
required, and it appears in no list written here.

Whether progress is pushed or pulled is a design question this record does not
settle, and the two answers need different Info.plist entries. What is asserted
is only that the Info.plist unit 02 writes must not answer either question by
default.
