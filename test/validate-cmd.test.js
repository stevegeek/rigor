// Covers Commands::Validate.run: exit codes, --json output, and --readme
// drift checking.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync, writeFileSync, rmSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { run } from "../src/commands/validate.js";
import { extract } from "../src/document.js";
import { lineBlock } from "../src/summary.js";
import { memoryOut, stampDoc, tempDir } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixturePath(name) {
  return path.join(__dirname, "fixtures", name);
}

describe("Rigor::Commands::Validate", () => {
  it("returns 0 and prints valid for a good file", () => {
    const out = memoryOut();
    const code = run(fixturePath("minimal.md"), false, false, out);
    assert.equal(code, 0);
    assert.ok(out.toString().includes("valid: true"));
  });

  it("returns 1 for a contradicting file", () => {
    const dir = tempDir("rigor");
    const p = path.join(dir, "rigor.md");
    writeFileSync(p, stampDoc("rigor: engineered\nchecks:\n  security_reviewed: no\nvouch: neutral"));
    const code = run(p, false, false, memoryOut());
    assert.equal(code, 1);
    rmSync(dir, { recursive: true, force: true });
  });

  it("emits JSON with --json", () => {
    const out = memoryOut();
    run(fixturePath("minimal.md"), false, true, out);
    const parsed = JSON.parse(out.toString());
    assert.equal(parsed.valid, true);
  });

  it("includes the stamp's spec version in --json output", () => {
    const out = memoryOut();
    run(fixturePath("minimal_v2.md"), false, true, out);
    const parsed = JSON.parse(out.toString());
    assert.equal(parsed.spec_version, "0.3");
  });

  it("reports spec_version as null when the stamp has no spec field", () => {
    const dir = tempDir("rigor");
    const p = path.join(dir, "rigor.md");
    writeFileSync(p, stampDoc("rigor: skimmed\nvouch: neutral"));
    const out = memoryOut();
    run(p, false, true, out);
    const parsed = JSON.parse(out.toString());
    assert.equal(parsed.spec_version, null);
    rmSync(dir, { recursive: true, force: true });
  });

  it("exits 1 and mentions README when the --readme line has drifted from the stamp", () => {
    const dir = tempDir("rigor");
    const stampPath = path.join(dir, "rigor.md");
    const readmePath = path.join(dir, "readme.md");
    const { doc } = extract(readFileSync(fixturePath("minimal.md"), "utf8"));
    writeFileSync(stampPath, readFileSync(fixturePath("minimal.md"), "utf8"));
    const staleBlock = lineBlock(doc).replace("read and understood this code", "skimmed this code");
    writeFileSync(readmePath, `# P\n\n${staleBlock}\n`);
    const out = memoryOut();
    const code = run(stampPath, false, false, out, readmePath);
    assert.equal(code, 1);
    assert.ok(out.toString().includes("README"));
    rmSync(dir, { recursive: true, force: true });
  });

  it("exits 0 when the --readme line matches the stamp", () => {
    const dir = tempDir("rigor");
    const stampPath = path.join(dir, "rigor.md");
    const readmePath = path.join(dir, "readme.md");
    writeFileSync(stampPath, readFileSync(fixturePath("minimal.md"), "utf8"));
    const { doc } = extract(readFileSync(fixturePath("minimal.md"), "utf8"));
    writeFileSync(readmePath, `# P\n\n${lineBlock(doc)}\n`);
    const out = memoryOut();
    const code = run(stampPath, false, false, out, readmePath);
    assert.equal(code, 0);
    rmSync(dir, { recursive: true, force: true });
  });

  it("exits 0 silently when the --readme file has no line markers", () => {
    const dir = tempDir("rigor");
    const stampPath = path.join(dir, "rigor.md");
    const readmePath = path.join(dir, "readme.md");
    writeFileSync(stampPath, readFileSync(fixturePath("minimal.md"), "utf8"));
    writeFileSync(readmePath, "# P\nno markers here\n");
    const out = memoryOut();
    const code = run(stampPath, false, false, out, readmePath);
    assert.equal(code, 0);
    assert.ok(!out.toString().includes("README"));
    rmSync(dir, { recursive: true, force: true });
  });
});
