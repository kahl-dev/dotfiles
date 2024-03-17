import 'zx/globals';
console.log('Imported link.ts');
export function registerLinkCommand(program) {
    program
        .command('link')
        .description('Symlink dotfiles')
        .action(async () => {
        console.log(chalk.cyan('\nCreating symlinks...'));
        await $ `sh $DOTFILES/scripts/createSymlinks.sh`;
    });
}
