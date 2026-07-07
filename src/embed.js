// Port of src/rigor/embed.cr.
//
// The paste-ready README snippet. Thin on purpose: summary.js owns the
// sentence composition and marker logic; this module is the stable name the
// CLI (`rigor embed`) calls, independent of how that text is assembled.

import { lineBlock } from "./summary.js";

export const USAGE_HINT = "Paste into your README; rigor validate <file> --readme README.md will keep it honest.";

/**
 * @param {Object<string, any>} doc
 * @returns {string}
 */
export function emit(doc) {
  return lineBlock(doc);
}
