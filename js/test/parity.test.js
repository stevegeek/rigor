// Byte-parity gate: every fixture in test/fixtures/ plus a generated matrix
// of stamps are run through BOTH the compiled Crystal binary (bin/rigor,
// repo root) and the JS port (bin/rigor.js) for `validate --strict --json`,
// `embed`, and `fmt`, and the outputs are asserted identical.
//
// Skip contract: when ./bin/rigor is absent (the expected steady state once
// js/ becomes the repo root and the Crystal source is retired), every test
// in this file reports as SKIPPED, not failed — the suite must survive the
// post-cutover world. See the per-`it` `{ skip: SKIP_REASON }` option below.
//
// Known, accepted deviation (carried forward from the Task 4 report's "Fix:
// strict flag parsing" note): ajv (JS) and json_schemer (Crystal) render
// SCHEMA (structural) violations with different wording for the same
// failure — e.g. ajv's "must be equal to one of the allowed values" vs
// json_schemer's "value at `/rigor` is not one of: [...]". For any stamp
// that fails STRUCTURAL validation, this gate compares {valid, exit code,
// warnings, spec_version} exactly, and for `errors` only compares
// count-and-both-non-empty — never exact text. Semantic errors/warnings
// (everything else) are hand-written in both ports and ARE byte-comparable,
// so they are compared for full equality.
//
// Malformed-flag argv shapes (an unrecognized `--flag`, a boolean flag
// written `--flag=value`, or a value-flag with nothing following it) are
// deliberately EXCLUDED from this matrix: Crystal's side of that comparison
// is an unhandled-exception backtrace, not a stable string (see cli.js's
// "Strictness parity" comment and the Task 4 report). Only exit code would
// be comparable there, and it is already asserted by e2e.test.js.

