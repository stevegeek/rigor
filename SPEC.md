# Rigor, Vouch, Origin: a disclosure convention for AI-era code

This is my personal convention for stamping my own repositories. It is not a finished standard and I am not asking anyone to adopt it as written. I am publishing it because the disclosure schemes I could find answer a question I have stopped caring about, and none of them answer the one I now care about. If parts of it are useful to you, take them. If you think it is wrong, tell me.

## The problem I am trying to solve

Existing schemes grade how much AI was involved. AI-DECLARATION.md runs `none → hint → assist → pair → auto`. The Linux kernel records an `Assisted-by:` trailer. The various badges are binary: vibe-coded or not, AI or no-AI.

That question is becoming useless. AI assistance is now close to universal, so "was AI used" carries almost no information, the same way "was an editor used" tells you nothing about a book. Worse, the old proxies for human care have stopped working. A thorough README used to signal that someone put effort in, because writing good docs was work. A one-shot tool now produces a fluent README over code that may be broken, so polish no longer implies diligence. CodeRabbit's December 2025 comparison of 470 PRs found AI-co-authored changes carried roughly 1.7 times more major issues and nearly three times more XSS vulnerabilities than human-only ones, while looking just as clean. Fluency and rigor have come apart.

So the question I want a reader to be able to answer about my code is not "did a machine touch this." It is: can I depend on this, given that someone deliberately worked to make it correct and secure, or did someone accept output that happened to run. That is independent of whether I trust the author as a person and independent of whether AI was used at all.

Pulling that apart, there are three separate things worth disclosing, and they are not the same kind of thing.

## The three axes

**Rigor** is graded. It measures the deliberate effort applied to make this artifact correct and secure. It is a property of the process applied to the code, not of the author's reputation and not of the tooling.

**Vouch** is a three-state flag. It records whether I am putting my authority behind recommending this code's use, or explicitly withholding it.

**Origin** is a short history. It records how the code was first authored and how it is maintained now, so a reader can see when those differ.

These are orthogonal. Code can be fully AI-written and fully rigorous. It can be lightly AI-assisted and completely unreviewed. It can be actively maintained and not vouched for. Forcing these onto one scale is what makes single-axis schemes lose information, and it is why my earlier drafts had a top level that meant "as good as I would write myself," which on inspection was a vouching claim smuggled onto an effort scale.

## Axis 1: Rigor

Rigor decomposes into observable checks rather than a feeling of effort. This matters because effort is an internal state that cannot be verified, whereas "did you review this for security" is a claim you can stand behind or be caught not having done. The decomposition follows the dimension IBM's 2025 attribution research found people actually reach for when assigning credit (who reviewed and approved the work), reframed around the specific checks that make code dependable.

The checks:

- **Comprehended.** The human can explain every line to another person. This is Simon Willison's commit rule, and it is the single threshold that matters most.
- **Quality reviewed.** The code was reviewed for design and correctness, and issues found were acted on.
- **Security reviewed.** The code was checked specifically for security problems. This is listed separately on purpose. A correctness review does not catch an injection flaw, and AI-generated code skews toward exactly these defects.
- **Tested.** There are tests the human trusts.
- **Owned.** The human holds architectural responsibility for it.

The levels are a shorthand for how many of these genuinely hold:

| Level | Name | Meaning |
|---|---|---|
| **R0** | none | Produced or changed and accepted without any of the checks. "Works for me, I have not looked." |
| **R1** | surface | Run and glanced at, possibly self-reviewed by an AI, but no human comprehension. Below the comprehension line. |
| **R2** | comprehended | The human understands and can explain every line. Basic review done. This is the trust threshold. |
| **R3** | engineered | Comprehension plus deliberate quality review and security review, with issues fixed and tests present. |
| **R4** | owned | R3 plus architectural ownership and iterated review rounds. The human stands behind it as soundly engineered. |

Each level has a code (`R0` to `R4`) and a name (`none` to `owned`). The name is what badges and prose lead with, because `rigor engineered` means something to a reader who has not read this document while `R3` does not. The code is the canonical key used in data, URLs, and validation, because it is short, sorts cleanly, and never changes. A stamp may be written either way: `rigor: engineered` and `rigor: R3` are equivalent, and the combined `R3 engineered` form is also accepted. Tools normalize to the code internally and display the name.

The break between R1 and R2 is the important one. Everything at R1 and below is code nobody has understood. Everything at R2 and above is code a human can account for. If you display nothing else, display whether you are above or below that line.

### Encoding

The stamp lives in a `RIGOR.md` file at the repo root, as YAML frontmatter followed by a prose body. The frontmatter is the machine-readable truth; the body is for human readers and the parser ignores it.

```markdown
---
rigor: engineered
checks:
  comprehended: yes
  quality_reviewed: yes
  security_reviewed: yes
  tested: not-applicable
  owned: yes
vouch: yes
origin:
  authored: ai-assisted
  maintenance: human-led
---

# Rigor, Vouch, Origin

A one-line restatement for anyone reading the file directly.

## Notes
Free text. Why the level is what it is, what was and was not checked,
anything a reader should know.
```

Two fields are required: `rigor` and `vouch`. Everything else is optional. The `rigor` value may be a name or a code. The smallest valid stamp is:

```markdown
---
rigor: comprehended
vouch: neutral
---
```

