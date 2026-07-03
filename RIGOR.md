---
rigor: surface
checks:
  comprehended: no
  quality_reviewed: yes
  security_reviewed: yes
  tested: yes
  owned: no
vouch: neutral
origin:
  authored: ai-generated
  maintenance: human-led
---

# Rigor, Vouch, Origin

This repository is stamped **R1 (surface)**: the code has been run, tested, and reviewed by an
AI, but no human has comprehended it line by line.

## Notes

The split here is deliberate and is exactly the kind of thing this convention exists to make
legible. The **specification** (`SPEC.md`) (the problem framing, the three-axis model, the
reasoning behind each level) was designed in depth with the human. Ie the human expended
effort on the underlying idea. However, the **implementation** (of the CLI tool, and writing 
of the docs) was delegated in full to an AI (`origin.authored: ai-generated`) and the human has 
only glanced at it superficially, hence `comprehended: no`.

What raises this above R0:

- **quality_reviewed / security_reviewed: yes** — the implementation was put through a dedicated
  quality review and a dedicated security review (both AI-performed). Real findings were acted
  on: a validation bug where a non-mapping `checks:` block was silently accepted; a YAML
  anchor/alias "billion laughs" memory-exhaustion vector; a frontmatter-regex crash on
  pathological input; and hardening of the `serve` bind default. All fixes carry regression
  tests.
- **tested: yes** — a full `crystal spec` suite covering the validator semantics, rendering,
  embedding, the HTTP service, and the above regressions.

Because the human has not comprehended the code and the author is not claiming others should 
be using this, `vouch` is **neutral**. No recommendation is made either way on its use by 3rd
parties. And `owned` is **no** as the human author does not take architectural responsibility. 

