import { Command } from 'commander';
import 'zx/globals'
import { commandExists } from '../utils.js';


export function registerColorTestCommand(program: Command): void {
  program
    .command('color-test')
    .description('Execute a color test')
    .action(async () => {
      if (await commandExists('nvim')) {
        console.log(chalk.cyan('\nExecuting color test...'));
        await $`sh $DOTFILES/scripts/color_test_command.sh`
      }
    });
}

