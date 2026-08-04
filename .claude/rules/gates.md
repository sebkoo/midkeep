# Gates, exit codes, and what the permission rules can and cannot do

For an agent arriving after the harness was built. This is orientation, not
rationale; the arguments are in `docs/adr/`.

## The nine gates

Run them all with `scripts/gates/all.sh`.

| Gate | Enforces | Needs |
|---|---|---|
| `gate-arch.sh` | INV-1, INV-3, INV-5's app-project clause | a checkout and git |
| `gate-hygiene.sh` | INV-2, INV-4, INV-8 | a checkout and git |
| `gate-runners.sh` | INV-13's readable clauses | a checkout and git |
| `gate-hostpath.sh` | INV-14 | a checkout and git |
| `gate-address.sh` | INV-15 | a checkout and git |
| `gate-workflow.sh` | `.github/workflows/*.yml` | `actionlint`, optional |
| `gate-format.sh` | the committed `.swift-format` | the Swift toolchain |
| `gate-build.sh` | INV-5 | the Swift toolchain |
| `gate-test.sh` | INV-7 | the Swift toolchain |

`gate-arch`, `gate-hygiene`, `gate-runners`, `gate-hostpath` and
`gate-address` still reach a verdict on a host with no Swift.
The three toolchain gates return 2 there, and so does `all.sh`. That is the
contract working, not the definition of done.

`gate-workflow` is the one gate whose tool is not a precondition. Without
`actionlint` it returns 2 with a reason, so a fresh clone reports "could not
look" rather than failing. It also runs `shellcheck` over the workflows' `run:`
blocks when `shellcheck` is on `PATH`, and silently skips that when it is not —
so a green here means the schema was checked, and means the shell was checked
only if `shellcheck` was present. The gate says which on stderr.

## The three exit codes

`0` ran and found nothing. `1` ran and found something, findings on stdout as
`path:line: message`. `2` reached no verdict — missing toolchain, unreadable
configuration — reason on stderr.

Never 2 for findings. Never 1 for a tool that could not look. `all.sh` returns
2 if any gate returned 2, else 1 if any returned 1, else 0: a no-verdict
outranks a finding, and a *missing* gate is also 2 with its name on stderr.

Everything on stdout is a finding and nothing else goes there, because
`scripts/gates/teeth.sh` counts findings by path. Commentary belongs on stderr;
`contract.sh` provides `note` for it. Full contract in ADR-0005.

## teeth

`scripts/gates/teeth.sh` proves each gate fails on a planted defect. Twelve
plant cases and one contract case, each in a detached worktree under a temp
directory and never in the checkout. Each case asserts the clean tree exits 0
*before* planting, that the planted tree exits exactly 1 with the expected
findings, and that the worktree is removed either way.

Plants refuse to run anywhere but a worktree `teeth.sh` created. That guard is
an identity check, not a presence check — pointed at this repository it exits 2.

## What the gates actually cover

Less than you would assume, and knowing the boundary matters more than knowing
the gates.

They read `Sources/`, `Tests/`, `Package.swift`, `.swift-format`,
`.github/workflows/*.yml`, commit messages, and — since unit 03 — `App/`
(imports only, by `gate-arch`'s allowlist) and
`Midkeep.xcodeproj/project.pbxproj` (two settings, by grep). They also
read — for exactly two leak shapes, host paths and email addresses — the
prose surface: `docs/`, `CLAUDE.md`, `README.md`, `.claude/` and
`.githooks/`. `App/` is read by no other gate: `gate-hygiene` and
`gate-format` scan `Sources/` and `Tests/`, so INV-2's and INV-4's bans
and the format rule are unenforced in `App/` — the shim is kept to a
handful of lines partly for that reason, and the boundary is recorded in
ROADMAP → Known holes. This paragraph once
counted sixteen paths read by no gate; of those sixteen, thirteen fell
inside the prose gates' scope when INV-14 and INV-15 landed, and three
remain read by nothing: `LICENSE`, `.gitignore` and
`scripts/dev/bootstrap.sh`.

Being read for two shapes is not review. The harness makes changes to
*code* safer and still does much less for prose: INV-11 — that every claim
about what the repository does names the file, script or run behind it —
is UNENFORCED for exactly this reason, and is checked by reading. Of the
three unread paths, `.gitignore` is the one worth singling out, because
git acts on it: a wrong line either commits a per-machine override or
silently hides a tracked path, and no gate would notice either.

If you are changing documentation, every gate but the two prose gates will
stay green, and green from those two means only that no host-path or
address shape appeared — nothing about whether the prose is true. This
file went stale the moment a sixth gate was added, and a review caught it
rather than a check.

## Paths that prompt

`.claude/settings.json` sets `permissions.defaultMode` to `plan`, so a fresh
session on this repository opens in plan mode. Note the nesting: `defaultMode`
is read from *inside* the `permissions` object. Written at the top level as a
sibling of `permissions` it is silently inert, which is where it sat for most of
the session that created this repository without anything noticing.

The same file sets `ask` on `Package.swift`, `docs/adr/**`, `scripts/gates/**`,
`scripts/dev/**`, `.github/workflows/**`, `.githooks/**`, and on `git commit`,
`git push` and `git config core.hooksPath`. It denies `git commit --no-verify`
and `git commit -n`.

It also asks on the irreversible GitHub and history operations: `gh repo delete`,
`gh repo create`, `gh repo edit`, `gh auth refresh`, `git filter-repo`,
`git push --force`, `git push -f`, `git reset --hard`, `git branch -D`,
`git reflog expire` and `git gc`. Until unit 02 those were absent, and a
destructive block ran before the read-only pre-flight that was written to precede
it — which is how the repository's About string and its seven topics were
destroyed with no capture of either.

That is insurance and not a guarantee, for the reason the next section gives: a
rule stops an agent typing a command and does not stop a script file doing the
same thing another way. The guarantee has to be a precondition check inside the
block, asserted rather than written in a comment. The pre-flight that failed
carried its ordering requirement as a comment reading "backups, before anything
destructive" and had no check behind it.

## What the permission rules cannot do

`.claude/` is a protected path. Writes to it prompt in every mode except
`bypassPermissions`, and `permissions.allow` cannot pre-approve them, because
the safety check runs before allow rules are evaluated. A plan to allowlist
those prompts away will not work; this is stated here so it is not rediscovered.

Treat settings as convenience in general. The commit-msg hook and CI are the
enforcement, because a fresh clone has neither until `scripts/dev/bootstrap.sh`
runs. A `deny` rule stops an agent typing a command; it does not stop a script
doing the same thing another way, which is exactly how
`teeth/plant-ai-trailer.sh` plants the trailer it needs.
