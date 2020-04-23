if [ -d "$HOME/.asdf" ]; then
  plugins+=(asdf)

  initAsdfPlugins() {
    if ! (asdf plugin list | grep -q 'nodejs'); then
      asdf plugin add nodejs
      bash ~/.asdf/plugins/nodejs/bin/import-release-team-keyring
    fi
  }

  after_init+=(initAsdfPlugins)
fi
