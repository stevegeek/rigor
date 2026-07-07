// Covers Commands::Fmt.run's CLI-level, file-I/O behavior. Direct
// StampYAML.emit assertions (no CLI/file I/O involved) live in
// test/stamp-yaml.test.js instead, so they are not duplicated here.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { run } from "../src/commands/fmt.js";
import { validate } from "../src/validator.js";
import { MARKER_START } from "../src/summary.js";
import { memoryOut, tempDir } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixture(name) {
  return readFileSync(path.join(__dirname, "fixtures", name), "utf8");
}

describe("Rigor::Commands::Fmt", () => {
  it("regenerates a stale summary in place", () => {
    const dir = tempDir("fmt");
    const p = path.join(dir, "fmt.md");
    writeFileSync(p, fixture("minimal_v2.md").replace("I have read and understood", "STALE"));
    const code = run(p, memoryOut());
    assert.equal(code, 0);
    assert.equal(validate(readFileSync(p, "utf8")).valid, true);
    rmSync(dir, { recursive: true, force: true });
  });

  it("inserts the summary block into a marker-less v0.2 file, and a second run is byte-identical", () => {
    const dir = tempDir("fmt");
    const p = path.join(dir, "fmt.md");
    writeFileSync(p, "# T\n\n## Stamp\n\n```yaml\nrigor: comprehended\nvouch: neutral\n```\n");
    assert.equal(run(p, memoryOut()), 0);
    const once = readFileSync(p, "utf8");
    assert.ok(once.includes(MARKER_START));
    assert.equal(validate(once).valid, true);

    assert.equal(run(p, memoryOut()), 0);
    assert.equal(readFileSync(p, "utf8"), once);
    rmSync(dir, { recursive: true, force: true });
  });

  it("is byte-idempotent on a second fmt run for a mapping-form vouch", () => {
    const dir = tempDir("fmt");
    const p = path.join(dir, "fmt.md");
    writeFileSync(
      p,
      '# T\n\n## Stamp\n\n```yaml\nrigor: skimmed\nvouch: {claim: withheld, why: "fine for scripts, never audited"}\n```\n',
    );
    assert.equal(run(p, memoryOut()), 0);
    const once = readFileSync(p, "utf8");
    assert.ok(once.includes("Why: fine for scripts, never audited"));
    assert.equal(validate(once).valid, true);

    assert.equal(run(p, memoryOut()), 0);
    assert.equal(readFileSync(p, "utf8"), once);
    rmSync(dir, { recursive: true, force: true });
  });
});
