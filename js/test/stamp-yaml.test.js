// Transcribed from the StampYAML.emit assertions inside spec/commands/fmt_spec.cr
// (the fmt-adjacent emit cases the Task 3 brief calls out — the rest of
// fmt_spec.cr exercises Rigor::Commands::Fmt, a later task's CLI surface).

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { parse as parseYaml } from "yaml";
import { extract } from "../src/document.js";
import { emit } from "../src/stamp-yaml.js";
import { stampDoc } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixture(name) {
  return readFileSync(path.join(__dirname, "fixtures", name), "utf8");
}

describe("Rigor::StampYAML", () => {
  it("emits deterministic stamp yaml", () => {
    const { doc } = extract(fixture("engineered_v2.md"));
    const yaml = emit(doc);
    assert.equal(yaml.split("\n")[0], 'spec: "0.3"');
    assert.ok(yaml.includes("stages:"));
    assert.ok(yaml.includes("  idea: {by: human, depth: deep}"));
    assert.ok(yaml.indexOf("rigor:") < yaml.indexOf("vouch:"));
  });

  it("round-trips a notes value with escaped quotes through StampYAML.emit", () => {
    const text = stampDoc('rigor: skimmed\nvouch: neutral\nnotes: "text with \\"quotes\\""');
    const { doc, error } = extract(text);
    assert.equal(error, null);
    const originalNotes = doc["notes"];

    const yaml = emit(doc);
    const reparsed = parseYaml(yaml);
    assert.equal(reparsed["notes"], originalNotes);
  });

  // NEW (per Task 3 brief): idempotence proof at the summary/stamp-yaml
  // layer — fmt's actual byte-idempotence (Rigor::Commands::Fmt.run twice)
  // is a later task's CLI concern, but the underlying guarantee (emit's
  // output, re-extracted and re-emitted, is byte-identical) is provable
  // now and is exactly what makes that later idempotence possible.
  it("is idempotent: emit(extract(stampDoc(emit(doc)))) === emit(doc)", () => {
    for (const name of ["engineered_v2.md", "full_r3.md", "minimal_v2.md", "minimal.md", "r4_partial.md"]) {
      const { doc: doc1 } = extract(fixture(name));
      const yaml1 = emit(doc1);

      const { doc: doc2, error } = extract(stampDoc(yaml1));
      assert.equal(error, null, `${name}: re-extracting emitted yaml failed: ${error}`);
      const yaml2 = emit(doc2);

      assert.equal(yaml2, yaml1, `${name}: emit output was not idempotent`);
    }
  });

  it("quotes spec even when the stamp omits it (defaults to 0.3)", () => {
    const { doc } = extract(stampDoc("rigor: comprehended\nvouch: neutral"));
    assert.equal(emit(doc).split("\n")[0], 'spec: "0.3"');
  });

  it("emits a flow-style vouch mapping with why via JSON.stringify escaping", () => {
    const { doc } = extract(
      stampDoc('rigor: skimmed\nvouch: {claim: withheld, why: "fine for scripts, never audited."}'),
    );
    const yaml = emit(doc);
    assert.ok(yaml.includes('vouch: {claim: withheld, why: "fine for scripts, never audited."}'));
  });
});
