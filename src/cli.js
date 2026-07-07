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
// `OptionParser#unknown_args`).
//
// Strictness parity: Crystal's OptionParser dies (unhandled exception, exit
// 1) on an unrecognized `--flag`, on a boolean flag written as
// `--flag=value`, and on a value-flag with nothing following it.
// `parseFlags` rejects all three shapes too, returning an `error` string
// instead of silently accepting them. Deviation: message text
// ("error: invalid option: <token>" / "error: missing value for <flag>") is
// a deliberate, humane departure from Crystal's raw exception backtrace;
// parity: exit code (both runtimes exit 1). Because Crystal's side of this
// path is an unhandled-exception backtrace rather than a stable string, a
// cross-runtime parity gate must compare exit codes only for these three
// argv shapes, never message text — do not add these shapes to any
// message-parity matrix.

import * as Init from "./commands/init.js";
import * as Validate from "./commands/validate.js";
import * as Embed from "./commands/embed.js";
import * as Schema from "./commands/schema.js";
import * as Fmt from "./commands/fmt.js";

/** Mirrors the retired Rigor::VERSION (formerly src/rigor.cr) — the CLI's
 * own version string, independent of package.json's npm package version. */
export const VERSION = "0.3.0";

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
 * @returns {{values: Object<string, string|boolean>, positional: string[], error: string|null}}
 */
function parseFlags(args, spec) {
  const values = {};
  const positional = [];
  for (let i = 0; i < args.length; i++) {
    const arg = args[i];
    const isFlag = arg.startsWith("--");
    const eq = isFlag ? arg.indexOf("=") : -1;
    const name = eq === -1 ? arg : arg.slice(0, eq);
    if (isFlag && Object.prototype.hasOwnProperty.call(spec, name)) {
      if (spec[name] === "boolean") {
        if (eq !== -1) {
          // `--force=true`: Crystal's OptionParser has no notion of a
          // value attached to a zero-arg switch and raises InvalidOption;
          // mirror that instead of silently discarding the `=value`.
          return { values, positional, error: `invalid option: ${arg}` };
        }
        values[name] = true;
      } else if (eq !== -1) {
        values[name] = arg.slice(eq + 1);
      } else if (i + 1 < args.length) {
        values[name] = args[i + 1];
        i += 1;
      } else {
        // `--readme` at argv end: no following value to consume.
        return { values, positional, error: `missing value for ${name}` };
      }
    } else if (isFlag) {
      // Unrecognized `--flag`-shaped arg: Crystal's OptionParser raises
      // InvalidOption for these rather than treating them as positional.
      return { values, positional, error: `invalid option: ${arg}` };
    } else {
      positional.push(arg);
    }
  }
  return { values, positional, error: null };
}

/**
 * @param {{error: string|null}} parsed
 * @param {{puts: (str?: string) => void}} out
 * @returns {boolean} true if `parsed.error` was set (and reported); caller should return exit code 1
 */
function reportFlagError(parsed, out) {
  if (parsed.error === null) return false;
  out.puts(`error: ${parsed.error}`);
  return true;
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
      const parsed = parseFlags(rest, {
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
      if (reportFlagError(parsed, out)) return 1;
      const { values, positional } = parsed;
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
      const parsed = parseFlags(rest, {
        "--strict": "boolean",
        "--json": "boolean",
        "--readme": "value",
      });
      if (reportFlagError(parsed, out)) return 1;
      const { values, positional } = parsed;
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
      const parsed = parseFlags(rest, {});
      if (reportFlagError(parsed, out)) return 1;
      const { positional } = parsed;
      if (positional.length === 0) {
        out.puts("usage: rigor embed <file>");
        return 2;
      }
      return Embed.run(positional[0], out);
    }
    case "schema":
      return Schema.run(out);
    case "fmt": {
      const parsed = parseFlags(rest, {});
      if (reportFlagError(parsed, out)) return 1;
      const { positional } = parsed;
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
