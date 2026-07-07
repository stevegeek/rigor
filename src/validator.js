// Port of src/rigor/validator.cr.

import { readFileSync } from "node:fs";
import Ajv2020 from "ajv/dist/2020.js";
import { extract } from "./document.js";
import { LEVEL_REQUIRES } from "./vocabulary.js";
import { drift } from "./summary.js";

// Schema loading (porting contract note): the Crystal predecessor embedded
// rigor.schema.json at COMPILE time via `{{ read_file(...) }}`, baking the
// schema into the binary with no runtime file dependency. JS has no
// equivalent compile-time file inlining, so SCHEMA_JSON is read at
// module-load time instead.
//
// Packaging note (cutover, Task 6): js/ was promoted to the repo root, so
// rigor.schema.json now lives one level up from src/ AT the package root
// — the single canonical copy (the earlier js/rigor.schema.json packaging
// copy and its schema-sync test were retired at the same time, since there
// is no longer a second copy to drift from). It is included in
// package.json's "files" so an `npm pack`'d tarball still carries it.
const SCHEMA_PATH = new URL("../rigor.schema.json", import.meta.url);

/** Canonical schema text, read once at module load. @type {string} */
export const SCHEMA_JSON = readFileSync(SCHEMA_PATH, "utf8");

const ajv = new Ajv2020({ allErrors: true, strictSchema: false });
const validateSchema = ajv.compile(JSON.parse(SCHEMA_JSON));

/**
 * @param {any} v
 * @returns {boolean}
 */
function isPlainObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

// The allowed-values list renders bracketed, comma-space separated, each
// element double-quoted: `["yes", "human"]`. This exact format is part of
// the error-message contract (pinned by the validator tests); JS's default
// array-to-string coercion (`yes,human`) is not it.
/**
 * @param {string[]} arr
 * @returns {string}
 */
function inspectValueList(arr) {
  return `[${arr.map((x) => JSON.stringify(x)).join(", ")}]`;
}

// ajv reports an `additionalProperties` violation with instancePath at the
// OBJECT that carries the unexpected key (often "", the document root),
// with the offending key name only in `params.additionalProperty` —
// unlike json_schemer, which points `data_pointer` straight at the
// offending property (e.g. "/bogus"). Appending the property name to the
// pointer here reproduces that pointer-at-the-property behavior so
// consuming code (and error text) can still find "/bogus" etc.
/**
 * @param {import("ajv").ErrorObject} e
 * @returns {string}
 */
function renderError(e) {
  let pointer = e.instancePath;
  if (e.keyword === "additionalProperties" && e.params && e.params.additionalProperty) {
    pointer = `${pointer}/${e.params.additionalProperty}`;
  }
  return `${pointer}: ${e.message}`;
}

/**
 * @param {Object<string, any>} doc
 * @returns {string[]}
 */
export function structural(doc) {
  const valid = validateSchema(doc);
  if (valid) return [];
  return (validateSchema.errors ?? []).map(renderError);
}

/**
 * @typedef {{errors: string[], warnings: string[]}} SemanticResult
 */

/**
 * @param {Object<string, any>} doc
 * @param {boolean} strict
 * @returns {SemanticResult}
 */
export function semantic(doc, strict) {
  const errors = [];
  const warnings = [];

  const rigor = doc["rigor"];
  const checks = isPlainObject(doc["checks"]) ? doc["checks"] : {};
  const required = LEVEL_REQUIRES[rigor] ?? {};

  // Above the comprehension line, a claim must show its working: the
  // implied checks must be surfaced, not merely non-contradicting. At or
  // below `comprehended`, terse stamps stay legal.
  const mustSurface = rigor === "engineered" || rigor === "owned";
  for (const [name, acceptable] of Object.entries(required)) {
    if (Object.prototype.hasOwnProperty.call(checks, name)) {
      const got = checks[name];
      if (!acceptable.includes(got)) {
        errors.push(
          `rigor '${rigor}' requires '${name}' to be one of ${inspectValueList(acceptable)}, but it is '${got}'.`,
        );
      }
    } else if (mustSurface) {
      errors.push(`rigor '${rigor}' claims '${name}' but it is not surfaced — show your working (add '${name}:' under checks:).`);
    } else if (strict) {
      warnings.push(`rigor '${rigor}' implies '${name}' but it was not surfaced.`);
    }
  }

  // An AI-only review is a different claim from a human one once the
  // headline crosses into engineered/owned territory (below the line the
  // summary sentence's "(by an AI)" actor parenthetical already covers
  // it). One warning names every affected check, rather than spamming one
  // per check.
  if (rigor === "engineered" || rigor === "owned") {
    const aiOnly = ["quality_reviewed", "security_reviewed"].filter((k) => checks[k] === "ai");
    if (aiOnly.length > 0) {
      const names = aiOnly.join(" and ");
      warnings.push(
        `${names} satisfied by an AI alone, but rigor is '${rigor}'. An AI-only review is a different claim from a human one at this level; confirm it supports the claim, or record the human pass.`,
      );
    }
  }

  const stages = isPlainObject(doc["stages"]) ? doc["stages"] : null;
  if (stages) {
    const maintenance = isPlainObject(stages["maintenance"]) ? stages["maintenance"] : null;

    if (maintenance && maintenance["by"] === "ai" && (rigor === "engineered" || rigor === "owned")) {
      warnings.push(
        `stages.maintenance.by is 'ai' (unattended) but rigor is '${rigor}'. Fully automated maintenance rarely sustains this level; confirm this reflects review of the most recent changes.`,
      );
    }

    if (maintenance && maintenance["by"] === "none" && Object.prototype.hasOwnProperty.call(maintenance, "activity")) {
      errors.push("stages.maintenance.by is 'none'; 'activity' does not apply — remove it or name who responds.");
    }
  }

  return { errors, warnings };
}

/**
 * @typedef {{valid: boolean, errors: string[], warnings: string[], doc: Object<string, any>|null}} ValidateResult
 */

/**
 * @param {string} text
 * @param {{strict?: boolean}} [options]
 * @returns {ValidateResult}
 */
export function validate(text, { strict = false } = {}) {
  const { doc, error } = extract(text);
  if (error) {
    return { valid: false, errors: [error], warnings: [], doc: null };
  }

  const structErrors = structural(doc);
  if (structErrors.length > 0) {
    return { valid: false, errors: structErrors, warnings: [], doc };
  }

  const { errors, warnings } = semantic(doc, strict);

  if (drift(text, doc)) {
    errors.push("The summary block does not match the stamp. Run `rigor fmt <file>` to regenerate it.");
  }

  if (!("spec" in doc)) {
    warnings.push('The stamp does not declare a spec version. Add `spec: "0.3"`.');
  }

  return { valid: errors.length === 0, errors, warnings, doc };
}
