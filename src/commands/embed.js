// Prints the paste-ready README line for a stamp.

import { existsSync, readFileSync } from "node:fs";
import { validate } from "../validator.js";
import { emit, USAGE_HINT } from "../embed.js";

/**
 * @param {string} filePath
 * @param {{puts: (str?: string) => void}} out
 * @returns {number}
 */
export function run(filePath, out) {
  if (!existsSync(filePath)) {
    out.puts(`error: no such file: ${filePath}`);
    return 2;
  }
  const result = validate(readFileSync(filePath, "utf8"));
  if (!result.valid) {
    out.puts("Cannot generate embed: document is invalid.");
    for (const e of result.errors) out.puts(`  error: ${e}`);
    return 1;
  }
  for (const w of result.warnings) out.puts(`  warning: ${w}`);

  out.puts(emit(result.doc));
  out.puts();
  out.puts(USAGE_HINT);
  return 0;
}
