import { $, chalk } from 'zx';

export const command = {
  command: 'link',
  desc: 'Symlink dotfiles',
  handler: async () => {
    console.log(chalk.cyan('\nCreating symlinks...'));
    await $`sh $DOTFILES/scripts/createSymlinks.sh`;
  }
}

