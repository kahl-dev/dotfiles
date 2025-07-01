# Claude Configuration Documentation

This directory contains documentation for your Claude setup and custom systems.

## Available Documentation

### 📋 [Task Management System](task-management.md)
Complete guide to the persistent task management system that allows Claude to maintain context and continuity across sessions.

**Quick Start:**
- Use `/task-help` for command reference
- Try `/task-new` to create your first task  
- Run `/task-list` to see project overview

### 🔧 Global Configuration
Your global Claude configuration is located at `~/.claude/CLAUDE.md` and includes:
- Behavioral guidelines for all projects
- Tool usage preferences
- Task management integration
- MCP server configurations
- Security and workflow standards

### 💬 Slash Commands
Custom commands are defined in `~/.claude/commands/`:
- **task-new.md** - Create new tasks
- **task-from-text.md** - Convert notes to tasks
- **task-list.md** - List and filter tasks
- **task-continue.md** - Resume existing work
- **task-help.md** - Usage guide

## System Overview

```
~/.claude/
├── CLAUDE.md              # Global configuration
├── commands/              # Custom slash commands
│   ├── task-*.md          # Task management commands
│   └── ...                # Additional commands
└── docs/                  # Documentation (this folder)
    ├── task-management.md # Complete task system guide
    └── README.md          # This file
```

## Quick Reference

### Essential Commands
- `/task-help` - Show task management help
- `/task-new` - Create new task
- `/task-list` - Show all tasks
- `/task-continue` - Resume work

### Getting Started
1. Read [task-management.md](task-management.md) for detailed usage
2. Try creating your first task with `/task-new`
3. Explore project tasks with `/task-list`
4. Use `/task-help` anytime for quick reference

### Integration Features
- **Persistent Context**: Tasks maintain context across Claude sessions
- **JIRA Integration**: Automatic ticket ID tracking and commit message generation
- **TodoWrite Integration**: Seamless progress tracking
- **Git Integration**: Smart commit messages with traceability

## Future Documentation

As you add more custom systems and configurations, document them here:
- Additional slash commands
- Project-specific workflows
- Integration guides
- Troubleshooting guides

This documentation system ensures your Claude setup remains maintainable and shareable.