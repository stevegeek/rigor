// Validates a stamp: structural + semantic checks, plus the optional
// --readme drift check.

import { existsSync, readFileSync } from "node:fs";
import { validate, structural } from "../validator.js";
import { lineDrift } from "../summary.js";

/**
 * @param {string} filePath
 * @param {boolean} strict
 * @param {boolean} json
 * @param {{puts: (str?: string) => void}} out
 * @param {string|null} [readme]
 * @returns {number}
 */
export function run(filePath, strict, json, out, readme = null) {
  if (!existsSync(filePath)) {
    out.puts(`error: no such file: ${filePath}`);
    return 2;
  }
  if (readme && !existsSync(readme)) {
    out.puts(`error: no such file: ${readme}`);
    return 2;
  }
  const result = validate(readFileSync(filePath, "utf8"), { strict });

  let errors = result.errors;
  let valid = result.valid;

  if (readme && result.doc && structural(result.doc).length === 0) {
    if (lineDrift(readFileSync(readme, "utf8"), result.doc)) {
      errors = [...errors, "The README line does not match the stamp. Run rigor embed and re-paste."];
      valid = false;
    }
  }

  if (json) {
    const specVersion = result.doc && typeof result.doc["spec"] === "string" ? result.doc["spec"] : null;
    out.puts(JSON.stringify({ valid, errors, warnings: result.warnings, spec_version: specVersion }));
  } else {
    out.puts(`valid: ${valid}`);
    for (const e of errors) out.puts(`  error: ${e}`);
    for (const w of result.warnings) out.puts(`  warning: ${w}`);
  }

  return valid ? 0 : 1;
}
