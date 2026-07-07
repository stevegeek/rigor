// Transcribed from spec/validator_spec.cr.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import path from "node:path";
import { extract } from "../src/document.js";
import { structural, validate } from "../src/validator.js";
import { stampDoc } from "./helpers.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

/** @param {string} name */
function fixture(name) {
  return readFileSync(path.join(__dirname, "fixtures", name), "utf8");
}

describe("Rigor::Validator", () => {
  describe(".structural", () => {
    it("accepts a valid minimal document", () => {
      const { doc } = extract(fixture("minimal.md"));
      assert.deepStrictEqual(structural(doc), []);
    });

    it("rejects an unknown field and a bad vouch value", () => {
      const doc = JSON.parse('{"rigor":"R2","vouch":"maybe","bogus":1}');
      const errs = structural(doc);
      const joined = errs.join("\n");
      assert.ok(joined.includes("/vouch"));
      assert.ok(joined.includes("/bogus"));
    });
  });

  describe(".validate", () => {
    it("accepts the full R3 example", () => {
      const r = validate(fixture("full_r3.md"));
      assert.equal(r.valid, true);
      assert.deepStrictEqual(r.errors, []);
    });

    it("accepts the R4-partial example with NO warnings in non-strict mode", () => {
      const r = validate(fixture("r4_partial.md"));
      assert.equal(r.valid, true);
      assert.deepStrictEqual(
        r.warnings.filter((w) => w.includes("implies")),
        [],
      );
    });

    it("warns about unsurfaced implied checks in strict mode", () => {
      const r = validate(fixture("r4_partial.md"), { strict: true });
      assert.equal(r.valid, true);
      assert.equal(r.warnings.filter((w) => w.includes("implies")).length, 1);
    });

    it("errors when a surfaced check contradicts the level", () => {
      const text = stampDoc(
        "rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral",
      );
      const r = validate(text);
      assert.equal(r.valid, false);
      assert.ok(r.errors.join("").includes("security_reviewed"));
    });

    it("rejects list-form checks instead of silently passing (regression)", () => {
      // Before the fix, coerce_checks swallowed a non-mapping into {} and this
      // validated as true, hiding an engineered claim that contradicts
      // security_reviewed: no.
      const text = stampDoc("rigor: engineered\nchecks:\n  - security_reviewed: no\nvouch: yes");
      assert.equal(validate(text).valid, false);
    });

    it("rejects a scalar checks value", () => {
      assert.equal(validate(stampDoc("rigor: engineered\nchecks: nope\nvouch: yes")).valid, false);
    });

    it("keeps a surfaced contradiction an error in strict mode too", () => {
      const text = stampDoc(
        "rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: no\nvouch: neutral",
      );
      assert.equal(validate(text, { strict: true }).valid, false);
    });

    it("warns on unattended AI maintenance with high rigor in BOTH modes", () => {
      const text = stampDoc("rigor: owned\nvouch: yes\nstages:\n  maintenance: {by: ai}");
      assert.ok(validate(text).warnings.join("").includes("unattended"));
      assert.ok(validate(text, { strict: true }).warnings.join("").includes("unattended"));
    });

    it("accepts actor values as done for review checks", () => {
      const text = stampDoc(
        "rigor: engineered\nchecks:\n  comprehended: yes\n  quality_reviewed: ai\n  security_reviewed: human\n  tested: human-with-ai\nvouch: neutral",
      );
      const r = validate(text);
      assert.equal(r.valid, true);
    });

    it("does not let an AI comprehension cross the line", () => {
      const text = stampDoc("rigor: comprehended\nchecks:\n  comprehended: ai\nvouch: neutral");
      const r = validate(text);
      assert.equal(r.valid, false);
      assert.ok(r.errors.join("").includes("comprehended"));
    });

    it("accepts a stages block and rejects origin as an unknown field", () => {
      const good = stampDoc(
        "rigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: human, depth: deep}\n  plan: {by: human-with-ai, depth: considered}\n  implementation: {by: ai}\n  maintenance: {by: none}",
      );
      assert.equal(validate(good).valid, true);

      // origin is not part of the v0.2 vocabulary; the Stamp block never
      // migrates it, so it is rejected as an unknown field.
      const bad = stampDoc("rigor: skimmed\nvouch: neutral\norigin:\n  authored: ai-generated");
      assert.equal(validate(bad).valid, false);
    });

    it("rejects depth on implementation and none outside maintenance", () => {
      assert.equal(
        validate(stampDoc("rigor: skimmed\nvouch: neutral\nstages:\n  implementation: {by: ai, depth: deep}")).valid,
        false,
      );
      assert.equal(validate(stampDoc("rigor: skimmed\nvouch: neutral\nstages:\n  idea: {by: none}")).valid, false);
    });

    it("warns on unattended AI maintenance with high rigor", () => {
      const text = stampDoc(
        "rigor: owned\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: yes\n  security_reviewed: yes\n  tested: yes\n  owned: yes\nstages:\n  maintenance: {by: ai}",
      );
      assert.ok(validate(text).warnings.join("").includes("unattended"));
    });

    it("warns about a missing spec version", () => {
      const text = stampDoc("rigor: skimmed\nvouch: neutral");
      const r = validate(text);
      assert.equal(r.valid, true);
      assert.ok(r.warnings.join("").includes("spec version"));
    });

    it("accepts the v0.2 fixtures without warnings", () => {
      const r = validate(fixture("engineered_v2.md"));
      assert.equal(r.valid, true);
      assert.deepStrictEqual(r.warnings, []);
    });

    it("rejects a malformed assessed date and an unknown spec version", () => {
      assert.equal(validate(stampDoc("rigor: comprehended\nvouch: neutral\nassessed: July 2026")).valid, false);
      assert.equal(validate(stampDoc('rigor: comprehended\nvouch: neutral\nspec: "9.9"')).valid, false);
    });

    it("requires surfaced checks for levels above the line (show your working)", () => {
      const r = validate(stampDoc("rigor: engineered\nvouch: yes"));
      assert.equal(r.valid, false);
      assert.ok(r.errors.join("").includes("show your working"));
      // comprehended stays terse-friendly
      assert.equal(validate(stampDoc("rigor: comprehended\nvouch: neutral")).valid, true);
      // low levels stay terse-friendly
      assert.equal(validate(stampDoc("rigor: skimmed\nvouch: neutral")).valid, true);
    });

    // Skipped: drift detection needs Summary.drift, which lives in
    // summary.js — not created until Task 3. validator.js's lazy
    // module-load guard (see src/validator.js) silently no-ops the drift
    // check while summary.js is absent, so this document currently
    // validates (wrongly, but expectedly for this task) as true. Task 3
    // removes the guard and un-skips this test.
    it(
      "errors when the summary block does not match the stamp",
      { skip: "summary.js lands in Task 3" },
      () => {
        const text = fixture("minimal_v2.md").replace("I have read and understood", "I promise I read");
        const r = validate(text);
        assert.equal(r.valid, false);
        assert.ok(r.errors.join("").includes("summary"));
      },
    );

    it("accepts a matching summary block", () => {
      assert.equal(validate(fixture("minimal_v2.md")).valid, true);
    });

    it("warns exactly once when a review check above the line was satisfied by AI alone", () => {
      const text = stampDoc(
        "rigor: engineered\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: human\n  security_reviewed: ai\n  tested: yes",
      );
      const r = validate(text);
      assert.equal(r.warnings.filter((w) => w.includes("AI alone")).length, 1);
      assert.ok(r.warnings.join("").includes("security_reviewed satisfied by an AI alone"));
    });

    it("names both checks when quality_reviewed and security_reviewed are both AI alone", () => {
      const text = stampDoc(
        "rigor: owned\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: ai\n  security_reviewed: ai\n  tested: yes\n  owned: yes",
      );
      const r = validate(text);
      assert.ok(r.warnings.join("").includes("quality_reviewed and security_reviewed satisfied by an AI alone"));
    });

    it("does not warn about an AI-only review when the pass was human-with-ai", () => {
      const text = stampDoc(
        "rigor: engineered\nvouch: yes\nchecks:\n  comprehended: yes\n  quality_reviewed: human\n  security_reviewed: human-with-ai\n  tested: yes",
      );
      const r = validate(text);
      assert.deepStrictEqual(
        r.warnings.filter((w) => w.includes("AI alone")),
        [],
      );
    });

    it("does not warn about AI-only checks at or below the comprehension line", () => {
      const text = stampDoc("rigor: skimmed\nvouch: neutral\nchecks:\n  security_reviewed: ai");
      const r = validate(text);
      assert.deepStrictEqual(
        r.warnings.filter((w) => w.includes("AI alone")),
        [],
      );
    });

    it("accepts vouch mapping form and rejects a mapping without claim", () => {
      assert.equal(
        validate(
          stampDoc('spec: "0.3"\nrigor: skimmed\nvouch: {claim: withheld, why: "fine for scripts, never audited"}'),
        ).valid,
        true,
      );
      assert.equal(validate(stampDoc('spec: "0.3"\nrigor: skimmed\nvouch: {why: "no claim"}')).valid, false);
    });

    it("accepts maintenance activity and rejects it on by: none", () => {
      assert.equal(
        validate(
          stampDoc('spec: "0.3"\nrigor: skimmed\nvouch: neutral\nstages:\n  maintenance: {by: human, activity: dormant}'),
        ).valid,
        true,
      );
      const r = validate(
        stampDoc('spec: "0.3"\nrigor: skimmed\nvouch: neutral\nstages:\n  maintenance: {by: none, activity: dormant}'),
      );
      assert.equal(r.valid, false);
      assert.ok(r.errors.join("").includes("activity"));
    });

    it("rejects spec 0.2 now that the vocabulary is 0.3", () => {
      assert.equal(validate(stampDoc('spec: "0.2"\nrigor: skimmed\nvouch: neutral')).valid, false);
    });
  });
});
