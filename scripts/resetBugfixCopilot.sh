#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

cd ~/.local/share/nvim/lazy/copilot.lua/copilot
git checkout dist/agent.js
