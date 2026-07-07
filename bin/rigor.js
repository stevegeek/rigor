#!/usr/bin/env node
// CLI entry point: runs the command and exits with its status code.

import { run } from "../src/cli.js";

process.exit(await run(process.argv.slice(2)));
