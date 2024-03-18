#!/usr/bin/env node

import yargs from 'yargs';
import { hideBin } from 'yargs/helpers';
import { readPackageSync } from 'read-pkg';
import { commands } from './commands/index.mjs';

const packageJson = readPackageSync();

yargs(hideBin(process.argv))
  .scriptName("dot-cli")
  .usage('$0 <cmd> [args]')
  .command(commands)
  .version(packageJson.version)
  .showHelpOnFail(true)
  .help(
    'help',
    'Show usage instructions.'
  )
  .demandCommand()
  .completion('completion')
  .argv
