# Rigor, Vouch, Stages

A disclosure convention for source code in the AI era. It lets a repository state three
separate things a reader actually wants to know — how much rigor went into the code, whether
the author vouches for depending on it, and the story of who did which stage of the work — in a
small, machine-checkable file at the repo root ([`RIGOR.md`](RIGOR.md)). The three axes are
orthogonal on purpose: code can be fully AI-written and fully rigorous, lightly AI-assisted and
completely unreviewed, or actively maintained and not vouched for. The full convention and the
reasoning behind each level is in [`SPEC.md`](SPEC.md).

<!-- rigor:line -->
> "I have run and skimmed this code, but I have not read it properly. No human has understood it line by line. I make no recommendation either way about depending on it." — [RIGOR.md](RIGOR.md)
<!-- /rigor:line -->

## The `rigor` CLI

A command-line tool that authors, validates, and formats the stamp — and emits the one-line
pointer above. It is plain JavaScript (Node.js >= 18), published as
[`rigor-md`](https://www.npmjs.com/package/rigor-md) — no build step, no toolchain, npx-first.

### Install

No install required — run it with `npx`:

```sh
npx rigor-md validate RIGOR.md --strict --readme README.md
```

Or install it globally:

```sh
npm install -g rigor-md
```

Or wire it into CI as a dev dependency:

```sh
npm install --save-dev rigor-md
npx rigor validate RIGOR.md --strict --readme README.md
```

### Commands

**`rigor init [DIR]`** — scaffold a `RIGOR.md` (default: current directory), writing both the
stamp and the generated plain-language summary. Refuses to overwrite an existing file without
`--force`, and refuses to write a stamp that would not validate.

```sh
rigor init --rigor skimmed --vouch neutral \
  --idea-by human --idea-depth deep \
  --plan-by human-with-ai --plan-depth considered \
  --implementation-by ai \
  --maintenance-by human --maintenance-activity active
```

Flags mirror the stamp fields: `--rigor`, `--vouch`, `--vouch-why` (promotes vouch to the
`{claim, why}` mapping), `--idea-by` / `--idea-depth`, `--plan-by` / `--plan-depth`,
`--implementation-by`, `--maintenance-by` / `--maintenance-activity`, and `--assessed`
(defaults to today; `none` to omit).

**`rigor validate <file> [--strict] [--json] [--readme PATH]`** — validate a stamp: structural
(schema vocabulary, required fields, no unknown keys) plus semantic (a claimed level may not
exceed its surfaced checks, and levels above the comprehension line must show their working).
Also errors if the generated summary has drifted from the stamp. Exit `0` valid, `1` invalid,
`2` usage error.

- Default (non-strict): surfacing only some checks is fine and silent.
- `--strict`: also warns about checks a level implies but that were not surfaced.
- `--json`: machine-readable `{ "valid", "errors", "warnings", "spec_version" }`.
- `--readme PATH`: also check the `<!-- rigor:line -->` block in `PATH` and error if that
  README line disagrees with the stamp.

**`rigor fmt <file>`** — regenerate the summary block from the stamp, in place, so the
human-facing prose can never disagree with the machine-readable YAML.

**`rigor embed <file>`** — print the paste-ready README line: a blockquote of the rigor and
vouch sentences (plus the vouch reason, if any), wrapped in `<!-- rigor:line -->` markers and
linking to `RIGOR.md`. Paste it into your README and keep it honest with
`rigor validate <file> --readme README.md`.

**`rigor schema`** — print the embedded canonical JSON Schema.

### The stamp

`RIGOR.md` is written human-first: a generated summary between markers at the top, free-text
notes in the middle, and the machine-readable stamp — the first fenced `yaml` block after the last
`## Stamp` heading — at the bottom. Two fields are required (`rigor` and `vouch`); everything
else is optional.

```yaml
spec: "0.3"                  # vocabulary version (only "0.3")
rigor: skimmed               # unexamined | skimmed | comprehended | engineered | owned
vouch: {claim: withheld, why: "fine for scripts; never audited for production use"}
                             #   or a bare value — vouch: neutral   (yes | neutral | withheld)
checks:                      # optional; surface any subset, done-values carry the actor
  comprehended: no           #   yes | human | ai | human-with-ai | no | not-applicable
  security_reviewed: ai      #   (comprehended cannot be satisfied by ai alone)
stages:                      # optional; who did each stage, and how deliberately
  idea:           {by: human, depth: deep}          # by: human | human-with-ai | ai
  plan:           {by: human, depth: deep}          # depth: one-shot | considered | deep
  implementation: {by: ai}                          # (idea/plan only take a depth)
  maintenance:    {by: human, activity: dormant}    # activity: active | dormant (maintenance only)
                                                     # maintenance by: also accepts none
assessed: 2026-07-06         # optional; when the stamp was last brought up to date
```

`rigor init` and `rigor fmt` keep the bold plain-language summary at the top of the file in sync
with this block; `rigor validate` rejects the file if they have drifted apart.

## Why it exists

Existing disclosure schemes grade *how much AI* was involved — `none → hint → assist → pair →
auto`, `Assisted-by:` trailers, vibe-coded badges. That question is losing its meaning: AI
assistance is now becoming part of our everyday lives, so "was AI used" now carries about as much
information as "was an editor used." At the same time the old proxies for care have broken. A
fluent README or clean-looking diff used to imply someone put in real work; a one-shot tool now
produces both over code that may be broken, so **polish no longer signals diligence**.

The question a reader still needs answered is not "did a machine touch this" but "can I depend on
this — did someone deliberately work to make it correct and secure, or did someone accept output
that happened to run?" Rigor, Vouch, and Stages exist to make that answerable, and to keep it
honest. The tool does not verify that the claims are true — nothing in a self-report can be
verified — but it does keep them **consistent**: a stamp cannot claim more than the details it
surfaces, and the prose a human reads cannot drift from the data a machine reads. And the
comprehension line (`skimmed` → `comprehended`) marks the break between code nobody has
understood and code a human can account for.

## Why I made this

I open-source things, and I now use AI (LLMs) while coding. Even this idea here was one I 
fleshed out in conversation with an LLM.

So the honest question about any repo of mine is no longer *whether* an LLM was involved,
as at some level it probably was. But the honest question, and what I want people to
understand for their own sake (and mine!), is **how much rigor** I actually
applied to the work, however I did it: did I review it, do I understand it, do I
stand behind it.

Honestly, it isn't much different to the pre-AI era in terms of how I go about things. Sometimes
I put in a lot of care and attention, and other times I don't. I still put code out into public.

The difference with AI is the visibility of where that attention and care lie is harder to
discern. A few years ago, a half-baked script in a repo with no README would obviously not be
worth a second look. But now a similar project might seem feature complete and fully documented
etc, but still not something I'd vouch for.

For a while I worried that the subjective parts did not belong in a format that calls itself
machine-checkable. For example, if I tried to convey how deeply something was thought through by myself,
or whether I had really reviewed it. The first version of rigor therefore tried to focus on more
"objective" assessment. But nothing here was ever objective: "security reviewed" in any README is
a self-report too. So I have decided that the convention does not pretend to measure anything and is purely subjective. 
It is an honesty mechanism, and based on trust. It records who did each stage and how deliberately,
keeps those claims consistent with each other, but leaves believing them to you. 

The trust you have in me decides whether these assessments mean anything at all. You don't have to trust me.
But why would you consider using my projects unless some trust existed.

## Development

```sh
npm install && npm test
```
