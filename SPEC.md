# Rigor, Vouch, Stages — spec v0.3

This is my personal convention for stamping my own repositories. It is not a finished standard and I am not asking anyone to adopt it as written. I am publishing it because the disclosure schemes I could find answer a question I have stopped caring about, and none of them answer the one I now care about. If parts of it are useful to you, take them. If you think it is wrong, tell me.

Version 0.3 trims v0.2 rather than expanding it. The short version: the badge is gone — a badge dresses a self-report as a measurement, so it is replaced by a single README line written in my own voice; the subjectivity earlier drafts kept apologizing for is now owned outright, because every value in a stamp always was a self-report and that is the point; `vouch` can carry a reason; and the maintenance stage can say it is dormant-but-still-owned. The v0.2 foundations below are unchanged: the level names carry the meaning (a reader should understand the claim in five seconds, with no spec knowledge), the document is written human-first with the machine block last, the `stages` axis tells the story of the work, and the validator's job is checking *consistency, not truth*. The full changelog is at the end.

## The problem I am trying to solve

Existing schemes grade how much AI was involved. AI-DECLARATION.md runs `none → hint → assist → pair → auto`. The Linux kernel records an `Assisted-by:` trailer. The various badges are binary: vibe-coded or not, AI or no-AI.

That question is becoming useless. AI assistance is now close to universal, so "was AI used" carries almost no information, the same way "was an editor used" tells you nothing about a book. Worse, the old proxies for human care have stopped working. A thorough README used to signal that someone put effort in, because writing good docs was work. A one-shot tool now produces a fluent README over code that may be broken, so polish no longer implies diligence. CodeRabbit's December 2025 comparison of 470 PRs found AI-co-authored changes carried roughly 1.7 times more major issues and nearly three times more XSS vulnerabilities than human-only ones, while looking just as clean. Fluency and rigor have come apart.

So the question I want a reader to be able to answer about my code is not "did a machine touch this." It is: can I depend on this, given that someone deliberately worked to make it correct and secure, or did someone accept output that happened to run. That is independent of whether I trust the author as a person and independent of whether AI was used at all.

Pulling that apart, there are three separate things worth disclosing, and they are not the same kind of thing.

## The three axes

**Rigor** is graded. It measures the deliberate effort applied to make this artifact correct and secure. It is a property of the process applied to the code, not of the author's reputation and not of the tooling. Five levels, `unexamined` through `owned`.

**Vouch** is a three-state speech act. It records whether I am putting my authority behind recommending this code's use, or explicitly withholding it. `yes | neutral | withheld`.

**Stages** is the story of the work: who did each stage (idea, plan, implementation, maintenance), and how deliberately. This is the axis that replaces v0.1's `origin`. The spec always called origin "a short history"; stages are that history grown up. It absorbs both origin's who-authored-it disclosure and the design/specification thinking that v0.1 could only record in free-text notes.

These are orthogonal. Code can be fully AI-written and fully rigorous. It can be lightly AI-assisted and completely unreviewed. It can be actively maintained and not vouched for. Forcing these onto one scale is what makes single-axis schemes lose information, and it is why my earlier drafts had a top level that meant "as good as I would write myself," which on inspection was a vouching claim smuggled onto an effort scale.

## What validation means

The stamp is machine-checkable, and it is worth being precise about what that check does and does not deliver, because it is easy to over-claim.

Validation has two layers, and both are about **form and consistency, not truth**.

**Structural validation** checks form: the stamp is well-formed YAML, the required fields are present, no unknown keys appear, and every value is drawn from its allowed vocabulary. A formal JSON Schema does this.

**Semantic validation** checks the *calculation*. A headline level is a summary of the detail claims underneath it, and the summary may not exceed the details. If you claim `engineered`, you are claiming a security review happened; the validator makes you surface that as a check, and rejects the stamp if the surfaced check contradicts the headline. You cannot state details and a headline that disagree, intentionally or accidentally. You can't tell me it's three while showing one plus one.

Not everything the validator notices stops the stamp from being valid. A structural violation, a contradicted or unsurfaced claim, drift between the summary and the stamp (below), or a README line that disagrees with the stamp are **errors** — the stamp is invalid, full stop. Three other things are **warnings**: they print, but validation still passes. First, a stamp missing `spec:` still validates, with a warning nudging you to add it. Second, when the headline is `engineered` or `owned` and `quality_reviewed` or `security_reviewed` was satisfied by an AI alone, the validator warns — an AI-only review is a different claim from a human one at that level, and it wants you to confirm the review supports the claim or record the human pass. Third, `stages.maintenance.by: ai` (unattended) alongside `engineered` or `owned` warns rather than errors — fully automated maintenance rarely sustains a high level on its own, so the validator flags it for a second look instead of assuming the worst.

