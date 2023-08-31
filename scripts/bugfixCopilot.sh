#!/bin/bash

source ./scripts/config.sh
source ./scripts/functions.sh

if _is_osx; then
	sed -i '' 's/\["\\n"\]/["\\n\\n\\n"]/' ~/.local/share/nvim/lazy/copilot.lua/copilot/dist/agent.js
else
	sed -i 's/\["\\n"\]/["\\n\\n\\n"]/' ~/.local/share/nvim/lazy/copilot.lua/copilot/dist/agent.js
fi
