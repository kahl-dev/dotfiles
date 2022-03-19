# Dotfiles

> This are my dotfiles

## DOCS

 * [SSH](./docs/SSH.md)

# OLD PART

## Install

```
$ cd ~
$ git clone --recursive git@github.com:patrickkahl/dotfiles.git .dotfiles
$ cd .dotfiles
$ ./install-profile osx
```

## Applications and tools

All necessary applications and tools are installed with the installation script.

The following must be installed manually.

- PixelSnap
- Microsoft Office
- Adobe Cloud
- Parallels

## OS X Settings

This script will set all my favorite OS X settings

```
$ .~/.dotfiles/sh/osx.sh
```

The following must be set manually

- System Preferences -> Keyboard -> Modifier Keys -> Caps Look -> Control
- System Preferences -> Monitor -> Scaled -> More space

## Remove some tools from autostart

- [FortiClient](https://forum.fortinet.com/tm.aspx?m=97324#msgNum5)
- [Tunnelblick](https://tunnelblick.net/cLaunchAtLogin.html)

## Alfred Workflows

Run this npm alias to install all required Alfred workflows

```
$ npmida
```

The following must be installed manually

- [AppCleaner](https://github.com/aiyodk/Alfred-Extensions/blob/master/AlfredApp_2.x/AppCleaner/AppCleaner.alfredworkflow)
- [Search Browser tabs](http://www.packal.org/workflow/search-browser-tabs)
- [Pinboard](https://github.com/spamwax/alfred-pinboard-rs)
- [Numi](http://www.packal.org/workflow/numi)
- [Translate](http://www.packal.org/workflow/translate)
- [defaultbrowser-alfred-workflow](https://github.com/stuartcryan/defaultbrowser-alfred-workflow)

## Fix colors

Run the colortest at 
```
$ ~/.dotfiles/zsh/custom/plugins/base16-shell/colortest 
```
## License

MIT © [Patrick Kahl](https://github.com/patrickkahl)
