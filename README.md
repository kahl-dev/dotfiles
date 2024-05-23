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
