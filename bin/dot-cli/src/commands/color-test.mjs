import 'zx/globals'

export const command = {
  command: 'color-test',
  desc: 'Execute a color test',
  handler: async () => {
    console.log(chalk.cyan('\nExecuting color test...'))
    await $`/bin/bash $DOTFILES/scripts/color_test_command.sh`
  },
}