What validation explicitly does **not** do is verify that the inputs are true. You may lie about the inputs — write `security_reviewed: human` on code no human ever read — and the stamp will validate. And this holds for *every* value in a stamp, not only the checks: `depth: deep`, `rigor: owned`, `stages.idea.by: human` are all subjective self-reports, and `depth` in particular is kept subjective on purpose rather than dressed up as a measured quantity. The validator's whole job is to keep those self-reports mutually consistent with each other and legible; believing them is the reader's calibration of the author's name, not the tool's job.

I want to state this once, plainly, without apology: *nothing* in open-source self-description is verifiable. "Security-audited" in a README is not verifiable either. What this spec adds is narrower and real — inflation of a claim *relative to your own stated details* is caught mechanically. A false stamp signed with your name still costs you more than it saves, and that is the only enforcement a self-disclosure format can honestly offer.

## Axis 1: Rigor

The rigor level is the headline. The **name is the canonical encoding** everywhere — the stamp, the prose summary, the README line — because `rigor engineered` means something to a reader who has not read this document, while `R3` does not. Tools always emit the name.

| Order | Name | What I am claiming (first-person, canonical) |
|---|---|---|
| 0 | `unexamined` | I have not examined this code. It ran; that is all I claim. |
| 1 | `skimmed` | I have run and skimmed this code, but I have not read it properly. No human has understood it line by line. |
| 2 | `comprehended` | I have read and understood this code; I can explain every line of it. |
| 3 | `engineered` | I understand this code; it was deliberately reviewed for quality and for security, issues found were fixed, and it has tests I trust. |
| 4 | `owned` | I stand behind this code as soundly engineered and hold architectural responsibility for it. |

The sentences above are the spec's actual voice — they are quoted verbatim from what the tool emits into a stamp's plain-language summary.

The break between `skimmed` and `comprehended` is the important one. Everything at `skimmed` and below is code no human has understood line by line. Everything at `comprehended` and above is code a human can account for. This is the **comprehension line**, and it is the single bit to display if you display nothing else.

### Checks — actors, not just booleans

Rigor decomposes into observable checks rather than a feeling of effort. Effort is an internal state that cannot be verified; "did you review this for security" is a claim you can stand behind or be caught not having done. The five checks:

- **comprehended** — a human can explain every line to another person. This is Simon Willison's commit rule, and it is the single threshold that matters most.
- **quality_reviewed** — the code was reviewed for design and correctness, and issues found were acted on.
- **security_reviewed** — the code was checked specifically for security problems. Listed separately on purpose: a correctness review does not catch an injection flaw, and AI-generated code skews toward exactly these defects.
- **tested** — there are tests the human trusts.
- **owned** — the human holds architectural responsibility for it.

In v0.2 each check is not a bare boolean but carries an **actor**. The values are:

```
human | ai | human-with-ai | yes | no | not-applicable
```

`human`, `ai`, and `human-with-ai` all mean "done", with the actor disclosed. `yes` also means done, actor unstated — legal for hand-written terseness and v0.1 compatibility. `no` means not done; `not-applicable` means there is nothing to do here (so "there is nothing to test" is distinct from "I did not test").

The actor matters because **an AI-only review is a different claim than a human review**, and v0.1 collapsed them. `security_reviewed: ai` composes into "reviewed for security (by an AI)"; `security_reviewed: human` into "(by me)". A reader must be able to tell reviewed-by-a-model from reviewed-by-a-person at a glance. One deliberate exception: **comprehended cannot be satisfied by `ai` alone** — an AI comprehending code does not put a human above the comprehension line, so `comprehended` accepts only `yes`, `human`, or `human-with-ai`.

### Show your working

v0.2 adds a rule for claims above the comprehension line. Claiming a high level requires the implied checks to be **surfaced affirmatively**, not merely non-contradicting:

- `unexamined` / `skimmed` — no surfacing required. The terse two-line stamp stays legal; honest low stamps are never punished.
- `comprehended` — implies `comprehended` is `yes`/`human`/`human-with-ai` if surfaced, but does not force you to surface it.
- `engineered` — must surface `comprehended`, `quality_reviewed`, and `security_reviewed` as done, and `tested` as done or `not-applicable`. Omitting any of them is an error: *show your working.*
- `owned` — everything `engineered` requires, plus `owned` as done.

