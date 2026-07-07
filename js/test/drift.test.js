// Transcribed from spec/drift_spec.cr.
//
// Note on the file name: this "drift" is schema-vs-vocabulary constant
// drift (do rigor.schema.json's enums and vocabulary.js's arrays still
// agree?) — unrelated to the summary-vs-stamp "drift" that validator.js's
// `validate()` checks via summary.js's `drift()` (see src/validator.js and
// src/summary.js). Nothing here depends on summary.js, so none of these
// are skipped.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { SCHEMA_JSON } from "../src/validator.js";
import { LEVELS, CHECK_VALUES, ACTIVITY } from "../src/vocabulary.js";

describe("schema/vocabulary drift", () => {
  it("vocabulary level names are exactly the schema rigor enum", () => {
    const schema = JSON.parse(SCHEMA_JSON);
    const enumVals = schema.properties.rigor.enum;
    assert.deepStrictEqual([...enumVals].sort(), [...LEVELS].sort());
  });

  it("check values match", () => {
    const schema = JSON.parse(SCHEMA_JSON);
    const cv = schema.$defs.checkValue.enum;
    assert.deepStrictEqual([...cv].sort(), [...CHECK_VALUES].sort());
  });

  it("maintenance activity values match", () => {
    const schema = JSON.parse(SCHEMA_JSON);
    const av = schema.properties.stages.properties.maintenance.properties.activity.enum;
    assert.deepStrictEqual([...av].sort(), [...ACTIVITY].sort());
  });
});
