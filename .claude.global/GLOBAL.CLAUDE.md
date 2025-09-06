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

## 📚 Documentation Maintenance

@instructions/documentation-maintenance.md

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

## 🐙 GitHub Project Management

**Use `gh` CLI over MCP servers for GitHub operations.**

## 📋 Enhanced Analysis Workflows

When handling complex tasks, automatically apply progressive thinking:

**Code Review & Analysis:**
- Small changes (< 5 files): Standard review
- Medium changes (5-20 files): `think` about cross-file interactions
- Large changes (20+ files): `think hard` about system architecture impact
- Security-sensitive: Always `think hard` about attack vectors
- Performance-critical: `think harder` about bottlenecks and scaling

**Commit Analysis:**
- Before any commit: `think hard` about change implications
- Multi-file commits: Analyze dependencies and integration points
- Breaking changes: `think harder` about migration paths and backwards compatibility
- Production deployments: `ultrathink` about failure scenarios

## 🎫 Jira Response Pattern

@instructions/jira-responses.md

## ⚡ Efficiency Patterns

@instructions/efficiency.md

## 🎨 Visual Development

- Use Playwright MCP server when making visual changes to front-end to check your work
- Always validate visual changes with browser snapshots
- Test user interactions after implementing UI components

## 🧭 Guidance & Clarification

- Ask for clarification upfront when you need more direction on initial prompts
- Present clear options and wait for user choice when approach is ambiguous
- Request specific requirements when user requests are too broad

## 🚨 System Load & Background Task Safety

**CRITICAL:** Claude Code background tasks can fail with `spawn pgrep EAGAIN` during high system load, causing the entire session to crash.

### Automatic Protections in Place

This system has multi-layer protection against system overload:

1. **System Load Guard Hook** (`~/.claude/hooks/system-load-guard.sh`)
   - Blocks tool execution when load > 10.0 (critical)  
   - Warns when load > 5.0 during background tasks
   - Tests process spawning capability before execution
   - Logs all load-related decisions

2. **Resource-Conscious Session Tracking**
   - tmux status updates skip when load > 8.0
   - Background process spawning is load-aware
   - Process accumulation prevention

### Claude Code Usage Guidelines

**Before Background Tasks:**
- Check system load: `uptime`
- Wait if load > 5.0 before using `run_in_background: true`
- Use shorter timeouts for potentially problematic tests

**If You See `spawn pgrep EAGAIN`:**
1. **Immediately check load**: `uptime`
2. **Kill runaway processes**: `ps aux | head -20` then `kill -9 <PID>`
3. **Wait for load < 3.0** before retrying background tasks
4. **Use direct terminal commands** instead of Claude Code during high load periods

**Background Task Best Practices:**
- Keep background processes short (< 30 seconds)
- Use `timeout` wrapper: `timeout 60s npm test`
- Monitor with `uptime` before each background task
- Close unused Claude Code sessions (check `ps aux | grep claude`)

### Common Culprits
- **Runaway test suites** (vitest, jest hanging)
- **Multiple Claude Code sessions** (check with `ps aux | grep claude`)
- **High graphics load** (WindowServer > 30% CPU)
- **Development servers left running** (npm run dev processes)

### Emergency Cleanup Commands
```bash
# Check system load
uptime

# Find resource hogs
ps aux | head -20

# Kill runaway tests
pkill -f vitest
pkill -f jest

# Kill excess Claude sessions (keep only current)
ps aux | grep claude | grep -v $$ | awk '{print $2}' | head -5 | xargs kill

# Check improved load
uptime
```

The system load guard will automatically prevent operations during critical load periods, but monitoring system health proactively prevents issues.


## 🖥️ Server Environments

- When working on a "Linux typo3" remove server, note that it is:
  - Without a GUI
  - Without a browser
  - Behind an htaccess authentication
  - When using tools like Playwright, MCP, or other calls on Linux typo3, use the `BURRITODEV_HTACCESS_USER` and `BURRITODEV_HTACCESS_PW` environment variables to access the URLs

## 📚 Claude Code System Knowledge

This section imports comprehensive documentation about Claude Code features, system configuration, hooks, and slash commands.

@.claude.global/CLAUDE.md