The `checks` block is optional, and any subset of the five checks may appear. Each check is `yes`, `no`, or `not-applicable` (the third state exists so "there is nothing to test here" is distinct from "I did not test"). Surfacing `security_reviewed` is recommended even when the others are omitted, because it is the check most often skipped and the one a reader most needs.

Frontmatter is used rather than prose-embedded values for one reason: syntax can be enforced. A malformed block fails to parse before any meaning is evaluated, and a formal schema can reject bad vocabulary. Loose prose cannot give you that, so a typo would pass silently. The format is deliberately shallow (two levels at most) to stay readable and hand-writable.

### Validation

Validation has two layers. Structural validation, defined by a JSON Schema (`rigor.schema.json`, which validates YAML), checks that the block is well-formed, the required fields are present, no unknown keys appear, and every value is in its allowed set. Semantic validation checks the cross-field rules the schema cannot cleanly express, chiefly that a claimed level is consistent with any surfaced checks: a document claiming `R3` while showing `security_reviewed: no` is rejected, because R3 means a security review was done.

Errors block validity. Warnings are surfaced without blocking, for deliberate edge cases. A high level under `maintenance: ai-auto`, for instance, is allowed but warned, since fully automated maintenance rarely sustains a high rigor level and the author should confirm the level reflects the most recent changes.

A note on what validation does and does not deliver. Well-formed YAML guarantees the document parses; the schema guarantees it uses real values; the semantic layer guarantees the level and checks agree. None of that can verify the claim is true. An author can write `rigor: R4` on unreviewed code and it will validate. Syntax and schema enforce form and vocabulary, not honesty. The honesty question is left to the trust-calibration framing: this is a signal a reader weighs, not a guarantee, and a false stamp signed with your name costs you more than it saves.

## Axis 2: Vouch

Vouch is a speech act, not a measurement. It answers whether I am willing to put my name behind recommending this for use.

```
Vouch: yes | neutral | withheld
```

- **yes**: I recommend depending on this.
- **neutral**: I make no recommendation either way.
- **withheld**: I am actively withholding my recommendation, even if I still use it myself.

This is independent of rigor. I can hold a high rigor level on code I will not vouch for, and I can vouch on the strength of experience for code I have not formally reviewed.

GitHub already has a crude version of this. Archiving a project, or adding a "no longer maintained" line to the README, is a way of saying "I no longer vouch for using this." But archiving fuses three different messages: I stopped maintaining, I no longer vouch for it, and it is now frozen. The `withheld` state separates the vouching from the maintenance status. It lets me keep a project live and in use while declining to tell anyone they should trust it, which archiving cannot express.

## Axis 3: Origin

Origin is a small history, because a single number cannot describe code whose effort profile changed over its life.

```
Origin:
  authored: human-crafted | ai-assisted | ai-generated
  maintenance: human-led | ai-led | ai-auto
```

`authored` is how the code was first written. `maintenance` is who drives changes now. The rigor level always describes the most recent significant changes, so reading the three together shows the trajectory.

Two cases this is built to handle:

Code hand-crafted before AI, now edited automatically by an agent without human review, reads as `authored: human-crafted, maintenance: ai-auto, Rigor: R0`. The mismatch between a high-effort origin and a low current rigor under automated maintenance is the alarm. A single score would hide it.

Code written with AI but reviewed and owned exactly as rigorously as the author always worked reads as `authored: ai-assisted, maintenance: human-led, Rigor: R4`. This says the tooling changed and the rigor did not, which binary AI disclosure destroys by lumping it in with unreviewed AI output.

## Putting it together

A complete stamp:

```markdown
---
rigor: R4
checks:
  security_reviewed: yes
vouch: yes
origin:
  authored: ai-assisted
  maintenance: human-led
---
```

The minimum is two required fields:

```markdown
---
rigor: R2
vouch: neutral
---
```

## Relationship to other schemes

This is meant to sit alongside the AI-involvement schemes, not replace them. AI-DECLARATION.md and the `Assisted-by:` trailer answer "how much AI." This answers "how much human rigor, do I vouch for it, and how has that changed." A repo can carry both an AI-involvement declaration and this one, and the pair says more than either alone: `auto / R4` is fully AI-written and fully human-rigorous, while `assist / R0` is lightly AI-assisted and unreviewed.

The grounding for the rigor decomposition is He, Houde and Weisz, "Which Contributions Deserve Credit? Perceptions of Attribution in Human-AI Co-Creation" (CHI 2025), which found human review and effort to be the dominant intuition behind credit, and the human-automation levels literature (Parasuraman, Sheridan and Wickens, 2000), which grades human oversight directly rather than machine capability. The comprehension threshold is Willison's. The vouch axis generalizes what GitHub archiving already does informally.

## Open questions

Things I have not settled and would discuss:

- The rigor level is an independent assertion, not strictly derived from the checks, but the validator enforces a one-way consistency: a level may not contradict a surfaced check (R3 with `security_reviewed: no` is rejected), while a conservative level below what the checks would support is allowed. Open question is whether the implied-but-unsurfaced-check case should warn more loudly than it currently does.
- Whether `maintenance` needs more than three values to capture mixed human and agent workflows.
- Whether vouch should carry a reason field, or whether that belongs in free-text notes.
- Whether any of this survives contact with the fact that all self-disclosure is unverifiable and gameable. My answer for now is that it is a trust-calibration signal for readers, not a guarantee, and that signing my name to a false stamp costs me more than it saves.
