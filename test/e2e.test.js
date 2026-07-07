// Covers the CLI end to end: command dispatch, flag parsing, and exit codes.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { run } from "../src/cli.js";
import { LINE_MARKER_START, LINE_MARKER_END } from "../src/summary.js";
import { memoryOut, tempDir } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixturePath(name) {
  return path.join(__dirname, "fixtures", name);
}

describe("end to end via CLI.run", () => {
  it("validate → 0, embed → README line block", () => {
    assert.equal(run(["validate", fixturePath("full_r3.md")], memoryOut()), 0);
    const out = memoryOut();
    run(["embed", fixturePath("full_r3.md")], out);
    const text = out.toString();
    assert.ok(text.includes(LINE_MARKER_START));
    assert.ok(text.includes(LINE_MARKER_END));
    assert.ok(text.includes("Paste into your README"));
  });

  it("returns 2 on unknown command and 1 on invalid document", () => {
    assert.equal(run(["frobnicate"], memoryOut()), 2);
    const dir = tempDir("bad");
    const bad = path.join(dir, "bad.md");
    writeFileSync(bad, "no frontmatter");
    assert.equal(run(["validate", bad], memoryOut()), 1);
    rmSync(dir, { recursive: true, force: true });
  });

  it("wires --readme through the CLI: drift → 1, missing README file → 2", () => {
    const dir = tempDir("readme-wiring");
    const stamp = path.join(dir, "stamp.md");
    writeFileSync(stamp, readFileSync(fixturePath("minimal.md"), "utf8"));
    const readme = path.join(dir, "readme.md");
    writeFileSync(readme, '# P\n\n<!-- rigor:line -->\n> "stale" — [RIGOR.md](RIGOR.md)\n<!-- /rigor:line -->\n');
    assert.equal(run(["validate", stamp, "--readme", readme], memoryOut()), 1);
    assert.equal(run(["validate", stamp, "--readme", "/nonexistent-readme.md"], memoryOut()), 2);
    rmSync(dir, { recursive: true, force: true });
  });

  it("the banner drops badge/serve and validate's usage line mentions --readme", () => {
    const out = memoryOut();
    run([], out);
    assert.ok(!out.toString().includes("badge"));
    assert.ok(!out.toString().includes("serve"));

    const out2 = memoryOut();
    run(["validate"], out2);
    assert.ok(out2.toString().includes("--readme"));
  });

  it("fails loudly (exit 1) on an unrecognized --flag instead of silently ignoring it", () => {
    const out = memoryOut();
    assert.equal(run(["validate", fixturePath("full_r3.md"), "--bogus-flag"], out), 1);
    assert.ok(out.toString().includes("invalid option: --bogus-flag"));
  });

  it("fails loudly (exit 1) on a boolean flag written as --flag=value", () => {
    const dir = tempDir("force-eq");
    const out = memoryOut();
    assert.equal(run(["init", dir, "--force=true"], out), 1);
    assert.ok(out.toString().includes("invalid option"));
    rmSync(dir, { recursive: true, force: true });
  });

  it("fails loudly (exit 1) on a value-flag with no following value", () => {
    const out = memoryOut();
    assert.equal(run(["validate", fixturePath("full_r3.md"), "--readme"], out), 1);
    assert.ok(out.toString().includes("missing value for --readme"));
  });
});
