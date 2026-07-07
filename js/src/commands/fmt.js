// Port of src/rigor/commands/fmt.cr.

import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { extract } from "../document.js";
import { structural } from "../validator.js";
import { replace, block } from "../summary.js";

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
  const text = readFileSync(filePath, "utf8");
  const { doc, error } = extract(text);
  if (error) {
    out.puts(`error: ${error}`);
    return 1;
  }

  const structErrors = structural(doc);
  if (structErrors.length > 0) {
    out.puts("error: stamp is structurally invalid; fix it before formatting:");
    for (const e of structErrors) out.puts(`  ${e}`);
    return 1;
  }

  const newText = replace(text, doc) ?? insertSummary(text, doc);
  writeFileSync(filePath, newText);

  out.puts(`wrote ${filePath}`);
  return 0;
}

// No markers yet: put the summary block right after the title line.
/**
 * @param {string} text
 * @param {Object<string, any>} doc
 * @returns {string}
 */
function insertSummary(text, doc) {
  const lines = text.split("\n");
  lines.splice(1, 0, `\n${block(doc)}`);
  return lines.join("\n");
}
