# Dotfiles

## Installation

Clone the repository and install the dotfiles:

```zsh
git clone https://github.com/kahl-dev/dotfiles.git ~/.dotfiles && cd ~/.dotfiles && ./install
```

## Post-Installation

If everything is up and running change the dotfiles remote URL to SSH:

```zsh
cd ~/.dotfiles && git remote set-url origin git@github.com:kahl-dev/dotfiles.git
```

### [Alfred](https://www.alfredapp.com/)

[Alfred](https://www.alfredapp.com/) is synced vie iCloud Drive. To make this happen there is a setting in
iCloud Drive that needs to be disabled. Open System Settings and click on your
name at the top. Then select iCloud and disable Optimise Mac Storage.
After that start [Alfred](https://www.alfredapp.com/) and set the sync folder to:

```zsh
/Users/$(whoami)/.icloud/.backup/alfred
```

### [Mackup](https://github.com/lra/mackup)

[Mackup](https://github.com/lra/mackup) is used to sync application settings. Its been installed as default
package with the install script of this repo so it should be available.
Simply run the following command to restore all:

```zsh
mackup restore
```

## Todos

- [x] Rewrite to use `brew bundle` commands.
- [x] Look into [Mackup](https://github.com/lra/mackup) for syncing application settings.
- [ ] Disable mission control auto rearrange.
- [ ] Try out [yazi](https://github.com/sxyazi/yazi) as terminal file manager
- [ ] Use trash-cli instead of rm on macOS
- [ ] Move node/fnm/yarn/pnpm installation with dotbot
- [ ] Transform vscode to look more like my neovim setup (theme, font, etc.)
- [ ] Make starship prompt more pure [omerxx config](https://github.com/omerxx/dotfiles/blob/master/starship/starship.toml)
- [ ] Clean zsh and old install script even more
- [ ] Add better dotbot scripts - Maybe something like ingredients and recipes - Or multiple install/update scripts - Add config for work dev server
- [ ] Show infos like heredoc/array etc in zsh prompt (starship?)
- [ ] Hanndle max line warning in obsidian markdown files
      MD013/line-length Line length [Expected: 80; Actual: 190]
