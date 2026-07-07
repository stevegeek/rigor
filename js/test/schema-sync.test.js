// Task 5 packaging fix: validator.js reads the schema from
// js/rigor.schema.json (a copy, added to package.json's "files") rather
// than the repo-root rigor.schema.json, because an npm-installed package
// cannot reach outside its own package directory. This test guards against
// the two copies drifting apart while both exist. See validator.js's
// "Packaging note" comment.
//
// Skip contract: mirrors parity.test.js — once js/ becomes the repo root,
// the repo-root copy this test compares against is gone by design, and
// js/rigor.schema.json stops being a copy of anything. The test reports
// skipped, not failed, in that world.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { existsSync, readFileSync } from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT_SCHEMA = path.resolve(__dirname, "..", "..", "rigor.schema.json");
const PACKAGE_SCHEMA = path.resolve(__dirname, "..", "rigor.schema.json");

const HAVE_REPO_ROOT_SCHEMA = existsSync(REPO_ROOT_SCHEMA);
const SKIP_REASON = HAVE_REPO_ROOT_SCHEMA
  ? false
  : `repo-root rigor.schema.json not found at ${REPO_ROOT_SCHEMA} — skipping sync check (expected once js/ becomes the repo root)`;

describe("packaged schema stays in sync with the repo-root schema", () => {
  it("js/rigor.schema.json is byte-identical to the repo-root copy", { skip: SKIP_REASON }, () => {
    const repoRoot = readFileSync(REPO_ROOT_SCHEMA, "utf8");
    const packaged = readFileSync(PACKAGE_SCHEMA, "utf8");
    assert.equal(
      packaged,
      repoRoot,
      "js/rigor.schema.json has drifted from the repo-root rigor.schema.json — copy the canonical file into js/ again.",
    );
  });
});
