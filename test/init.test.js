// Covers Commands::Init.run: scaffolding a new RIGOR.md stamp.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync, writeFileSync, rmSync } from "node:fs";
import path from "node:path";
import { run } from "../src/commands/init.js";
import { validate } from "../src/validator.js";
import { MARKER_START } from "../src/summary.js";
import { DORMANT_SENTENCE } from "../src/vocabulary.js";
import { memoryOut, tempDir } from "./helpers.js";

describe("Rigor::Commands::Init", () => {
  it("scaffolds a valid human-first v0.2 RIGOR.md", () => {
    const dir = tempDir("init");
    const stages = { idea: { by: "human", depth: "deep" }, implementation: { by: "ai" } };
    const code = run(dir, "skimmed", "neutral", stages, "2026-07-05", false, memoryOut());
    assert.equal(code, 0);
    const text = readFileSync(path.join(dir, "RIGOR.md"), "utf8");
    assert.equal(text.split("\n")[0], "# Who made this, and how carefully");
    assert.ok(text.includes(MARKER_START));
    assert.ok(text.includes("## Notes"));
    assert.ok(text.includes("## Stamp"));
    assert.ok(text.indexOf("## Stamp") > text.indexOf("## Notes"));
    const r = validate(text);
    assert.equal(r.valid, true);
    assert.ok(!r.warnings.join("").includes("spec version"));
    rmSync(dir, { recursive: true, force: true });
  });

  it("still refuses to overwrite without --force", () => {
    const dir = tempDir("init2");
    writeFileSync(path.join(dir, "RIGOR.md"), "x");
    const code = run(dir, "comprehended", "neutral", {}, null, false, memoryOut());
    assert.equal(code, 1);
    rmSync(dir, { recursive: true, force: true });
  });

  it("refuses to scaffold a structurally invalid vocabulary, and writes no file", () => {
    const dir = tempDir("init3");
    const out = memoryOut();
    const code = run(dir, "bogus", "neutral", {}, null, false, out);
    assert.equal(code, 1);
    assert.equal(existsSync(path.join(dir, "RIGOR.md")), false);
    assert.ok(out.toString().includes("error"));
    rmSync(dir, { recursive: true, force: true });
  });

  it("refuses to scaffold an engineered stamp whose checks are not surfaced", () => {
    const dir = tempDir("init4");
    const out = memoryOut();
    const code = run(dir, "engineered", "neutral", {}, null, false, out);
    assert.equal(code, 1);
    assert.equal(existsSync(path.join(dir, "RIGOR.md")), false);
    assert.ok(out.toString().includes("show your working"));
    rmSync(dir, { recursive: true, force: true });
  });

  it("scaffolds a vouch-why + dormant-maintenance RIGOR.md that validates and shows Why: in the summary", () => {
    const dir = tempDir("init5");
    const stages = { maintenance: { by: "human", activity: "dormant" } };
    const code = run(
      dir,
      "skimmed",
      "withheld",
      stages,
      "2026-07-05",
      false,
      memoryOut(),
      "fine for scripts, never audited",
    );
    assert.equal(code, 0);
    const text = readFileSync(path.join(dir, "RIGOR.md"), "utf8");
    const r = validate(text);
    assert.equal(r.valid, true);
    assert.ok(text.includes("Why: fine for scripts, never audited"));
    assert.ok(text.includes(DORMANT_SENTENCE));
    rmSync(dir, { recursive: true, force: true });
  });
});