The principle: below the comprehension line, terseness is fine — a low stamp claims little and owes little. Above it, if you are going to claim the work was done, you have to itemize it.

Here is a complete `engineered` stamp that does show its working:

```yaml
spec: "0.3"
rigor: engineered
vouch: yes
checks:
  comprehended: yes
  quality_reviewed: human-with-ai
  security_reviewed: human
  tested: yes
stages:
  idea: {by: human, depth: considered}
  plan: {by: human-with-ai, depth: considered}
  implementation: {by: human-with-ai}
  maintenance: {by: human}
```

Drop the `checks:` block entirely and this same stamp becomes invalid: claiming `engineered` implies `comprehended`, `quality_reviewed`, `security_reviewed`, and `tested` all happened, and the validator will not take that on faith — it is exactly the "show your working" error above that catches the gap.

## Axis 2: Vouch

Vouch is a speech act, not a measurement. It answers whether I am willing to put my name behind recommending this for use.

```
vouch: yes | neutral | withheld
```

- **yes** — "I recommend this for use; I put my name behind it." Displayed as **vouched**.
- **neutral** — "I make no recommendation either way about depending on it." Displayed as **no vouch**.
- **withheld** — "I am specifically not recommending you depend on this." Displayed as **vouch withheld**.

A vouch may also carry a reason. Write it as a mapping instead of a bare value:

```yaml
vouch: {claim: withheld, why: "fine for scripts; never audited for production use"}
```

`claim` is required and takes the same three values; `why` is optional free text. The summary renders it verbatim as a trailing sentence — `Why: fine for scripts; never audited for production use` — immediately after the vouch sentence, so the reason travels with the claim wherever the sentences go, in both `RIGOR.md` and the README line. The bare scalar form is unchanged, and the two-line stamp still works.

This is independent of rigor. I can hold a high rigor level on code I will not vouch for, and I can vouch on the strength of experience for code I have not formally reviewed.

GitHub already has a crude version of this. Archiving a project, or adding a "no longer maintained" line to the README, is a way of saying "I no longer vouch for using this." But archiving fuses three different messages: I stopped maintaining, I no longer vouch for it, and it is now frozen. The `withheld` state separates the vouching from the maintenance status. It lets me keep a project live and in use while declining to tell anyone they should trust it, which archiving cannot express.

## Axis 3: Stages

The work is told as a short history — who did each stage, and how deliberately. This replaces v0.1's `origin` block, which could only record who authored and who maintains; stages add the design/specification thinking that used to be lost in free text.

```yaml
stages:
  idea:           {by: human,         depth: deep}
  plan:           {by: human-with-ai, depth: considered}
  implementation: {by: ai}
  maintenance:    {by: human, activity: active}
```

The four stages:

- **idea** — why this exists; the thinking behind it.
- **plan** — the specification, the details of what would be built.
- **implementation** — writing the code.
- **maintenance** — who drives changes now.

Two fields, both optional within any stage:

- **`by`** — one actor vocabulary, shared with the checks: `human | human-with-ai | ai`, plus `none` on `maintenance` only ("no one maintains this").
- **`depth`** — `one-shot | considered | deep`. Meaningful for `idea` and `plan`. The `implementation` and `maintenance` stages take no depth — implementation's depth *is* the rigor level and its checks.

The `maintenance` stage takes one more optional field:

- **`activity`** — `active | dormant`, on `maintenance` only. Absent means unstated, which is today's behavior. `dormant` is for a project that is finished but still owned; it composes into "Nothing has needed changing lately; I still use this and would respond if it broke." That is a deliberately different claim from `by: none` ("no one maintains this"), so the two do not combine — `activity` alongside `by: none` is a semantic error.

Everything is optional: any subset of stages, any field within a stage. The two-line minimal stamp survives untouched.

The stages compose, chronologically, into the plain-language summary. The sentences the tool emits:

