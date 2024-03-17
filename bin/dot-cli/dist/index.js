#!/usr/bin/env node
import { Command } from 'commander';
import { registerUpdateCommand } from './commands/update.js';
import { registerColorTestCommand } from './commands/color-test.js';
import { registerLinkCommand } from './commands/link.js';
import { readPackageSync } from 'read-pkg';
const program = new Command();
program
    .version(readPackageSync().version)
    .option('-y, --yes', 'Skip all confirmation prompts')
    .description('Dotfiles management tool');
registerUpdateCommand(program);
registerColorTestCommand(program);
registerLinkCommand(program);
program.parse(process.argv);
