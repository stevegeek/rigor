// Transcribed from spec/embed_spec.cr.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { extract } from "../src/document.js";
import { emit } from "../src/embed.js";
import { line, lineBlock } from "../src/summary.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function docFor(name) {
  const { doc } = extract(readFileSync(path.join(__dirname, "fixtures", name), "utf8"));
  return doc;
}

describe("Rigor::Embed", () => {
  it("emits the README line block for a stamp", () => {
    const d = docFor("full_r3.md");
    assert.equal(emit(d), lineBlock(d));
  });

  it("agrees with Summary.line for a minimal stamp", () => {
    const d = docFor("minimal.md");
    assert.ok(emit(d).includes(`"${line(d)}"`));
  });
});
