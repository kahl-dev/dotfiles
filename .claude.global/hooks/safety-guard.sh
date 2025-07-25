#!/usr/bin/env bash

echo "$(date): Safety guard checking tool: $CLAUDE_TOOL_NAME" >> /tmp/claude-hook-debug.log

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

COMMAND_LINE="$*"

if [[ "$CLAUDE_TOOL_NAME" == "Bash" ]]; then
    echo "$(date): [$$] $COMMAND_LINE" >> ~/.claude.store/user-level/bash_audit.log
fi

DANGEROUS_PATTERNS=(
    "rm -rf /"
    "rm -rf \*"
    "rm -rf ~"
    "rm -rf \$HOME"
    "chmod 777 /"
    "chmod -R 777"
    "chown -R .* /"
    "dd if=/dev/zero"
    "dd if=.*of=/dev/sd"
    "dd if=.*of=/dev/nvme"
    "mkfs\."
    "fdisk /dev/sd"
    "fdisk /dev/nvme"
    "> /dev/sd"
    "> /dev/nvme"
    "curl.*|.*sh"
    "wget.*|.*sh"
    "curl.*|.*bash"
    "wget.*|.*bash"
    "sudo rm -rf"
    "sudo dd"
    "sudo mkfs"
    "sudo fdisk"
    ":(){:|:&};:"
)

LONG_RUNNING_PATTERNS=(
    "npm run dev"
    "yarn dev"
    "pnpm dev"
    "bun dev"
    "npm start"
    "yarn start" 
    "pnpm start"
    "npm run serve"
    "yarn serve"
    "npm run watch"
    "yarn watch"
    "make dev"
    "make serve"
    "make watch"
    "cargo run.*--watch"
    "cargo watch"
    "python.*manage\.py runserver"
    "python.*runserver"
    "rails server"
    "rails s"
    "php.*serve"
    "webpack.*--watch"
    "webpack-dev-server"
    "vite.*--watch"
    "rollup.*--watch"
    "nodemon"
    "pm2 start"
    "forever start"
    "jest.*--watch"
    "vitest.*--watch"
    "cypress open"
    "playwright.*--ui"
    "tailwindcss.*--watch"
    "sass.*--watch"
    "less.*--watch"
    "docker-compose up[^-d]"
    "docker run.*-it"
    ".*&$"
    "nohup"
    "screen.*-S"
    "tmux new-session"
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
    if [[ "$COMMAND_LINE" =~ $pattern ]]; then
        echo -e "${RED}🚫 BLOCKED: Potentially dangerous command detected${NC}" >&2
        echo -e "${RED}   Pattern: $pattern${NC}" >&2
        echo -e "${RED}   Command: $COMMAND_LINE${NC}" >&2
        echo -e "${YELLOW}   Reason: This command could damage your system${NC}" >&2
        echo -e "${YELLOW}   💡 If this is intentional, run the command manually in a terminal${NC}" >&2
        echo "$(date): BLOCKED dangerous command: $COMMAND_LINE" >> ~/.claude.store/user-level/blocked_commands.log
        exit 2
    fi
done

for pattern in "${LONG_RUNNING_PATTERNS[@]}"; do
    if [[ "$COMMAND_LINE" =~ $pattern ]]; then
        echo -e "${YELLOW}🚫 BLOCKED: Long-running command detected${NC}" >&2
        echo -e "${YELLOW}   Command: $COMMAND_LINE${NC}" >&2
        echo -e "${YELLOW}   Reason: This command runs indefinitely and would block Claude${NC}" >&2
        echo -e "${YELLOW}   💡 Run this command manually in a separate terminal:${NC}" >&2
        echo -e "${GREEN}      $COMMAND_LINE${NC}" >&2
        echo "$(date): BLOCKED long-running command: $COMMAND_LINE" >> ~/.claude.store/user-level/blocked_commands.log
        exit 2
    fi
done

if [[ "$CLAUDE_TOOL_NAME" == "Bash" ]] && [[ "$COMMAND_LINE" =~ git.*push ]]; then
    echo -e "${YELLOW}⚠️  Git push detected - logging for audit${NC}" >&2
    echo "$(date): [$$] Git push: $COMMAND_LINE" >> ~/.claude.store/user-level/git_push_log.txt
fi

if [[ "$COMMAND_LINE" =~ (npm|yarn|pnpm).*install ]]; then
    echo -e "${GREEN}📦 Package installation detected - allowing${NC}" >&2
fi

echo "$(date): Safety check passed for: $COMMAND_LINE" >> /tmp/claude-hook-debug.log
exit 0