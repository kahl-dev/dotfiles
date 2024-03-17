import { Command } from 'commander';
import 'zx/globals'
import { commandExists, askYesNo, isOSX, changeCommandWithSpinner } from '../utils.js';


export function registerUpdateCommand(program: Command): void {
  program
    .command('update')
    .description('Update dotfiles and related software')
    .action(async () => {
      const options = program.opts();
      const allYes = options.yes || false;

      console.log(chalk.cyan('Starting the update process...'));


      // Update LazyVim
      let lazyVimUpdated = false;
      if (await commandExists('nvim')) {
        if (allYes || await askYesNo('Do you want to update LazyVim?')) {
          console.log(chalk.cyan('\nUpdating LazyVim...'));
          await changeCommandWithSpinner('Updating Lazyvim packages...', $`nvim --headless '+Lazy! update' +qa`)
          lazyVimUpdated = true;
        } else {
          console.log(chalk.cyan('\nLazyVim update skipped.'));
        }
      }

      // Update Homebrew
      if (await commandExists('brew')) {
        if (allYes || await askYesNo('Do you want to update Homebrew packages?')) {
          console.log(chalk.cyan('\nUpdating Homebrew...'));
          await changeCommandWithSpinner('Updating Homebrew packages...', $`brew update`)
          console.log(chalk.cyan('\nUpgrading Homebrew packages...'));
          await changeCommandWithSpinner('Upgrade Homebrew packages...', $`brew upgrade`)
          console.log(chalk.cyan('\nCleaning up Homebrew packages...'));
          await changeCommandWithSpinner('Cleaning up Homebrew packages...', $`brew cleanup -s`)
        } else {
          console.log(chalk.cyan('\nHomebrew update skipped.'));
        }
      }

      if (isOSX()) {
        if (allYes || await askYesNo('Do you want to update App Store packages with mas?')) {
          console.log(chalk.cyan('\nUpdating App Store...'));
          await changeCommandWithSpinner('Update App Store...', $`mas upgrade`)
        } else {
          console.log(chalk.cyan('\nApp Store update skipped.'));
        }

        if (allYes || await askYesNo('Do you want to update the System?')) {
          console.log(chalk.cyan('\nUpdating the system...'));
          await changeCommandWithSpinner('Update system...', $`softwareupdate -i -a`)
        } else {
          console.log(chalk.cyan('\nSystem update skipped.'));
        }
      }

      // Reminder for manual updates
      console.log(chalk.cyan('Remember to update node and npm packages manually.'));
      if (!lazyVimUpdated) {
        console.log(chalk.blue('Please also update Mason LSPs manually.'));
      }
    });
}

