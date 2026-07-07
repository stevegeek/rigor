// Mirrors spec/spec_helper.cr's stamp_doc.

import { mkdtempSync } from "node:fs";
import os from "node:os";
import path from "node:path";

/**
 * @param {string} yaml
 * @returns {string}
 */
export function stampDoc(yaml) {
  return `# T\n\n## Stamp\n\n\`\`\`yaml\n${yaml}\n\`\`\`\n`;
}

// Mirrors Crystal's `IO::Memory.new` + `.to_s`: an `out` sink commands write
// through (`out.puts(str)`), matching Crystal's `IO#puts` semantics exactly
// (writes the string, then a newline UNLESS the string already ends with
// one; a bare `.puts()` with no argument writes a lone newline).
/**
 * @returns {{puts: (str?: string) => void, toString: () => string}}
 */
export function memoryOut() {
  let buf = "";
  return {
    puts(str = "") {
      buf += str;
      if (!str.endsWith("\n")) buf += "\n";
    },
    toString() {
      return buf;
    },
  };
}

// Mirrors Crystal's `File.tempname` + `Dir.mkdir` (or, for files,
// `File.tempname` + `File.write`) using Node's directory-based temp API:
// creates and returns a fresh, isolated OS temp directory per call.
/**
 * @param {string} [prefix]
 * @returns {string}
 */
export function tempDir(prefix = "rigor-") {
  return mkdtempSync(path.join(os.tmpdir(), prefix));
}