import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { existsSync, mkdtempSync, mkdirSync, writeFileSync, readFileSync, readdirSync, rmSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { stringify } from "yaml";
import { block } from "../src/summary.js";
import { extract } from "../src/document.js";
import { structural } from "../src/validator.js";
import { LEVELS, VOUCH_VALUES, ACTORS, DEPTHS, CHECK_DONE } from "../src/vocabulary.js";

const execFileAsync = promisify(execFile);

const __dirname = path.dirname(fileURLToPath(import.meta.url));
// Resolved relative to the repo root, per the brief — today js/ sits one
// level below it; at cutover (js/ becomes the repo root) bin/rigor simply
// stops existing and every test below reports skipped.
const REPO_ROOT = path.resolve(__dirname, "..", "..");
const CRYSTAL_BIN = path.join(REPO_ROOT, "bin", "rigor");
const JS_BIN = path.resolve(__dirname, "..", "bin", "rigor.js");
const FIXTURES_DIR = path.join(__dirname, "fixtures");

const HAVE_CRYSTAL = existsSync(CRYSTAL_BIN);
const SKIP_REASON = HAVE_CRYSTAL
  ? false
  : `Crystal binary not found at ${CRYSTAL_BIN} — skipping byte-parity gate (expected once js/ becomes the repo root)`;

// --- stamp construction -----------------------------------------------

/**
 * @param {number} i
 * @param {any[]} arr
 * @returns {any}
 */
function pick(arr, i) {
  return arr[((i % arr.length) + arr.length) % arr.length];
}

/**
 * Wraps a stamp `doc` (a plain object matching the schema's document shape)
 * as a full RIGOR.md-style markdown file: a title, an optional pre-existing
 * summary block, and the fenced "## Stamp" yaml section. Deliberately does
 * NOT reuse stamp-yaml.js's `emit` (which always defaults a missing `spec`
 * to "0.3" — exactly wrong for building "spec absent" fixtures); `yaml`'s
 * own stringify is used instead so presence/absence of every field is under
 * this generator's control, and both runtimes' YAML parsers agree on the
 * resulting values regardless of quoting (verified against document.js's/
 * document.cr's Norway-problem coercion).
 * @param {Object<string, any>} doc
 * @param {{summaryBlock?: string|null, title?: string}} [opts]
 * @returns {string}
 */
function stampFileText(doc, { summaryBlock = null, title = "# Fixture" } = {}) {
  const yamlText = stringify(doc, { lineWidth: 0 }).replace(/\n+$/, "");
  const lines = [title, ""];
  if (summaryBlock) lines.push(summaryBlock, "");
  lines.push("## Stamp", "", "```yaml", ...yamlText.split("\n"), "```", "");
  return lines.join("\n");
}

/**
 * @param {string} level
 * @param {number} idx
 * @returns {Object<string, string>}
 */
function checksFor(level, idx) {
  const checks = {};
  const comprehendedOk = ["yes", "human", "human-with-ai"];
  const testedOk = [...CHECK_DONE, "not-applicable"];
  if (level !== "unexamined") {
    checks.comprehended = pick(comprehendedOk, idx);
  }
  if (level === "engineered" || level === "owned") {
    checks.quality_reviewed = pick(CHECK_DONE, idx + 1);
    checks.security_reviewed = pick(CHECK_DONE, idx + 2);
    checks.tested = pick(testedOk, idx + 3);
  }
  if (level === "owned") {
    checks.owned = pick(CHECK_DONE, idx + 4);
  }
  return checks;
}

/**
 * @param {number} idx
 * @param {number} variant 0 -> maintenance by:human, 1 -> dormant, 2 -> by:none
 * @returns {Object<string, any>}
 */
function stagesFor(idx, variant) {
  const stages = {
    idea: { by: pick(ACTORS, idx), depth: pick(DEPTHS, idx + 1) },
    plan: { by: pick(ACTORS, idx + 1), depth: pick(DEPTHS, idx + 2) },
    implementation: { by: pick(ACTORS, idx + 2) },
  };
  if (variant === 0) {
    stages.maintenance = { by: "human" };
  } else if (variant === 1) {
    stages.maintenance = { by: pick(["ai", "human-with-ai"], idx), activity: "dormant" };
  } else {
    stages.maintenance = { by: "none" };
  }
  return stages;
}

/** @param {number} variant @returns {string|null} */
function assessedFor(variant) {
  return variant === 0 ? "2026-07-03" : variant === 1 ? "2026-07" : null;
}

/** @param {number} variant @returns {string|null} */
function specFor(variant) {
  return variant === 1 ? null : "0.3";
}

/**
 * @param {string} level
 * @param {number} vouchForm 0 -> scalar vouch, 1 -> {claim, why} mapping
 * @param {number} variant 0..2, drives stages/assessed/spec sampling
 * @param {number} idx global sample index, drives checks/actor rotation
 * @returns {Object<string, any>}
 */
function buildMatrixDoc(level, vouchForm, variant, idx) {
  const doc = {};
  const spec = specFor(variant);
  if (spec) doc.spec = spec;
  doc.rigor = level;
  const claim = pick(VOUCH_VALUES, idx);
  doc.vouch = vouchForm === 0 ? claim : { claim, why: `Sampled rationale #${idx} for the parity matrix.` };
  const checks = checksFor(level, idx);
  if (Object.keys(checks).length > 0) doc.checks = checks;
  doc.stages = stagesFor(idx, variant);
  const assessed = assessedFor(variant);
  if (assessed) doc.assessed = assessed;
  return doc;
}

/** @type {{name: string, text: string}[]} */
const stamps = [];

for (const file of readdirSync(FIXTURES_DIR).sort()) {
  stamps.push({ name: `fixture:${file}`, text: readFileSync(path.join(FIXTURES_DIR, file), "utf8") });
}

// Generated matrix: each rigor level x vouch scalar/mapping form x 3
// variants (sampling checks/actor values, and covering maintenance
// human/dormant/by-none across the 3 variant slots, plus assessed and spec
// present/absent). 5 levels x 2 vouch forms x 3 variants = 30 stamps.
let sampleIdx = 0;
for (const level of LEVELS) {
  for (let vouchForm = 0; vouchForm < 2; vouchForm++) {
    for (let variant = 0; variant < 3; variant++) {
      const doc = buildMatrixDoc(level, vouchForm, variant, sampleIdx);
      const name = `matrix:${level}-${vouchForm === 0 ? "scalar" : "mapping"}-v${variant}`;
      stamps.push({ name, text: stampFileText(doc) });
      sampleIdx++;
    }
  }
}

// Special-cased violations (semantic unless noted) -----------------------

// 1. Show-your-working: engineered claims checks it does not surface.
stamps.push({
  name: "violation:show-your-working",
  text: stampFileText({ spec: "0.3", rigor: "engineered", vouch: "yes", checks: { comprehended: "yes" } }),
});

// 2. Drift: the frozen summary block reflects an OLDER doc than the stamp
// now says (vouch changed from neutral to yes after the summary was last
// regenerated).
{
  const staleDoc = { spec: "0.3", rigor: "comprehended", vouch: "neutral" };
  const currentDoc = { spec: "0.3", rigor: "comprehended", vouch: "yes" };
  stamps.push({
    name: "violation:drift",
    text: stampFileText(currentDoc, { summaryBlock: block(staleDoc) }),
  });
}

// 3. by: none + activity: activity does not apply once no one responds.
stamps.push({
  name: "violation:by-none-activity",
  text: stampFileText({
    spec: "0.3",
    rigor: "comprehended",
    vouch: "neutral",
    stages: { maintenance: { by: "none", activity: "active" } },
  }),
});

// 4. Structural violation (bogus rigor enum value). Not in the brief's
// literal list, added deliberately: it is the ONLY way to actually exercise
// (not just document) the ajv-vs-json_schemer relaxed-comparison path
// described at the top of this file.
stamps.push({
  name: "violation:structural-enum",
  text: '# Fixture\n\n## Stamp\n\n```yaml\nspec: "0.3"\nrigor: bogus\nvouch: neutral\n```\n',
});

// --- runner helpers ------------------------------------------------------

/**
 * @param {string[]} args
 * @param {string} cwd
 * @returns {Promise<{stdout: string, code: number|null, stderr: string}>}
 */
async function execCrystal(args, cwd) {
  try {
    const { stdout, stderr } = await execFileAsync(CRYSTAL_BIN, args, { cwd });
    return { stdout, code: 0, stderr: stderr ?? "" };
  } catch (err) {
    return { stdout: err.stdout ?? "", code: typeof err.code === "number" ? err.code : null, stderr: err.stderr ?? "" };
  }
}

/**
 * @param {string[]} args
 * @param {string} cwd
 * @returns {Promise<{stdout: string, code: number|null, stderr: string}>}
 */
async function execJs(args, cwd) {
  try {
    const { stdout, stderr } = await execFileAsync(process.execPath, [JS_BIN, ...args], { cwd });
    return { stdout, code: 0, stderr: stderr ?? "" };
  } catch (err) {
    return { stdout: err.stdout ?? "", code: typeof err.code === "number" ? err.code : null, stderr: err.stderr ?? "" };
  }
}

/**
 * Builds a full-diff assertion message: both runtimes' complete stdout
 * (and stderr, if any), labeled, so a mismatch is diagnosable without
 * re-running anything.
 * @param {string} label
 * @param {{stdout: string, code: number|null, stderr?: string}} cr
 * @param {{stdout: string, code: number|null, stderr?: string}} js
 * @returns {string}
 */
function diffBlock(label, cr, js) {
  return [
    `${label}:`,
    `--- crystal (exit ${cr.code}) ---`,
    cr.stdout,
    cr.stderr ? `[crystal stderr]\n${cr.stderr}` : "",
    `--- node (exit ${js.code}) ---`,
    js.stdout,
    js.stderr ? `[node stderr]\n${js.stderr}` : "",
  ]
    .filter((s) => s !== "")
    .join("\n");
}

describe("byte-parity gate against the Crystal binary (./bin/rigor)", () => {
  for (const stamp of stamps) {
    it(stamp.name, { skip: SKIP_REASON }, async () => {
      const base = mkdtempSync(path.join(os.tmpdir(), "rigor-parity-"));
      const crDir = path.join(base, "cr");
      const jsDir = path.join(base, "js");
      mkdirSync(crDir);
      mkdirSync(jsDir);
      const crFile = path.join(crDir, "stamp.md");
      const jsFile = path.join(jsDir, "stamp.md");
      writeFileSync(crFile, stamp.text);
      writeFileSync(jsFile, stamp.text);

      try {
        const { doc } = extract(stamp.text);
        const isStructural = doc ? structural(doc).length > 0 : false;

        // validate --strict --json ---------------------------------------
        const [crValidate, jsValidate] = await Promise.all([
          execCrystal(["validate", "stamp.md", "--strict", "--json"], crDir),
          execJs(["validate", "stamp.md", "--strict", "--json"], jsDir),
        ]);
        assert.equal(
          jsValidate.code,
          crValidate.code,
          diffBlock(`${stamp.name} validate: exit code mismatch`, crValidate, jsValidate),
        );
        const crJson = JSON.parse(crValidate.stdout);
        const jsJson = JSON.parse(jsValidate.stdout);
        assert.equal(
          jsJson.valid,
          crJson.valid,
          diffBlock(`${stamp.name} validate: "valid" mismatch`, crValidate, jsValidate),
        );
        assert.deepStrictEqual(
          jsJson.warnings,
          crJson.warnings,
          diffBlock(`${stamp.name} validate: warnings mismatch`, crValidate, jsValidate),
        );
        assert.equal(
          jsJson.spec_version,
          crJson.spec_version,
          diffBlock(`${stamp.name} validate: spec_version mismatch`, crValidate, jsValidate),
        );
        if (isStructural) {
          // Known + accepted: ajv vs json_schemer wording differs for
          // structural (schema) failures. Compare shape only.
          assert.equal(
            jsJson.errors.length,
            crJson.errors.length,
            diffBlock(`${stamp.name} validate: error count mismatch (structural failure)`, crValidate, jsValidate),
          );
          assert.ok(
            crJson.errors.length > 0 && jsJson.errors.length > 0,
            diffBlock(`${stamp.name} validate: expected non-empty errors on both sides (structural failure)`, crValidate, jsValidate),
          );
        } else {
          assert.deepStrictEqual(
            jsJson.errors,
            crJson.errors,
            diffBlock(`${stamp.name} validate: errors mismatch`, crValidate, jsValidate),
          );
          assert.equal(
            jsValidate.stdout,
            crValidate.stdout,
            diffBlock(`${stamp.name} validate: raw --json stdout mismatch (non-structural case)`, crValidate, jsValidate),
          );
        }

        // embed -----------------------------------------------------------
        const [crEmbed, jsEmbed] = await Promise.all([
          execCrystal(["embed", "stamp.md"], crDir),
          execJs(["embed", "stamp.md"], jsDir),
        ]);
        assert.equal(
          jsEmbed.code,
          crEmbed.code,
          diffBlock(`${stamp.name} embed: exit code mismatch`, crEmbed, jsEmbed),
        );
        if (isStructural) {
          assert.equal(
            jsEmbed.stdout.split("\n")[0],
            crEmbed.stdout.split("\n")[0],
            diffBlock(`${stamp.name} embed: first line mismatch (structural failure)`, crEmbed, jsEmbed),
          );
          assert.ok(
            crEmbed.stdout.length > 0 && jsEmbed.stdout.length > 0,
            diffBlock(`${stamp.name} embed: expected non-empty stdout on both sides (structural failure)`, crEmbed, jsEmbed),
          );
        } else {
          assert.equal(
            jsEmbed.stdout,
            crEmbed.stdout,
            diffBlock(`${stamp.name} embed: stdout mismatch`, crEmbed, jsEmbed),
          );
        }

        // fmt (separate temp copies; compare exit code, then file bytes) --
        const [crFmt, jsFmt] = await Promise.all([
          execCrystal(["fmt", "stamp.md"], crDir),
          execJs(["fmt", "stamp.md"], jsDir),
        ]);
        assert.equal(
          jsFmt.code,
          crFmt.code,
          diffBlock(`${stamp.name} fmt: exit code mismatch`, crFmt, jsFmt),
        );
        if (isStructural) {
          assert.equal(
            jsFmt.stdout.split("\n")[0],
            crFmt.stdout.split("\n")[0],
            diffBlock(`${stamp.name} fmt: first line mismatch (structural failure)`, crFmt, jsFmt),
          );
        } else {
          assert.equal(jsFmt.stdout, crFmt.stdout, diffBlock(`${stamp.name} fmt: stdout mismatch`, crFmt, jsFmt));
        }
        const crFileAfter = readFileSync(crFile, "utf8");
        const jsFileAfter = readFileSync(jsFile, "utf8");
        assert.equal(
          jsFileAfter,
          crFileAfter,
          [
            `${stamp.name} fmt: output file bytes mismatch:`,
            "--- crystal file ---",
            crFileAfter,
            "--- node file ---",
            jsFileAfter,
          ].join("\n"),
        );
      } finally {
        rmSync(base, { recursive: true, force: true });
      }
    });
  }
});
