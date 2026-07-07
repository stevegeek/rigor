// Port of src/rigor/commands/embed.cr.
//
// Note (matches Crystal): unlike validate/fmt, this command does not check
// File.exists? first — a missing file raises (here, propagates the node:fs
// ENOENT exception) rather than returning a usage exit code, same as
// Crystal's uncaught File::NotFoundError from the bare File.read call.

import { readFileSync } from "node:fs";
import { validate } from "../validator.js";
import { emit, USAGE_HINT } from "../embed.js";

/**
 * @param {string} filePath
 * @param {{puts: (str?: string) => void}} out
 * @returns {number}
 */
export function run(filePath, out) {
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
