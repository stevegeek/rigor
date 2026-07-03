# Rigor, Vouch, Origin

A disclosure convention for source code in the AI era. It lets a repository state three
separate things a reader actually wants to know, in a small machine-checkable file at the repo
root ([`RIGOR.md`](RIGOR.md)):

- **Rigor** — a graded measure (R0–R4) of the deliberate effort applied to make the code
  correct and secure: whether a human comprehended it, whether it was reviewed for quality and
  for security, whether it is tested, and whether someone holds architectural responsibility
  for it.
- **Vouch** — a three-state speech act (`yes` / `neutral` / `withheld`): whether the author puts
  their name behind recommending the code's use, independent of how it was built.
- **Origin** — a short provenance history: how the code was first authored (`human-crafted` /
  `ai-assisted` / `ai-generated`) and who drives changes now (`human-led` / `ai-led` /
  `ai-auto`).

The three axes are orthogonal on purpose. Code can be fully AI-written and fully rigorous; it
can be lightly AI-assisted and completely unreviewed; it can be actively maintained and not
vouched for. The full convention, its levels, and the reasoning behind each is in
[`SPEC.md`](SPEC.md).

## Why it exists

Existing disclosure schemes grade *how much AI* was involved — `none → hint → assist → pair →
auto`, `Assisted-by:` trailers, vibe-coded badges. That question is losing its meaning: AI
assistance is now becoming part of our everyday lives, so "was AI used" now carries about as much
information as "was an editor used." At the same time the old proxies for care have broken. A
fluent README or clean-looking diff used to imply someone put in real work; a one-shot tool now
produces both over code that may be broken, so **polish no longer signals diligence**.

The question a reader still needs answered is not "did a machine touch this" but "can I depend
on this and did someone deliberately work to make it correct and secure. Or did someone accept
output that happened to run." Rigor, Vouch, and Origin exist to make that answerable, and to
keep it honest: the format is machine-validated, and the comprehension line (R1 → R2) marks the
break between code nobody has understood and code a human can account for.

## Why I made this

I open-source things, and I now use AI (LLMs) while coding.

This whole idea here is an idea I worked out in conversation with an LLM too.

So the honest question about any repo of mine is no longer *whether* an LLM was involved,
as at some level it probably was. But the honest question, and what I want people to 
understand for their own sake (and mine!) is how much rigor I actually 
applied to the work, however I did it: did I review it, do I understand it, do I
stand behind it.

Honestly, it isn't much different to the pre-AI era in terms of how I go about things. Sometimes
I put in a lot of care and attention, and other times I don't. I still put code out into public.

The difference with AI is the visibility of where that attention and care lie is harder to 
discern. A few years ago, a half-baked script in a repo with no README would obviously not be 
worth a second look. But now a similar project might seem feature complete and fully documented
etc, but still not something I'd vouch for.

In an earlier draft tried to also grade how much thinking went into the design and speccing
of the project, but that turned out to be unverifiable and subjective, so it was cut. 

What is left aims to be more dependable than a vibe or a polished README 
So be honest about which parts of the work were mine, which were the model's, and how the two meshed. 

Ie the point is how much rigor went into the work.

It is a personal convention, not a finished standard.

## The `rigor` CLI

A command-line tool that authors, validates, renders, and serves the stamp. It is written in
Crystal and compiles to a native binary.

### Build

```sh
shards install
shards build --release      # produces ./bin/rigor
```

### Commands

**`rigor init [DIR]`** — scaffold a `RIGOR.md` (default: current directory). Refuses to overwrite
an existing file without `--force`.

```sh
rigor init --rigor R2 --vouch neutral --authored ai-assisted --maintenance human-led
```

**`rigor validate <file> [--strict] [--json]`** — validate a stamp: structural (schema
vocabulary, required fields, no unknown keys) plus semantic (a claimed level may not contradict a
surfaced check). Exit `0` valid, `1` invalid, `2` usage error.

- Default (non-strict): surfacing only some checks is fine and silent.
- `--strict`: also warns about checks a level implies but that were not surfaced.
- `--json`: machine-readable `{ "valid", "errors", "warnings" }`.

**`rigor badge <file> [--infobox] [-o out.svg]`** — render an SVG badge (or the larger
`--infobox`) to stdout or a file. `--params "rigor=R4&vouch=yes"` renders from a query string
instead of a file.

**`rigor embed <file> [--base URL]`** — emit paste-ready README markdown (badge + infobox) plus
the generated alt text. `--base` sets the badge-service origin in the generated URLs.

**`rigor serve [--port 8080] [--bind 127.0.0.1] [--base URL]`** — run the badge HTTP service:
`/badge.svg?…`, `/infobox.svg?…`, and `/r?…` (a human page). Each response is a pure function of
the query string and carries `ETag` + long `Cache-Control`, so it sits behind a reverse proxy /
CDN. Binds to loopback by default; widen exposure with `--bind`.

**`rigor schema`** — print the embedded canonical JSON Schema.

### The stamp

`RIGOR.md` is YAML frontmatter followed by a prose body. Two fields are required; everything else
is optional:

```markdown
---
rigor: engineered          # R0..R4 or none/surface/comprehended/engineered/owned
vouch: yes                 # yes | neutral | withheld
checks:                    # optional; surface any subset
  security_reviewed: yes
origin:                    # optional
  authored: ai-assisted    # human-crafted | ai-assisted | ai-generated
  maintenance: human-led   # human-led | ai-led | ai-auto
---
```

## Development

```sh
crystal spec        # run the test suite
```
