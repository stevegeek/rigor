// Mirrors spec/spec_helper.cr's stamp_doc.

/**
 * @param {string} yaml
 * @returns {string}
 */
export function stampDoc(yaml) {
  return `# T\n\n## Stamp\n\n\`\`\`yaml\n${yaml}\n\`\`\`\n`;
}
