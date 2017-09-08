#!/usr/bin/env bash

mas upgrade

appstoreapps=(
407963104 # pixelmator // photo editing app
1063996724 # tyme // time tracking tool
# 441258766 # magnet // window managment
1107421413 # 1blocker // adblock
1094255754 # outbank // banking app
410968114 # pdfscanner // document scanner
918858936 # airmail // mail app
557168941 # tweetbot // twitter app
497799835 # xcode
1160374471 # Pipifier // picture in picture for all videos
890031187 # marked 2
409203825 # numbers
409201541 # pages
)

for pkg in ${appstoreapps[@]}; do
  if (mas list | grep "^${pkg}" >$ /dev/null); then
    mas install ${pkg}
  fi
done