- **idea / plan `by`** — "The idea was mine." / "…was mine, developed with an AI." / "…was an AI's." (and likewise for "The plan").
- **depth** — appended when `by` is present: "…and was taken as it first came" (`one-shot`) / "…and was thought through" (`considered`) / "…and was worked in depth, over iterations" (`deep`). When `by` is absent the depth stands alone: "The idea was worked in depth, over iterations."
- **implementation `by`** — "The implementation was written by me." / "…written by me with an AI." / "…generated by an AI."
- **maintenance `by`** — "A human drives changes today." / "Changes are made by an AI with a human in the loop." / "Changes are made by an AI unattended." / "No one maintains this."
- **maintenance `activity: dormant`** — replaces the `by` sentence with "Nothing has needed changing lately; I still use this and would respond if it broke."

## The file

The stamp lives in a `RIGOR.md` file at the repo root. v0.2 inverts v0.1's layout: the file is **human-first, machine-last**. Humans read from the top; machines read from the end.

````markdown
# Who made this, and how carefully

<!-- rigor:summary -->
**The idea was mine and was worked in depth, over iterations. The plan was mine and was worked in depth, over iterations. The implementation was generated by an AI. I have run and skimmed this code, but I have not read it properly. No human has understood it line by line. It was reviewed for quality (by an AI), reviewed for security (by an AI) and tested (by an AI). A human drives changes today. This assessment is as of 2026-07-03. I make no recommendation either way about depending on it.**
<!-- /rigor:summary -->

## Notes

(author free text — why the level is what it is, what was and was not checked)

## Stamp

```yaml
spec: "0.3"
rigor: skimmed
vouch: neutral
checks:
  comprehended: no
  quality_reviewed: ai
  security_reviewed: ai
  tested: ai
stages:
  idea:           {by: human, depth: deep}
  plan:           {by: human, depth: deep}
  implementation: {by: ai}
  maintenance:    {by: human}
assessed: 2026-07-03
```
````

Three parts, in order:

1. **The generated summary**, between `<!-- rigor:summary -->` and `<!-- /rigor:summary -->` markers. This bold paragraph is *generated from the stamp* by `rigor init` / `rigor fmt`; it is composed from the same first-person sentences the README line draws on. Its composition is chronological — idea → plan → implementation rigor → notable checks with their actors → maintenance → assessment → vouch last — so it reads as the story of the work.
2. **`## Notes`** — free text, unchanged in role. Whatever a reader should know that the summary cannot carry.
3. **`## Stamp`** — the machine-readable truth: the first fenced ` ```yaml ` block after the **last** `## Stamp` heading in the file.

Two fields are required: `rigor` and `vouch`. Everything else — including `spec` — is optional, and the minimal stamp is genuinely two lines:

```yaml
rigor: comprehended
vouch: neutral
```

Omitting `spec:` does not invalidate the stamp; it only draws a warning nudging you to add it, so the terse form above stays legal on its own.

Two new optional top-level fields:

- **`spec: "0.3"`** — the vocabulary version this stamp is written against.
- **`assessed: YYYY-MM`** (or `YYYY-MM-DD`) — when the stamp was last brought up to date. Composes into "This assessment is as of 2026-07-03."

### The drift rule

Because the summary is derived from the stamp, the two can never be allowed to disagree. `rigor validate` re-derives the summary from the YAML and **errors on drift**: if the bold paragraph a human reads does not match the stamp a machine reads, the file is invalid. Run `rigor fmt` to regenerate. This is what makes the human-first layout safe — the prose at the top cannot quietly lie about the data at the bottom.

### The README line

A repository's README wants a one-line pointer to the stamp. Earlier drafts put a badge there; v0.3 removes it. A badge dresses a self-report as a measurement — a coloured sticker reading "skimmed" invites the reader to parse it the way they parse "88% coverage", which is exactly the category error this whole convention exists to undo. A sentence in the author's own voice is the honest artifact: it cannot be mistaken for a metric because it reads as what it is, a claim someone is making.

`rigor embed <file>` emits that line — a blockquote of the rigor sentence and the vouch sentence (plus the vouch `why`, if there is one), linking to `RIGOR.md`:

```markdown
<!-- rigor:line -->
> "I have run and skimmed this code, but I have not read it properly. No human has understood it line by line. I make no recommendation either way about depending on it." — [RIGOR.md](RIGOR.md)
<!-- /rigor:line -->
```

The `<!-- rigor:line -->` … `<!-- /rigor:line -->` markers are optional, and they extend the drift rule to the README. `rigor validate <file> --readme README.md` re-derives the line and **errors** if the marked block disagrees with the stamp, exactly as it does for the summary block. An unmarked, hand-written pointer is fine and goes unchecked — the drift guarantee is opt-in, and it is what lets a README quote the stamp without risking a quiet lie.

