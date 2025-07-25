# Claude User-Level Configuration

This directory contains the modular configuration system for Claude Code, providing a clean separation of concerns and improved maintainability.

## 📁 Directory Structure

```
user-level/
├── CLAUDE.md              # Main configuration file with @includes
├── settings.json          # Claude settings, permissions, and hooks
├── commands/              # Custom slash commands
│   ├── check.md          # /check - Run project checks
│   ├── comments.md       # /comments - Remove code comments
│   ├── commit.md         # /commit - Create conventional commits
│   ├── emoji.md          # /emoji - Add contextual emojis
│   ├── learn.md          # /learn - Document learned solutions
│   ├── lia-commit.md     # /lia-commit - JIRA-integrated commits
│   ├── rebase.md         # /rebase - Handle rebase conflicts
│   ├── task-*.md         # /task-* - Task management commands
│   └── todo.md           # /todo - Manage .llm/todo.md
├── instructions/          # Modular instruction files
│   ├── build-commands.md # Build and verification guidelines
│   ├── code-style.md     # Human-readable code style rules
│   ├── conversation.md   # Communication style guidelines
│   ├── llm-code-style.md # LLM-specific code patterns
│   ├── llm-context.md    # Context management (.llm/ directory)
│   ├── llm-git-commits.md# Git commit conventions
│   ├── tests.md          # Testing guidelines
│   └── tool-use.md       # Tool usage patterns and priorities
├── hooks/                 # Git hooks and automation
│   ├── smart-lint.sh     # Intelligent linting with auto-fix
│   └── pushover-notify.sh# Notification integration
└── shared/               # Shared resources
    └── comment-removal-rules.md # Rules for comment removal

```

## 🔧 Key Features

### Modular Instructions
The main `CLAUDE.md` file uses `@instructions/filename.md` syntax to include modular instruction files. This allows:
- Easy updates to specific aspects without touching the main file
- Better version control and diff visibility
- Shared instructions across multiple projects

### Smart Hooks
The `smart-lint.sh` hook automatically:
- Detects ESLint and TypeScript configurations
- Attempts auto-fix before reporting errors
- Supports Vue files with vue-tsc
- Provides clear, actionable error messages

### Enhanced Security
- Explicit allow/deny lists in `settings.json`
- Blocked dangerous operations (`rm -rf`, `git push --force`)
- No hardcoded credentials or MCP server configs

### Custom Commands
Slash commands provide quick access to common workflows:
- Task management with JIRA integration
- Smart comment removal with configurable rules
- Automated commit message generation
- Interactive rebase conflict resolution

## 🚀 Usage

1. **Global Configuration**: This configuration applies to all Claude Code sessions
2. **Project-Specific Overrides**: Projects can have their own `.claude/CLAUDE.md`
3. **Hook Integration**: Hooks run automatically on file modifications
4. **Command Access**: Type `/` in Claude to see available commands

## 📝 Maintenance

### Adding New Instructions
1. Create a new `.md` file in `instructions/`
2. Add the reference in `CLAUDE.md` using `@instructions/newfile.md`

### Creating New Commands
1. Add a new `.md` file in `commands/`
2. Follow the existing format with emoji header and clear instructions

### Updating Hooks
1. Modify hook scripts in `hooks/`
2. Ensure proper error handling and exit codes
3. Test with various file types and project structures

## 🔐 Security Notes

- All paths must be absolute (security requirement)
- Credentials should use environment variables
- Dangerous operations are explicitly denied
- File operations validate against path traversal

## 📚 Related Documentation

- Main system documentation: `/home/kahl/.claude.store/README.md`
- Security audit: `/home/kahl/.claude.store/SECURITY-AUDIT.md`
- Global CLAUDE.md: `/home/kahl/.claude/CLAUDE.md`