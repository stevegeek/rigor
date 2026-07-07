// Transcribed from spec/commands/schema_spec.cr. Not in the Task 4 brief's
// literal test-file list, but included per the global constraint to
// transcribe ALL of spec/commands/*_spec.cr.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { run } from "../src/commands/schema.js";
import { memoryOut } from "./helpers.js";

describe("Rigor::Commands::Schema", () => {
  it("prints valid JSON that is the canonical schema", () => {
    const out = memoryOut();
    const code = run(out);
    assert.equal(code, 0);
    const parsed = JSON.parse(out.toString());
    assert.deepStrictEqual(parsed.required, ["rigor", "vouch"]);
  });
});
