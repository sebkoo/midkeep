# 5. The gate exit-code contract

Date: 2026-08-01

Status: Accepted

## Context

A check that cannot run and a check that ran and found nothing are different
facts, and a boolean cannot tell them apart. The distinction matters most
exactly when it is easiest to lose: on a fresh clone with no toolchain, in CI
on a runner that is missing something, in a container where a binary moved. In
all three the tempting answer is to treat "could not run" as "fine" and carry
on, and in all three that is how a repository ends up with a wall of green that
inspected nothing.

## Decision

Every gate exits with one of three codes.

`0` — it ran, and found nothing.

`1` — it ran, and found something. Findings on stdout.

`2` — it reached no verdict. A missing toolchain, an unreadable configuration,
an absent simulator. The reason goes on stderr.

Never `2` for findings, however severe. The mirror also holds and is easier to
get wrong: never `1` for a tool that reached no verdict. A gate whose formatter
configuration will not parse has not found a formatting problem; it has failed
to look.

Two exit codes cannot separate those, because both are non-zero. Only the text
can, so a gate that shells out to a tool inspects the tool's diagnostics: if it
can attribute the failure to a file and a line, that is a finding and the code
is `1`; if it cannot, that is no verdict and the code is `2`.

`scripts/gates/lib/contract.sh` holds the helpers that make this the path of
least resistance — `finding`, `note`, `need`, `die_cannot_run`, and `finish`,
which is the only exit path and normalizes anything outside `{0,1,2}` to `2`.
That normalization is not defensive tidying: `pipefail` turns a `grep | head`
that closes its pipe early into exit 141, and without `finish` a gate would
report a code the contract does not define.

## Alternative considered and rejected

Two codes — pass and fail — is simpler, needs no helper library, and matches
what every shell tool already does.

It was rejected because it makes the most dangerous state indistinguishable
from the safest one. Under two codes a repository has to choose: either a gate
that cannot run reports failure, in which case a fresh clone is red for reasons
that have nothing to do with the code and people learn to ignore it; or it
reports success, in which case a CI runner missing a toolchain produces a green
build that checked nothing. The first is noise and the second is a lie, and
there is no third option inside two codes.

Three codes cost a shared preamble and the discipline of routing findings
through one function. That is the price of being able to say "this ran and was
clean" as a different sentence from "this could not be asked".

## Aggregation

`scripts/gates/all.sh` runs every gate and reduces their codes to one: `2` if
any gate returned `2`, otherwise `1` if any returned `1`, otherwise `0`.

A no-verdict outranks a finding, and that ordering is a decision rather than an
arbitrary tie-break. A run that both found something and could not finish is
neither of those things on its own. Knowing the run was incomplete is worth
more than a finding you could act on, because the finding is still there after
the run is repaired, whereas a `1` reported over an incomplete run invites
someone to fix the one thing that was seen and believe the rest was checked.

A *missing* gate is also `2`, with its name on stderr. This is the part of the
aggregator's contract that is not about arithmetic: a set of gates where one
silently disappears is a harness that proves nothing, and no other check in the
tree would notice. So `all.sh` verifies the set of gates it expects, not only
the codes they return.

Each gate's stdout flows through `all.sh` untouched. The per-gate summary goes
to stderr.

## The findings channel

Everything a gate writes to stdout is a finding, in the form
`path:line: message`, and nothing else goes there. Commentary, banners and
progress belong on stderr, which is why `contract.sh` provides `note`.

The reason is that findings have to be countable from outside the gate. A
harness that plants a defect and asks whether the gate saw it needs stdout to
carry findings and only findings; a gate that prints a banner there breaks
every such case at once.

Paths are repo-relative. On macOS `$PWD` holds the logical path while a
toolchain emits the physical one — `/var/folders` against
`/private/var/folders` — so a gate strips both prefixes. This is in the
contract rather than left to each gate because the two spellings coincide in an
ordinary checkout and diverge only under a temporary worktree, which means the
bug is invisible until precisely the moment the harness runs.

## The tally must survive subshells

`finish` derives its status from how many findings were emitted, and that count
is kept in a file rather than a shell variable. This is part of the contract,
not an implementation note.

In bash the last element of a pipeline runs in a subshell, so a variable
incremented there is discarded when the subshell exits. The natural way to
write a scanning gate is

```sh
grep -n "$pattern" "$file" | while read -r line; do finding ...; done
```

and with a variable-based count that gate prints every finding to stdout and
then exits `0`. Anything reading exit codes believes it. That is the failure
this repository exists to prevent, sitting in the primitive every gate is built
on.

`shopt -s lastpipe` fixes only the pipeline case and only with job control
disabled, leaving explicit subshells broken. A documented rule saying `finding`
must not be called from a pipeline is discipline, which is not relied on
anywhere else here. A file survives every case unconditionally.

The tally is scoped to the process that created it, so gates running in
sequence under `all.sh` never share one and a finding in the first cannot make
the second exit `1`. The scoping is by process id rather than by not exporting
the variable, because "we did not export it" is a property that one careless
line elsewhere could remove.

## The hook protocol

Claude Code's hook protocol inverts the severity of `1` and `2` relative to
this contract. Gates are therefore wrapped when used as hooks and never wired
up directly. A gate reused unwrapped would report its most urgent state as its
least.

## Consequences

Every gate carries a preamble and routes its output through two functions.
That is more ceremony than a shell script usually needs, and it is what makes
`scripts/gates/teeth.sh` possible: a harness can plant a defect, run the gate,
and assert both the exit code and the number of findings attributable to the
file it touched.

The contract earned this on its first full run. `teeth.sh` exited `1` and one
of its two failures was in a gate that had already passed its own
three-direction verification and landed in a commit: findings carried an
absolute path, for the `$PWD` reason above. Per-gate verification could not
have found it, because the divergence exists only once a worktree does. That is
the single result in this unit which could not have been reached by reasoning,
and it is the argument for the harness rather than for the contract alone.
