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
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/validate-changes.sh",
            "timeout": 5000
          }
        ]
      }
    ]
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

#### 🎯 Smart Lint Hook - Implementation Guide

**Location:** `~/.dotfiles/.claude.global/hooks/smart-lint.sh`

**Purpose:** Automatic linting and type checking for JavaScript, TypeScript, Vue, Shell scripts, and Makefiles on every file edit.

**Hook Configuration (`~/.claude/settings.json`):**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/smart-lint.sh"
          }
        ]
      }
    ]
  }
}
```

**📥 Input Protocol (3-Tier System):**

The hook uses a three-tier fallback system for file collection:

1. **Tier 1: Hook stdin JSON (PostToolUse)** - AUTHORITATIVE
   - Source: Claude Code's PostToolUse hook protocol
   - Input: JSON via stdin with structure:
     ```json
     {
       "tool_name": "Edit|Write|MultiEdit",
       "tool_input": {
         "file_path": "/absolute/path/to/file.ts",
         "old_string": "...",
         "new_string": "..."
       }
     }
     ```
   - Behavior: Per-file processing, immediate feedback
   - Reliability: 100% accurate
   - Use case: Normal Edit/Write operations in PostToolUse hook

2. **Tier 2: CLAUDE_MODIFIED_FILES environment variable** - BATCH MODE
   - Source: Environment variable with newline-separated file paths
   - Behavior: Multi-file batch processing, ESLint/TypeScript optimization active
   - Reliability: 100% accurate if variable is set correctly
   - Use case: SessionEnd hooks, manual invocation, CI/CD
   - Example:
     ```bash
     export CLAUDE_MODIFIED_FILES="/path/to/file1.ts
     /path/to/file2.ts
     /path/to/file3.ts"
     ~/.claude/hooks/smart-lint.sh
     ```

3. **Tier 3: Time-based file search** - DEBUGGING FALLBACK
   - Source: `find . -mmin -1` for recently modified files
   - Behavior: Searches for files changed in last 1 minute
   - Reliability: ~50% (timing issues, directory context problems)
   - Use case: Testing/debugging only, not production
   - Warning: Inherently unreliable, use only as last resort

**🔧 Processing Modes:**

| File Source | ESLint | TypeScript | Speed | Use Case |
|-------------|---------|------------|-------|----------|
| `hook_stdin` | 1 run/file | 1 run/file | Immediate (2-5s) | PostToolUse per-file |
| `env_variable` | Batched | Batched | Fast (5-10s) | SessionEnd, manual |
| `time_based` | Batched | Batched | Varies | Debugging only |

**📋 Linter Features:**

1. **ESLint:**
   - Auto-discovery of `.eslintrc.*` configs
   - Project-specific Node.js version detection (via `.nvmrc`, `.node-version`, `package.json`)
   - Uses `npx --prefix` for project-specific ESLint version
   - Batch optimization: groups files by shared config
   - Auto-fix with `--fix` flag
   - Caching for config discovery and tool availability

2. **TypeScript/vue-tsc:**
   - Auto-discovery of `tsconfig.json`
   - Project-specific TypeScript version
   - Nuxt project special handling with `nuxi typecheck`
   - NEW: Batch optimization for multiple files sharing same tsconfig
   - Skips `.nuxt` build directories

3. **ShellCheck:**
   - Validates bash/sh scripts
   - Zsh syntax checking with `zsh -n`
   - Shebang detection
   - File extension detection (`.sh`, `.bash`, `.zsh`)

4. **Makefile:**
   - Syntax validation with `make --dry-run`
   - Secure temporary directory usage
   - File size limits to prevent DoS

**🔍 Session Info Display:**

The hook displays processing mode and file counts:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Smart Lint Session Info
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  File Source: hook_stdin
  Total Files: 1
  JS/TS/Vue:   1
  Shell:       0
  Makefile:    0
  Mode: Per-file (immediate feedback)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**⚙️ Advanced Usage: SessionEnd Batch Processing:**

For end-of-session bulk linting with full batch optimization:

```json
{
  "hooks": {
    "SessionEnd": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-end-lint.sh"
          }
        ]
      }
    ]
  }
}
```

Create `session-end-lint.sh`:

```bash
#!/usr/bin/env bash
# Collect all modified files from session
export CLAUDE_MODIFIED_FILES="$(cat ~/.claude/user-data/file-types.json | jq -r '.file_types[].recent_files[]' | sort -u)"
~/.claude/hooks/smart-lint.sh
```

**🔒 Security Features:**

- Input sanitization for file paths
- Prevention of shell injection
- File size limits (10 MB default)
- Timeout protection (30s per command)
- Sandboxed command execution with restricted environment
- Directory traversal prevention
- Secure temporary directory handling

**🚫 Exit Codes:**

- `0`: All files passed linting/type checking
- `2`: Blocking errors found (lint/type errors that need manual fixes)

**🐛 Troubleshooting:**

1. **Hook not triggering:**
   - Check matcher in settings.json: `"Write|Edit|MultiEdit"`
   - Verify hook script is executable: `chmod +x ~/.claude/hooks/smart-lint.sh`
   - Test with `claude --debug`

2. **Files not being linted:**
   - Check tier source in "Smart Lint Session Info" output
   - If `time_based`, stdin reading failed - check jq installation
   - Verify file is not in excluded directories (`.nuxt`, `node_modules`, etc.)

3. **ESLint version issues:**
   - Hook uses project-specific ESLint via `npx --prefix`
   - Check Node.js version matches project requirements
   - Verify `.nvmrc` or `package.json` engines.node is correct

4. **Performance issues:**
   - Batch mode (Tier 2) is 5-10x faster than per-file
   - Consider SessionEnd hook for bulk operations
   - Check cache warming on first run

**📚 References:**

- Official hook docs: https://docs.claude.com/en/docs/claude-code/hooks.md
- Hook implementation: `~/.dotfiles/.claude.global/hooks/smart-lint.sh`
- Settings example: `~/.dotfiles/.claude.global/settings.json`

### Slash Commands & Custom Prompts

#### 📋 Command Organization Structure

**Primary Categories:**
- `/lia:*` - LIA/work commands (Jira operations, company development workflows)
- `/user:*` - Personal commands (productivity tools, analysis, personal development)
- `/claude:*` - System commands (memory management, prompt configuration)

**LIA/Work Commands (`/lia:`):**
- `jira/` - Jira operations (fetch-issue, estimate)
- `development/` - Company development workflows (commit)

**Personal Commands (`/user:`):**
- `productivity/` - Personal productivity tools (screenshots, changelog, docs, todo)
- `development/` - Personal development commands (check, commit)
- `analysis/` - Code analysis and review tools (analyze, review)

**System Commands (`/claude:`):**
- Core Claude configuration (memory, prompt)

**Usage Examples:**
- `/lia:jira:fetch-issue PROJ-123` - Fetch complete Jira ticket data
- `/user:productivity:screenshots 3` - Show last 3 screenshots
- `/user:development:commit` - Personal commit workflow
- `/claude:memory` - Edit Claude memory

#### 🔄 Production Review Workflow

1. **🚨 Pre-commit gate** – Run `/user:review:hard` (invokes `@review-hard-auditor`).
   - Scope: current staged/unstaged changes only.
   - Expectation: returns `Not Ready` until all blockers (injections, unsafe fallbacks, etc.) are fixed.
   - Ship only after the auditor reports *no blockers*.

2. **🔍 Deep analysis** – Once the gate is green, use the `review-simple-analyzer` agent for follow-up work.
   - Examples: `analyze src/auth/`, `review commits from last week`, `full codebase health check`, `postmortem commit abc123`.
   - Purpose: advisory insights on architecture, technical debt, historical regressions, post-deploy audits.

3. **❌ Common mistake** – Do **not** rely on `review-simple-analyzer` for gating uncommitted changes. It is advisory; the auditor is the strict production safety gate.

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
description: 'Brief description of what this command does'
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
