// Transcribed from spec/document_spec.cr, plus a new "YAML 1.2 parity"
// block (see the note at the top of src/document.js) covering behavior
// that the yaml package's YAML 1.2 core schema handles differently to
// Crystal's YAML 1.1 parser.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { extract, normalizeRigor, MAX_STAMP_BYTES } from "../src/document.js";
import { stampDoc } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixture(name) {
  return readFileSync(path.join(__dirname, "fixtures", name), "utf8");
}

describe("Rigor::Document", () => {
  describe(".normalize_rigor", () => {
    it("passes canonical names through", () => {
      assert.equal(normalizeRigor("engineered"), "engineered");
    });

    it("is case-insensitive on names and trims whitespace", () => {
      assert.equal(normalizeRigor("  Owned "), "owned");
    });

    it("passes unknown values through unchanged", () => {
      assert.equal(normalizeRigor("bogus"), "bogus");
    });
  });

  describe(".extract", () => {
    it("errors when there is no stamp", () => {
      const { doc, error } = extract("no frontmatter here");
      assert.equal(doc, null);
      assert.ok(error.includes("No stamp found"));
    });

    it("coerces YAML yes/no booleans back to strings and normalizes rigor", () => {
      const text = fixture("full_r3.md");
      const { doc, error } = extract(text);
      assert.equal(error, null);
      assert.equal(doc["rigor"], "engineered");
      assert.equal(doc["checks"]["comprehended"], "yes");
      assert.equal(doc["checks"]["tested"], "not-applicable");
      assert.equal(doc["vouch"], "yes");
    });

    it("errors on invalid YAML", () => {
      const { doc, error } = extract(stampDoc(" rigor: : :"));
      assert.equal(doc, null);
      assert.ok(error.includes("YAML"));
    });

    it("rejects YAML anchors/aliases (billion-laughs vector)", () => {
      const text = stampDoc("rigor: comprehended\nvouch: neutral\na: &a [x, x]\nb: [*a, *a]");
      const { doc, error } = extract(text);
      assert.equal(doc, null);
      assert.ok(error.includes("anchors/aliases"));
    });

    it("reports malformed YAML error before alias error (malformed YAML wins)", () => {
      const text = stampDoc("rigor: : :\na: &a [x]\nb: [*a]");
      const { doc, error } = extract(text);
      assert.equal(doc, null);
      assert.ok(error.startsWith("Stamp is not valid YAML:"));
    });

    it("rejects an oversized stamp", () => {
      const big = stampDoc("rigor: comprehended\nvouch: neutral\n" + "# pad\n".repeat(20000));
      const { doc, error } = extract(big);
      assert.equal(doc, null);
      assert.ok(error.includes("too large"));
    });

    it("rejects a v0.2 Stamp block whose yaml exceeds Document::MAX_STAMP_BYTES", () => {
      const big = stampDoc("rigor: comprehended\nvouch: neutral\n# " + "a".repeat(MAX_STAMP_BYTES));
      const { doc, error } = extract(big);
      assert.equal(doc, null);
      assert.ok(error.includes("too large"));
    });

    it("does not crash on pathological whitespace with no closing fence", () => {
      const text = "## Stamp\n\n```yaml\n" + "\n \t".repeat(20000) + "rigor: comprehended\n";
      const { doc, error } = extract(text);
      assert.equal(doc, null);
      assert.ok(error.includes("No stamp found"));
    });

    it("preserves a non-mapping checks value so the schema can reject it", () => {
      // list-form checks (a very common YAML mistake) must not be swallowed
      const { doc, error } = extract(
        stampDoc("rigor: engineered\nchecks:\n  - security_reviewed: no\nvouch: yes"),
      );
      assert.equal(error, null);
      assert.ok(Array.isArray(doc["checks"]));
    });
  });

  describe(".extract v0.2 layout", () => {
    it("parses the trailing Stamp block", () => {
      const { doc, error } = extract(fixture("minimal_v2.md"));
      assert.equal(error, null);
      assert.equal(doc["rigor"], "comprehended");
      assert.equal(doc["spec"], "0.3");
    });

    it("coerces a bare spec: 0.3 scalar to a string", () => {
      const text = stampDoc("spec: 0.3\nrigor: comprehended\nvouch: neutral");
      const { doc } = extract(text);
      assert.equal(doc["spec"], "0.3");
    });

    it("uses the LAST Stamp heading's yaml block", () => {
      const text = fixture("minimal_v2.md") + "\n## Stamp\n\n```yaml\nrigor: owned\nvouch: yes\n```\n";
      const { doc } = extract(text);
      assert.equal(doc["rigor"], "owned");
    });

    it("errors on a frontmatter-only file, mentioning Stamp", () => {
      const text = "---\nrigor: comprehended\nvouch: neutral\n---\n# body\n";
      const { doc, error } = extract(text);
      assert.equal(doc, null);
      assert.ok(error.includes("Stamp"));
    });

    it("errors clearly when no stamp is present", () => {
      const { error } = extract("just prose");
      assert.ok(error.includes("Stamp"));
    });

    it("coerces an unquoted day-precision assessed date to YYYY-MM-DD", () => {
      const text = stampDoc("rigor: comprehended\nvouch: neutral\nassessed: 2026-07-15");
      const { doc, error } = extract(text);
      assert.equal(error, null);
      assert.equal(doc["assessed"], "2026-07-15");
    });
  });

  // NEW: not in document_spec.cr. Crystal's YAML parser is 1.1 (bare
  // yes/no are booleans, bare day-precision dates are Time); the yaml
  // package's default core schema is YAML 1.2 (yes/no are strings already,
  // no timestamp type). These pin the JS-side behavior at each point where
  // that divergence could silently change an observable result.
  describe("YAML 1.2 parity (yaml package core schema vs Crystal's YAML 1.1)", () => {
    it("unquoted assessed: 2026-07-15 stays the string \"2026-07-15\" (no 1.1 Time type)", () => {
      const text = stampDoc("rigor: comprehended\nvouch: neutral\nassessed: 2026-07-15");
      const { doc, error } = extract(text);
      assert.equal(error, null);
      assert.equal(doc["assessed"], "2026-07-15");
    });

    it("bare spec: 0.3 arrives as a JS number and String()-ifies to \"0.3\"", () => {
      assert.equal(String(0.3), "0.3");
      const text = stampDoc("spec: 0.3\nrigor: comprehended\nvouch: neutral");
      const { doc, error } = extract(text);
      assert.equal(error, null);
      assert.equal(doc["spec"], "0.3");
    });

    it("comprehended: true (a real YAML 1.2 boolean) coerces to the string \"yes\"", () => {
      const text = stampDoc(
        "rigor: engineered\nvouch: neutral\nchecks:\n  comprehended: true\n  quality_reviewed: yes\n  security_reviewed: yes\n  tested: not-applicable",
      );
      const { doc, error } = extract(text);
      assert.equal(error, null);
      assert.equal(doc["checks"]["comprehended"], "yes");
    });
  });
});
