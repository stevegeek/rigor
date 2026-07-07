// Prints the canonical JSON Schema used for structural validation.

import { SCHEMA_JSON } from "../validator.js";

/**
 * @param {{puts: (str?: string) => void}} out
 * @returns {number}
 */
export function run(out) {
  out.puts(SCHEMA_JSON);
  return 0;
}
