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
  * Without a GUI
  * Without a browser
  * Behind an htaccess authentication
  * When using tools like Playwright, MCP, or other calls on Linux typo3, use the `BURRITODEV_HTACCESS_USER` and `BURRITODEV_HTACCESS_PW` environment variables to access the URLs

## 📚 Claude Code System Knowledge

### CLAUDE.md Files
- **Project memory**: `./CLAUDE.md` (team-shared instructions)
- **User memory**: `~/.claude/CLAUDE.md` (personal preferences across projects)
- Auto-loaded into context when Claude starts
- Support imports with `@path/to/file` syntax (max 5 hops)
- Discovered recursively up directory tree
- Quick addition with `#` prefix in chat
- Use `/memory` command to edit memories
- Use `/init` command to bootstrap project CLAUDE.md

### Hooks System

#### 📚 Documentation & Research
Before modifying any hooks:

1. **Use Context7 for current docs**:
   ```
   mcp__context7__resolve-library-id "claude code hooks"
   mcp__context7__get-library-docs <library-id>
   ```

2. **Official Anthropic Documentation**:
   - **Hooks Overview**: https://docs.anthropic.com/en/docs/claude-code/hooks
   - **Settings Configuration**: https://docs.anthropic.com/en/docs/claude-code/settings
   - **CLI Reference**: https://docs.anthropic.com/en/docs/claude-code/cli-reference
   - **Troubleshooting**: https://docs.anthropic.com/en/docs/claude-code/troubleshooting

#### 🔧 Hook Development Best Practices

**Hook Events Available:**
- `PreToolUse`: Before tool execution (can block)
- `PostToolUse`: After successful completion
- `UserPromptSubmit`: Before processing prompts
- `Stop`: When main agent finishes
- `PreCompact`: Before context compaction
- `Notification`: For tool permissions or idle periods
- `SubagentStop`: When sub-agent finishes

**JSON Input Format:**
```json
{
  "event": "PreToolUse",
  "tool": "Edit",
  "parameters": {...},
  "context": {...}
}
```

**Security Considerations:**
- Validate all inputs - hooks execute arbitrary shell commands
- Sanitize user data before processing
- Use absolute paths for script execution
- Set appropriate timeouts to prevent hanging
- Never trust external input without validation

**Tool Matching Patterns:**
- Use regex patterns like `"Write|Edit|MultiEdit"`
- Test patterns against actual tool names
- Consider case sensitivity
- Account for future tool additions

**Exit Codes & Control:**
- Exit 0: Allow tool execution
- Exit 1: Block tool execution
- JSON output: For complex decision control

**Hook Configuration (`~/.claude/settings.json`):**
```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Write|Edit",
      "hooks": [{
        "type": "command",
        "command": "~/.claude/hooks/validate-changes.sh",
        "timeout": 5000
      }]
    }]
  }
}
```

**🛡️ Security Checklist:**
- [ ] Input validation implemented
- [ ] No hardcoded secrets or credentials
- [ ] Appropriate error handling
- [ ] Timeout configured
- [ ] Permissions verified
- [ ] Shell injection prevention

**Debugging Commands:**
```bash
claude --debug              # Test hook execution
claude config get hooks     # Check configuration syntax
cat ~/.claude/settings.json | jq '.'  # Validate settings file
```

### Slash Commands & Custom Prompts

#### 📚 Documentation & Research
Before creating or modifying commands:

1. **Use Context7 for current docs**:
   ```
   mcp__context7__resolve-library-id "claude code slash commands"
   mcp__context7__get-library-docs <library-id>
   ```

2. **Official Anthropic Documentation**:
   - **Slash Commands**: https://docs.anthropic.com/en/docs/claude-code/slash-commands
   - **Settings Configuration**: https://docs.anthropic.com/en/docs/claude-code/settings
   - **Interactive Mode**: https://docs.anthropic.com/en/docs/claude-code/interactive-mode
   - **CLI Reference**: https://docs.anthropic.com/en/docs/claude-code/cli-reference

#### 🛠️ Command Development

**Command Types:**
- **Built-in**: `/help`, `/clear`, `/review`, `/model`, `/init`, `/memory`
- **Custom Project**: `.claude/commands/` (team-shared)
- **Custom Personal**: `~/.claude/commands/` (individual preferences)
- **MCP Commands**: `/mcp__<server-name>__<prompt-name>` (dynamic)

**Command Structure:**
```markdown
---
description: "Brief description of what this command does"
---

# Command Name

Your command prompt goes here.

Use $ARGUMENTS to accept user input:
- $ARGUMENTS - All arguments as single string
- ${ARGUMENTS:default value} - With default
- Can include bash commands with backticks
- Support file references and imports
```

**Naming Conventions:**
- Use descriptive names: `/analyze-logs` not `/al`
- Separate words with hyphens: `/check-tests`
- Avoid conflicts with built-in commands
- Consider namespacing: `/project/deploy`, `/team/review`

**🛡️ Command Security Guidelines:**
- [ ] No hardcoded secrets or credentials
- [ ] Validate user arguments before processing
- [ ] Avoid executing arbitrary shell commands
- [ ] Use relative paths carefully
- [ ] Consider command injection risks
- [ ] Test with malicious inputs

**Safe Patterns:**
```markdown
# ✅ Good - Safe file operations
Please analyze the file: $ARGUMENTS

# ❌ Dangerous - Direct shell execution
`rm -rf $ARGUMENTS`
```

**Testing Commands:**
```bash
/your-command test arguments    # Test the command
claude --debug                  # Verify with debug mode
/help                          # List available commands
```

**Advanced Features:**
- File imports: `@README.md`, `@.claude/config.md`
- Conditional logic: Framework detection, environment checks
- Cross-references: Link to other commands and documentation

### Settings Configuration
- **User**: `~/.claude/settings.json`
- **Project**: `.claude/settings.json` 
- **Local**: `.claude/settings.local.json`
- **Precedence**: Enterprise → CLI args → Local project → Shared project → User
- **Key Options**: `apiKeyHelper`, `hooks`, `permissions`, `env`, `model`