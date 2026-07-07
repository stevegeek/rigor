// Deterministic stamp emission. Hand-rolled (not a general YAML dumper) so
// key order, flow style, and quoting are stable — fmt must be idempotent
// byte-for-byte.
//
// Contract: emit() assumes `doc` is already structurally valid (every field
// it reads is the type the schema requires) and does not re-check it. Its
// one caller, src/commands/init.js, runs `structural` (and then `semantic`)
// on the doc first and refuses to write anything if that reports an error.

import { vouchClaim, vouchWhy } from "./document.js";
import { CHECK_KEYS, STAGE_KEYS } from "./vocabulary.js";

/**
 * @param {any} v
 * @returns {boolean}
 */
function isPlainObject(v) {
  return v !== null && typeof v === "object" && !Array.isArray(v);
}

/**
 * @param {Object<string, any>} doc
 * @returns {string}
 */
export function emit(doc) {
  let out = "";

  out += `spec: "${doc["spec"] ?? "0.3"}"\n`;
  out += `rigor: ${doc["rigor"]}\n`;

  const claim = vouchClaim(doc);
  const why = vouchWhy(doc);
  if (why) {
    out += `vouch: {claim: ${claim}, why: ${JSON.stringify(why)}}\n`;
  } else {
    out += `vouch: ${claim}\n`;
  }

  const checks = isPlainObject(doc["checks"]) ? doc["checks"] : null;
  if (checks) {
    out += "checks:\n";
    for (const k of CHECK_KEYS) {
      if (Object.prototype.hasOwnProperty.call(checks, k)) {
        out += `  ${k}: ${checks[k]}\n`;
      }
    }
  }

  const stages = isPlainObject(doc["stages"]) ? doc["stages"] : null;
  if (stages) {
    out += "stages:\n";
    for (const k of STAGE_KEYS) {
      const st = isPlainObject(stages[k]) ? stages[k] : null;
      if (!st) continue;
      const fields = [];
      if (Object.prototype.hasOwnProperty.call(st, "by")) fields.push(`by: ${st["by"]}`);
      if (Object.prototype.hasOwnProperty.call(st, "depth")) fields.push(`depth: ${st["depth"]}`);
      if (Object.prototype.hasOwnProperty.call(st, "activity")) fields.push(`activity: ${st["activity"]}`);
      if (fields.length > 0) out += `  ${k}: {${fields.join(", ")}}\n`;
    }
  }

  if (typeof doc["assessed"] === "string") {
    out += `assessed: ${doc["assessed"]}\n`;
  }

  if (typeof doc["notes"] === "string") {
    out += `notes: ${JSON.stringify(doc["notes"])}\n`;
  }

  return out;
}
