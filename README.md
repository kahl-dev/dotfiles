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
- [x] Disable mission control auto rearrange.
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
- [ ] Catpuchino theme for more apps ([catppuccin](https://github.com/catppuccin/catppuccin?tab=readme-ov-file))
- [ ] look into [bat-extras](https://github.com/eth-p/bat-extras)
- [ ] Fix neovim checkhealth:
      ```
      - Nvim node.js host: /home/kahl/.local/share/fnm/aliases/lts-latest/bin/node
      - ERROR Failed to run: node /home/kahl/.local/share/fnm/aliases/lts-latest/bin/node --version
        - ADVICE:
          - Report this issue with the output of: 
          - node /home/kahl/.local/share/fnm/aliases/lts-latest/bin/node --version
      ```
- [ ] find a way to put encrypted files into dotfiles and kick .dotfiles-local
- [ ] Add [fabric](https://github.com/danielmiessler/fabric) config to dotfiles
- [ ] add some apps to show in all desktops on osx programmatically (like music, toggle, etc.). Can be done by right click on app in dock -> options -> all desktops
- [ ] try out an [neovim extension](https://www.youtube.com/watch?v=ig_HLrssAYE) for making screenshots
