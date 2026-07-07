// Extracts and normalizes the Stamp block from a RIGOR.md.
//
// YAML semantics note: stamps are parsed with the `yaml` package's default
// core schema (YAML 1.2). Under that schema, bare `yes`/`no` already arrive
// as plain strings — exactly the vocabulary's own tokens — and there is no
// timestamp type, so a bare `2026-07-15` arrives as a string too. Only
// `true`/`false` arrive as real JS booleans. An author plausibly writes
// `comprehended: true` meaning the same thing as `comprehended: yes`, so
// `coerceYesNo` below maps booleans back onto their vocabulary equivalents.

import { parseDocument, isAlias, visit } from "yaml";
import { LEVELS } from "./vocabulary.js";

// The stamp is spec'd as shallow and hand-written; a real one is well
// under 1 KB. Cap it so a hostile file cannot force a huge parse.
export const MAX_STAMP_BYTES = 64 * 1024;

const STAMP_HEADING = /^##\s+Stamp\s*$/;
const FENCE_OPEN = /^```ya?ml\s*$/;
const FENCE_CLOSE = /^```\s*$/;

/**
 * Normalize to the canonical v0.2 name: trim + downcase, and return that
 * if it matches a known level. Anything else passes through unchanged so
 * the schema reports it.
 * @param {string} value
 * @returns {string}
 */
export function normalizeRigor(value) {
  const token = value.trim().toLowerCase();
  return LEVELS.includes(token) ? token : value;
}

/**
 * Vouch is a scalar or a {claim, why} mapping; downstream code reads it
 * only through these two helpers.
 * @param {Object<string, any>} doc
 * @returns {string}
 */
export function vouchClaim(doc) {
  const v = doc["vouch"];
  if (v !== null && typeof v === "object" && !Array.isArray(v)) {
    return v["claim"] ?? "";
  }
  return v;
}

/**
 * @param {Object<string, any>} doc
 * @returns {string|null}
 */
export function vouchWhy(doc) {
  const v = doc["vouch"];
  if (v !== null && typeof v === "object" && !Array.isArray(v)) {
    return v["why"] ?? null;
  }
  return null;
}

// The stamp: the fenced yaml block under the LAST "## Stamp" heading.
// Line-scanned, not regexed across the file, so pathological input cannot
// trigger catastrophic backtracking.
/**
 * @param {string} text
 * @returns {string|null}
 */
function stampYaml(text) {
  const lines = text.split("\n");
  let heading = null;
  for (let i = 0; i < lines.length; i++) {
    if (STAMP_HEADING.test(lines[i])) heading = i;
  }
  if (heading === null) return null;

  let open = null;
  for (let i = heading + 1; i < lines.length; i++) {
    if (FENCE_OPEN.test(lines[i])) {
      open = i;
      break;
    }
  }
  if (open === null) return null;

  let close = null;
  for (let i = open + 1; i < lines.length; i++) {
    if (FENCE_CLOSE.test(lines[i])) {
      close = i;
      break;
    }
  }
  if (close === null) return null;

  return lines.slice(open + 1, close).join("\n");
}

/**
 * @typedef {{doc: Object<string, any>|null, error: string|null}} ExtractResult
 */

/**
 * @param {string} text
 * @returns {ExtractResult}
 */
export function extract(text) {
  const yaml = stampYaml(text);
  if (yaml !== null) {
    return parseStamp(yaml);
  }
  return { doc: null, error: "No stamp found. Expected a '## Stamp' section with a fenced yaml block." };
}

// Walk the parsed document's contents for any Alias node (which is what
// expands a bomb). This happens BEFORE any .toJS() call — expansion of an
// alias only happens when the tree is materialized, never during parsing.
/**
 * @param {import("yaml").Document} parsed
 * @returns {boolean}
 */
function containsAlias(parsed) {
  let found = false;
  visit(parsed.contents ?? null, (_key, node) => {
    if (isAlias(node)) {
      found = true;
      return visit.BREAK;
    }
  });
  return found;
}

// size cap -> alias check -> YAML parse errors -> mapping check ->
// coerceTop, operating on the Stamp fence contents.
/**
 * @param {string} fm
 * @returns {ExtractResult}
 */
