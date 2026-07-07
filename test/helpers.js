// Shared test fixtures and doubles.

import { mkdtempSync } from "node:fs";
import os from "node:os";
import path from "node:path";

/** Wraps a bare stamp yaml block in a minimal RIGOR.md-shaped document, so
 * tests can hand `extract()` a snippet instead of a full file.
 * @param {string} yaml
 * @returns {string}
 */
export function stampDoc(yaml) {
  return `# T\n\n## Stamp\n\n\`\`\`yaml\n${yaml}\n\`\`\`\n`;
}

// An in-memory output sink: each `puts(str)` call appends `str` to the
// buffer, adding a trailing newline unless `str` already ends with one (a
// bare `.puts()` with no argument writes a lone newline). Commands under
// test write through this instead of process.stdout, so assertions can
// inspect everything they printed via `toString()`.
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

// A fresh, isolated OS temp directory per call, so file-writing tests never
// collide with each other or leave state behind between runs.
/**
 * @param {string} [prefix]
 * @returns {string}
 */
export function tempDir(prefix = "rigor-") {
  return mkdtempSync(path.join(os.tmpdir(), prefix));
}
