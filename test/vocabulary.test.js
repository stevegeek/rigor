// Transcribed from spec/vocabulary_spec.cr.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { LEVELS, LEVEL_SENTENCE, VOUCH_VALUES, VOUCH_SENTENCE, LEVEL_REQUIRES } from "../src/vocabulary.js";

describe("Rigor::Vocabulary", () => {
  it("levels are the five v0.2 names, ordered", () => {
    assert.deepStrictEqual(LEVELS, ["unexamined", "skimmed", "comprehended", "engineered", "owned"]);
  });

  it("has a first-person sentence for every level and vouch value", () => {
    for (const l of LEVELS) {
      assert.ok(LEVEL_SENTENCE[l] && LEVEL_SENTENCE[l].length > 0, `LEVEL_SENTENCE[${l}] should not be empty`);
    }
    for (const v of VOUCH_VALUES) {
      assert.ok(VOUCH_SENTENCE[v] && VOUCH_SENTENCE[v].length > 0, `VOUCH_SENTENCE[${v}] should not be empty`);
    }
  });

  it("level requirements are keyed by name", () => {
    assert.ok(Object.keys(LEVEL_REQUIRES["engineered"]).includes("security_reviewed"));
    assert.deepStrictEqual(LEVEL_REQUIRES["skimmed"], {});
  });
});