function parseStamp(fm) {
  const byteLength = Buffer.byteLength(fm, "utf8");
  if (byteLength > MAX_STAMP_BYTES) {
    return { doc: null, error: `Stamp is too large (${byteLength} bytes; limit is ${MAX_STAMP_BYTES}).` };
  }

  // YAML anchors/aliases are never needed in a shallow stamp and enable a
  // "billion laughs" expansion that detonates during parse. Reject them.
  const parsed = parseDocument(fm, { uniqueKeys: true, prettyErrors: false });

  if (parsed.errors.length > 0) {
    return { doc: null, error: `Stamp is not valid YAML: ${parsed.errors[0].message}` };
  }

  if (containsAlias(parsed)) {
    return { doc: null, error: "Stamp uses YAML anchors/aliases, which are not allowed." };
  }

  // No aliases were found anywhere in the tree, so materializing it now
  // cannot trigger expansion; maxAliasCount: 0 is passed as a defense-in-
  // depth backstop in case the walk above ever misses a node type.
  const raw = parsed.toJS({ maxAliasCount: 0 });

  if (raw === null || typeof raw !== "object" || Array.isArray(raw)) {
    return { doc: null, error: "Stamp parsed but is not a mapping of fields." };
  }

  return { doc: coerceTop(raw), error: null };
}

// Convert the parsed YAML mapping into a normalized plain-object document:
// rigor -> canonical code; vouch and checks -> yes/no-coerced strings.
/**
 * @param {Object<string, any>} raw
 * @returns {Object<string, any>}
 */
function coerceTop(raw) {
  const obj = {};
  for (const key of Object.keys(raw)) {
    const v = raw[key];
    switch (key) {
      case "rigor":
        obj[key] = normalizeRigor(yamlScalarToString(v));
        break;
      case "vouch":
        obj[key] = coerceVouch(v);
        break;
      case "checks":
        obj[key] = coerceChecks(v);
        break;
      case "spec":
      case "assessed":
        // Both must end up as strings. An unquoted spec value like `0.3`
        // parses as a JS number under the YAML 1.2 core schema (dates parse
        // as strings already); yamlScalarToString reprints any non-string
        // scalar as its literal text so these two fields stay strings
        // regardless of how the author quoted them.
        obj[key] = yamlScalarToString(v);
        break;
      default:
        obj[key] = v;
    }
  }
  return obj;
}

// Vouch is a scalar (yes/neutral/withheld) or a {claim, why} mapping. Each
// value inside a mapping gets the same boolean coercion as the scalar form,
// since `claim` carries the same yes-shaped vocabulary value (an author
// writing `claim: true` means `claim: yes`).
/**
 * @param {any} v
 * @returns {any}
 */
function coerceVouch(v) {
  if (v !== null && typeof v === "object" && !Array.isArray(v)) {
    const h = {};
    for (const vk of Object.keys(v)) {
      h[vk] = coerceYesNo(v[vk]);
    }
    return h;
  }
  return coerceYesNo(v);
}

// A mapping is Norway-coerced per key. A non-mapping (list, scalar) is
// passed through with its real type PRESERVED, so the schema's
// `checks: {type: object}` rejects it instead of it being silently dropped.
/**
 * @param {any} v
 * @returns {any}
 */
function coerceChecks(v) {
  if (v !== null && typeof v === "object" && !Array.isArray(v)) {
    const h = {};
    for (const ck of Object.keys(v)) {
      h[ck] = coerceYesNo(v[ck]);
    }
    return h;
  }
  return v;
}

// Authors write `comprehended: yes`, and the vocabulary wants that string
// back; under the yaml package's YAML 1.2 core schema, `yes`/`no` already
// arrive that way, so this only fires for a literal `true`/`false` scalar,
// mapping it onto its vocabulary equivalent. A non-boolean scalar (e.g.
// "not-applicable") is returned unchanged.
/**
 * @param {any} v
 * @returns {any}
 */
function coerceYesNo(v) {
  if (v === true) return "yes";
  if (v === false) return "no";
  return v;
}

/**
 * @param {any} v
 * @returns {string}
 */
function yamlScalarToString(v) {
  if (typeof v === "string") return v;
  if (v === null || v === undefined) return "";
  return String(v);
}