## Changelog: v0.2 → v0.3

v0.3 trims rather than grows. Nothing in the vocabulary above is new; several things are gone.

- **The badge is retired.** No `badge.svg`, no infobox, no colour semantics, no `rigor badge`, no `rigor serve`. A badge implied a measurement, and a self-report is not one. In its place, `rigor embed` emits a single README line in the stamp's own voice — the rigor and vouch sentences, linking to `RIGOR.md` — and the drift rule now covers it through the optional `<!-- rigor:line -->` markers.
- **Subjectivity is owned, not apologized for.** The spec no longer implies anywhere that any value was ever objective. Every value in a stamp — `depth`, `rigor`, the stage `by`s, the checks — is a subjective self-report; the validator keeps them consistent with each other and legible, and does nothing more. `depth` stays exactly as it was; it was never a measured quantity, and it is no longer pretended to be one.
- **Vouch can carry a reason.** `vouch` accepts a `{claim, why}` mapping; `why` renders as a trailing "Why: …" sentence after the vouch sentence. The bare scalar form is unchanged.
- **Maintenance can be dormant.** `stages.maintenance.activity: active | dormant`; `dormant` says "finished but still owned," a distinct claim from `by: none`, and the two cannot be combined.
- **`spec` is now `"0.3"` only.** The enum accepts a single value; there is no v0.2 compatibility mode.

The tool is implemented in plain JavaScript (npm package `rigor-md`, run via npx), which replaced the original Crystal implementation after a byte-parity gate. That was an implementation change, not a change to this spec — the vocabulary and validation rules above are the contract, whatever binary enforces them.

## Changelog: v0.1 → v0.2

- **Names are canonical, and two were renamed.** `surface` → `skimmed`, `none` → `unexamined`; the top three names are unchanged. Names lead everywhere and are the only accepted vocabulary.
- **The document was inverted.** v0.1 put YAML frontmatter first and prose after. v0.2 puts a generated human summary first, notes in the middle, and the machine stamp last under `## Stamp`.
- **Checks carry actors.** `human | ai | human-with-ai` join `yes | no | not-applicable`, so an AI review is no longer visually identical to a human one.
- **Stages replace origin.** A four-stage history (idea / plan / implementation / maintenance) with `by:` and optional `depth:` absorbs both `origin` and the design-thinking axis v0.1 had cut. v0.1 stamps and their origin block are not parsed; the mapping was: authored human-crafted/ai-assisted/ai-generated → implementation.by human/human-with-ai/ai; maintenance human-led/ai-led/ai-auto → maintenance.by human/human-with-ai/ai.
- **Show your working.** Levels above the comprehension line must surface their implied checks affirmatively, not merely avoid contradicting them.
- **Validation reframed as consistency, not truth** — with the calculation framing above, and no more hand-wringing about gameability.
- **Badge redesign.** Legible level names, an "· AI-reviewed" qualifier when a review check is an AI's, plain-word vouch labels (`vouched` / `no vouch` / `vouch withheld`), and a neutral slate palette below the line so an honest low stamp never looks like a warning.
- **New fields.** `spec` (vocabulary version) and `assessed` (date last brought up to date).
- **New command.** `rigor fmt` regenerates the summary from the stamp.
- **v0.2 drops v0.1 parsing entirely** — no frontmatter stamps, no R-code or none/surface aliases, no migration tooling.

## Open questions

Things I have not settled and would discuss:

- **Evidence links.** Optional fields pointing at CI runs, review PRs, or audit reports. Attractive, but they push toward a verifiability claim this spec deliberately does not make; still deferred.
- **Per-path scope.** One root stamp describes a whole repo today. A large repo may have a hand-owned core and a generated periphery; per-directory scoping is real but unbuilt. The stages axis absorbs the most common split (design vs implementation) for now.
- **Agent-authored stamps.** A contract for an agent to draft or update its own stamp honestly, the way it already drafts a commit message.
- **Fence-aware scanning.** The stamp scanner is a line scanner by design, so pathological input cannot trigger catastrophic backtracking; teaching it to see nested code fences is deferred rather than rejected.
- **Account-level rollup / discoverability.** A way to see one author's stamps together, without turning the convention into a ranking.
- Whether the idea/plan boundary is worth its fuzziness. It is softer than the plan/implementation boundary; mitigated for now by every stage and field being optional.
