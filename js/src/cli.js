// Port of src/rigor/cli.cr.
//
// Flag parsing note (porting contract deviation, deliberate): Crystal uses
// `OptionParser`, a full-featured parser supporting short flags, bundled
// short options, `--flag=value`/`--flag value` forms, and a
// `gnu_optional_args` mode. Every flag this CLI actually declares is either
// a boolean switch (`--force`, `--strict`, `--json`) or a long flag that
// takes exactly one required value (`--rigor V`, `--readme PATH`, etc) —
// no short flags, no optional-value flags are ever registered. `parseFlags`
// below is a hand-rolled parser scoped to exactly that subset: it recognizes
// `--flag value` and `--flag=value` for value flags, bare `--flag` for
// booleans, and treats anything else as positional (mirroring
// `OptionParser#unknown_args`). It does not replicate Crystal's behavior for
// unrecognized `--flag`-shaped arguments (which raises `InvalidOption` and
// crashes the process) since no spec in either suite exercises that path.

import * as Init from "./commands/init.js";
import * as Validate from "./commands/validate.js";
import * as Embed from "./commands/embed.js";
import * as Schema from "./commands/schema.js";
import * as Fmt from "./commands/fmt.js";

/** Mirrors Rigor::VERSION (src/rigor.cr) — the CLI's own version string,
 * independent of the js/package.json npm package version. */
export const VERSION = "0.2.0";

const BANNER_LINES = [
  "rigor - Rigor/Vouch/Stages disclosure tool",
  "",
  "Usage: rigor <command> [options]",
  "",
  "Commands:",
  "  init      Scaffold a RIGOR.md stamp",
  "  validate  Validate a RIGOR.md (structural + semantic)",
  "  embed     Print the paste-ready README line",
  "  schema    Print the embedded JSON Schema",
  "  fmt       Regenerate the summary from the stamp",
];

export const BANNER = BANNER_LINES.join("\n");

/**
 * @param {string} [str]
 */
function stdoutPuts(str = "") {
  process.stdout.write(str);
  if (!str.endsWith("\n")) process.stdout.write("\n");
}

/** @returns {{puts: (str?: string) => void}} */
function defaultOut() {
  return { puts: stdoutPuts };
}

/** Today's date, local timezone, as YYYY-MM-DD (mirrors `Time.local.to_s("%Y-%m-%d")`).
 * @returns {string}
 */
function today() {
  const d = new Date();
  const y = String(d.getFullYear()).padStart(4, "0");
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

/**
 * @param {string[]} args
 * @param {Object<string, "value"|"boolean">} spec flag name (with leading --) -> kind
 * @returns {{values: Object<string, string|boolean>, positional: string[]}}
 */
function parseFlags(args, spec) {
  const values = {};
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    const eq = arg.startsWith("--") ? arg.indexOf("=") : -1;
    const name = eq === -1 ? arg : arg.slice(0, eq);
    if (Object.prototype.hasOwnProperty.call(spec, name)) {
      if (spec[name] === "boolean") {
        values[name] = true;
      } else if (eq !== -1) {
        values[name] = arg.slice(eq + 1);
      } else {
        values[name] = args[i + 1] ?? "";
        i += 1;
      }
    } else {
      positional.push(arg);
    }
  }
  return { values, positional };
}

/**
 * @param {string[]} argv
 * @param {{puts: (str?: string) => void}} [out]
 * @returns {number}
 */
export function run(argv, out = defaultOut()) {
  if (argv.length === 0) {
    out.puts(BANNER);
    return 2;
  }
  const command = argv[0];
  const rest = argv.slice(1);

  switch (command) {
    case "init": {
      const { values, positional } = parseFlags(rest, {
        "--rigor": "value",
        "--vouch": "value",
        "--vouch-why": "value",
        "--idea-by": "value",
        "--idea-depth": "value",
        "--plan-by": "value",
        "--plan-depth": "value",
        "--implementation-by": "value",
        "--maintenance-by": "value",
        "--maintenance-activity": "value",
        "--assessed": "value",
        "--force": "boolean",
      });
      const rigor = values["--rigor"] ?? "comprehended";
      const vouch = values["--vouch"] ?? "neutral";
      const vouchWhy = values["--vouch-why"] ?? null;
      const assessedFlag = values["--assessed"];
      const assessed = assessedFlag === undefined ? today() : assessedFlag === "none" ? null : assessedFlag;
      const force = values["--force"] === true;

      const stages = {};
      /**
       * @param {string} name
       * @param {string} field
       * @param {string|undefined} v
       */
      const setStage = (name, field, v) => {
        if (v === undefined) return;
        if (!stages[name]) stages[name] = {};
        stages[name][field] = v;
      };
      setStage("idea", "by", values["--idea-by"]);
      setStage("idea", "depth", values["--idea-depth"]);
      setStage("plan", "by", values["--plan-by"]);
      setStage("plan", "depth", values["--plan-depth"]);
      setStage("implementation", "by", values["--implementation-by"]);
      setStage("maintenance", "by", values["--maintenance-by"]);
      setStage("maintenance", "activity", values["--maintenance-activity"]);

      return Init.run(positional[0] ?? ".", rigor, vouch, stages, assessed, force, out, vouchWhy);
    }
    case "validate": {
      const { values, positional } = parseFlags(rest, {
        "--strict": "boolean",
        "--json": "boolean",
        "--readme": "value",
      });
      if (positional.length === 0) {
        out.puts("usage: rigor validate <file> [--strict] [--json] [--readme PATH]");
        return 2;
      }
      return Validate.run(
        positional[0],
        values["--strict"] === true,
        values["--json"] === true,
        out,
        values["--readme"] ?? null,
      );
    }
    case "embed": {
      const { positional } = parseFlags(rest, {});
      if (positional.length === 0) {
        out.puts("usage: rigor embed <file>");
        return 2;
      }
      return Embed.run(positional[0], out);
    }
    case "schema":
      return Schema.run(out);
    case "fmt": {
      const { positional } = parseFlags(rest, {});
      if (positional.length === 0) {
        out.puts("usage: rigor fmt <file>");
        return 2;
      }
      return Fmt.run(positional[0], out);
    }
    case "-h":
    case "--help":
    case "help":
      out.puts(BANNER);
      return 0;
    case "--version":
      out.puts(VERSION);
      return 0;
    default:
      out.puts(`unknown command: ${command}`);
      out.puts(BANNER);
      return 2;
  }
}
