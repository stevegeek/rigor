// Port of src/rigor/commands/init.cr.

import { existsSync, writeFileSync } from "node:fs";
import path from "node:path";
import { normalizeRigor } from "../document.js";
import { STAGE_KEYS } from "../vocabulary.js";
import { block } from "../summary.js";
import { emit } from "../stamp-yaml.js";
import { structural, semantic } from "../validator.js";

/**
 * @param {string} dir
 * @param {string} rigor
 * @param {string} vouch
 * @param {Object<string, Object<string, string>>} stages
 * @param {string|null} assessed
 * @param {boolean} force
 * @param {{puts: (str?: string) => void}} out
 * @param {string|null} [vouchWhy]
 * @returns {number}
 */
export function run(dir, rigor, vouch, stages, assessed, force, out, vouchWhy = null) {
  const filePath = path.join(dir, "RIGOR.md");
  if (existsSync(filePath) && !force) {
    out.puts(`error: ${filePath} already exists (use --force to overwrite)`);
    return 1;
  }

  const doc = {};
  doc["spec"] = "0.3";
  doc["rigor"] = normalizeRigor(rigor);
  doc["vouch"] = vouchWhy ? { claim: vouch, why: vouchWhy } : vouch;
  if (Object.keys(stages).length > 0) {
    const st = {};
    for (const k of STAGE_KEYS) {
      const fields = stages[k];
      if (!fields) continue;
      st[k] = { ...fields };
    }
    doc["stages"] = st;
  }
  if (assessed) doc["assessed"] = assessed;

  let errors = structural(doc);
  if (errors.length === 0) {
    ({ errors } = semantic(doc, false));
  }
  if (errors.length > 0) {
    out.puts("error: refusing to write an invalid stamp:");
    for (const e of errors) out.puts(`  ${e}`);
    return 1;
  }

  const lines = [
    "# Who made this, and how carefully",
    "",
    block(doc),
    "",
    "## Notes",
    "",
    "Why the level is what it is, what was and was not checked, and anything",
    "the plain summary above cannot carry.",
    "",
    "## Stamp",
    "",
    "```yaml",
    `${emit(doc)}\`\`\``,
    "",
    "<!--",
    "checks: surface any subset under the stamp; done-values carry the actor.",
    "  comprehended: yes | no          (can a human explain every line?)",
    "  quality_reviewed / security_reviewed / tested: human | ai | human-with-ai | yes | no | not-applicable",
    "  owned: yes | no                 (architectural responsibility)",
    "Run `rigor fmt RIGOR.md` after editing the stamp to refresh the summary.",
    "-->",
  ];
  writeFileSync(filePath, lines.join("\n"));

  out.puts(`wrote ${filePath}`);
  return 0;
}
