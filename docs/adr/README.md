# Architecture decisions

Numbered records of decisions that constrain later work. The convention is
ADR-0001; the short version is that a record names the situation that forced a
choice, the choice, what it costs, and — where a real alternative existed —
what was set aside and why.

Records are immutable once accepted. A decision that stops holding is
superseded by a new record, and the old one keeps its number and its text.

| # | Decision | Status |
|---|---|---|
| [0001](0001-record-architecture-decisions.md) | Record architecture decisions | Accepted |
| [0002](0002-the-run-is-the-unit-of-persistence.md) | The run is the unit of persistence | Accepted |
| [0003](0003-three-modules-one-direction.md) | Three modules, one direction | Accepted |
| [0004](0004-ios-17-deployment-target.md) | iOS 17.0 as the deployment target | Accepted |
| [0005](0005-gate-exit-code-contract.md) | The gate exit-code contract | Accepted |
| [0006](0006-history-records-decisions-not-tools.md) | History records decisions, not tools | Accepted |
| [0007](0007-the-server-executes-a-run.md) | The server executes a run; the device participates | Accepted |

Two of these carry extended arguments. ADR-0002 is why a step is recorded
before its effect is visible, which is the premise the product rests on.
ADR-0005 is the exit-code contract every check in the repository obeys.

This table is maintained by hand. Nothing in the tree generates it.
