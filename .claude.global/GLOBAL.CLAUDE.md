# 🧑‍💻 Instructions for people AND LLMs

## 📁 Global Claude Configuration

This file serves as the main entry point for global Claude Code instructions. All Claude-related configuration files are organized in the `.claude.global/` directory:

- **GLOBAL.CLAUDE.md** - This file with imports to all instruction modules
- **instructions/** - Modular instruction files imported via `@instructions/filename.md`
- **commands/** - Custom slash commands available across all projects
- **hooks/** - Hook scripts for tool execution events
- **settings.json** - Global Claude Code configuration
- **shared/** - Shared resources and utilities

These files are symlinked to `~/.claude/` via dotbot configuration for version control and consistency across machines.

## 🎨 Code Style

@instructions/code-style.md

## 🧪 Tests

@instructions/tests.md

# 🤖 Instructions for LLMs

## 🏗️ Development Workflow

@instructions/workflow.md

## 🚫 Essential Constraints

@instructions/constraints.md

## 🎨 Code Style

@instructions/llm-code-style.md

## 💻 Code Principles

@instructions/code-principles.md

## 💬 Communication

@instructions/conversation.md

## 🔨 Build Commands

@instructions/build-commands.md

## 🧠 LLM Context

@instructions/llm-context.md

## 📝 Git Commits

@instructions/llm-git-commits.md

## 🛠️ Tool Use

@instructions/tool-use.md

## 🚨 Hook Errors

@instructions/hook-errors.md

## 🤔 Problem Solving

@instructions/problem-solving.md

## 🔒 Security

@instructions/security.md

## 🔌 MCP Integration

@instructions/mcp-integration.md

## ⚡ Efficiency Patterns

@instructions/efficiency.md

## 🖥️ Server Environments

- When working on a "Linux typo3" remove server, note that it is:
  - Without a GUI
  - Without a browser
  - Behind an htaccess authentication
  - When using tools like Playwright, MCP, or other calls on Linux typo3, use the `BURRITODEV_HTACCESS_USER` and `BURRITODEV_HTACCESS_PW` environment variables to access the URLs

