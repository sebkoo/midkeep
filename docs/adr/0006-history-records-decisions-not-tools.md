# 6. History records decisions, not tools

Date: 2026-08-01

Status: Accepted

## Context

What is commit metadata for? Two answers are defensible and they lead to
different repositories.

One reads `git log` as **provenance**: a record of how the text came to exist.
Under that reading, noting which tools participated in writing a change is
accurate and useful, in the same way a paper's methods section is.

The other reads it as **accountability**: a record of who can be asked why a
change was made, who can review the follow-up, and who owns it when it turns
out wrong.

## Decision

This repository takes the accountability reading. Commit messages name people
who can answer for the change, and carry no tool attribution of any kind.

The consequence — no `Co-Authored-By` naming an assistant, no `Claude-Session`,
no "Generated with" line — follows from that, and is INV-8.

The argument is not that a tool attribution is false. It is not false; the
generation happened. The argument is that it cannot do the thing every other
line in a commit message does. It cannot answer a question, review the
follow-up, or hold the bug. Everywhere else this repository requires a claim to
name something that can be asked — a file, a script, a run — and a trailer
naming a tool names something that cannot.

## Alternative considered and rejected

Keeping the trailers is a coherent position, held deliberately by projects that
read history as provenance, and it was rejected here rather than refuted. If
the question you expect to ask `git log` in three years is "how was this
written", the trailer is the right answer and removing it destroys information.

This repository expects a different question — "who decided this, and why" —
and answers that one. Someone building a corpus of machine-authored code would
be right to choose the opposite, and would not be making a mistake.

## Why a hook rather than a habit

The gate is not there to settle which reading is correct. It is there because a
history where some commits carry trailers and some do not is worse than either
policy applied consistently: you can no longer tell whether an absent trailer
means a human wrote that commit or means somebody forgot.

Consistency is the property being enforced, and consistency is not what
discipline delivers over twelve commits, let alone over a year of units. That
is also why the rule lives in `.githooks/commit-msg` rather than in
`.claude/settings.json`. A fresh clone gets the hook.

## Where the disclosure actually lives

`docs/prompts/` records, for each unit, what was asked, what was predicted,
what was observed, and what turned out false — dated, with commands anyone can
re-run.

That is more disclosure than a trailer, not less. A trailer says a tool was
involved. The prompt file says what it was told, what it got wrong, and how to
check. This rule is not concealment, and a repository that removed the trailers
without keeping something like `docs/prompts/` would deserve the suspicion.

## The family list has one source

`.githooks/commit-msg` matches on family — `claude`, `anthropic`, `copilot`,
`cursor`, `codex`, `openai`, `gemini` — plus `Claude-Session:` and
`Generated with .*Claude Code`, never a specific model string, so that renaming
a model does not silently disarm the check.

`scripts/gates/gate-hygiene.sh` does not restate that list. It reads it out of
the hook:

```sh
family="$(sed -n "s/^family='\(.*\)'\$/\1/p" .githooks/commit-msg)"
```

This is a decision and not a convenience. The list was retyped by hand three
times during the unit that built this repository and broke three different ways
— alternation that the host's grep might have read literally, a pattern so
broad it flagged the repository's own prose, and a truncation that silently
dropped five of the seven families while every control still passed. One source
of truth removes the class: a family added to the hook is checked
automatically, and a family dropped from the hook stops being claimed.

## Consequences

The check is line-level and will reject a human contributor actually named
Claude, or one whose address is at a domain containing one of the seven tokens.
That is the loud failure direction and the right trade, but it is a real cost
and `docs/ROADMAP.md` carries it under Known holes rather than leaving a
contributor to discover it by being unable to commit.

The hook is local configuration. Anyone can step around it for a single command
with `git -c core.hooksPath=/dev/null commit`, which is exactly what
`scripts/gates/teeth/plant-ai-trailer.sh` does on purpose in order to test the
gate. The hook keeps an honest author honest; CI is the layer a contributor
cannot switch off.
