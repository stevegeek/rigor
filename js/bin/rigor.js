#!/usr/bin/env node
// Port of src/main.cr (`exit Rigor::CLI.run(ARGV)`).

import { run } from "../src/cli.js";

process.exit(await run(process.argv.slice(2)));
