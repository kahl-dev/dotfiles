# https://www.chriswrites.com/update-apps-and-macos-without-ever-launching-the-app-store/
#!/bin/bash
brew update
brew outdated

mas outdated

softwareupdate -i
