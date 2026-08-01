# 1. Record architecture decisions

Date: 2026-08-01

Status: Accepted

## Context

Decisions made early in a repository are the ones least visible later. The code
shows what was chosen; it does not show what else was on the table, or why the
alternative was set aside. Six months on, an option that was considered and
rejected for a good reason looks identical to an option nobody thought of, and
the second gets re-proposed while the first stays rejected for reasons nobody
can reconstruct.

## Decision

Every decision that constrains later work gets a numbered record here.

A record is a file named `NNNN-kebab-case-title.md`, numbered in the order
accepted, carrying a date, a status, and three sections: the situation that
forced a choice, the choice, and what it costs. Where a real alternative
existed, the record names it and says why it was set aside — an ADR that can
only describe the option it took has not documented a decision.

Records are immutable once accepted. A decision that stops holding is
superseded by a new record that says so, and the old one keeps its number and
its text. Editing an accepted record to match current practice destroys the
only thing it was written to preserve.

Status is one of Accepted, Superseded by ADR-NNNN, or Rejected. A rejected
record is worth keeping when the rejection itself is the useful information.

Two of these are long, and deliberately so. ADR-0002 argues why a step is
recorded before its effect is visible, which is the premise the whole product
rests on. ADR-0005 argues the gate exit-code contract, which every check in the
repository obeys. The rest are short because the decisions are small.

## Consequences

Adding a constraint costs a file. That is intentional friction: a rule nobody
was willing to write down is a rule nobody will be able to defend.

The index at `docs/adr/README.md` lists every record. It is maintained by hand
and says so, because nothing in the tree generates it.

This convention describes decisions, not history. What was asked, what was
predicted, what was observed and what turned out false is recorded per unit in
`docs/prompts/`, which is a different kind of record and is not a substitute
for this one.
