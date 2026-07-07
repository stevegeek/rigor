# rigor-md

A CLI for **RIGOR.md** stamps: a small, first-person disclosure block that
says how carefully a piece of code was reviewed, who did the work, and
whether the author is willing to vouch for it. This package is the Node.js
port of the [Rigor](https://github.com/stevegeek/rigor) Crystal CLI — same
commands, same `rigor.schema.json` vocabulary, byte-parity tested against
the original binary.

See the [project README](https://github.com/stevegeek/rigor#readme) for the
full pitch, and [SPEC.md](https://github.com/stevegeek/rigor/blob/main/SPEC.md)
for the stamp format itself (rigor levels, vouch, checks, stages).

## Usage

No install required:

```sh
npx rigor-md init                          # scaffold a RIGOR.md stamp
npx rigor-md validate RIGOR.md --strict    # structural + semantic checks
npx rigor-md fmt RIGOR.md                  # regenerate the summary block
npx rigor-md embed RIGOR.md                # print a paste-ready README line
npx rigor-md schema                        # print the embedded JSON Schema
```

Or install it as a dev dependency and wire it into CI:

```sh
npm install --save-dev rigor-md
npx rigor validate RIGOR.md --strict --readme README.md
```

Run `npx rigor-md --help` for the full command list.

## Requirements

Node.js >= 18.
