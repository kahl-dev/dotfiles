---
name: task-help
description: Show help and usage examples for the task management system
---

# Task Management Help

Comprehensive guide to using the task management system.

## Instructions:

Display the following information in a clear, organized format:

### Available Commands:

**📝 Task Creation:**
- `/task-new` - Create new task from context or arguments
- `/task-from-text` - Convert scratchpad/notes to structured task

**📋 Task Management:**
- `/task-list` - Show all open tasks with filtering options
- `/task-continue` - Resume work on existing task
- `/task-help` - Show this help guide

### Usage Examples:

**Quick Task Creation:**
- `/task-new PROJ-123 "Fix login bug"` - Create simple task with JIRA ID
- `/task-new feature "Add dark mode toggle"` - Create feature task
- `/task-new` - Create task from current conversation context

**Convert Existing Content:**
- `/task-from-text @scratchpad.md` - Convert file to task
- `/task-from-text "Build user dashboard with charts and filters"` - Convert text
- `/task-from-text PROJ-125` - Convert with specific JIRA ID

**Task Management:**
- `/task-list` - Show all active and backlog tasks
- `/task-list feature` - Show only feature tasks
- `/task-list PROJ-123` - Show tasks for specific JIRA project
- `/task-continue PROJ-123` - Resume specific task
- `/task-continue user-auth` - Resume task with partial name match

### File Structure:

```
<project>/
└── .tasks/
    ├── active/            # Currently working on
    │   ├── PROJ-123-login-fix.md
    │   └── 2024-01-15-dark-mode.md
    ├── backlog/           # Planned for later
    │   └── PROJ-124-dashboard.md
    ├── done/              # Completed tasks
    │   └── PROJ-122-user-settings.md
    └── scripts/           # Generated helper scripts
        └── migration-script.sh
```

### Task File Format:

```markdown
# Task: Add User Authentication

**Status:** active
**Type:** feature
**JIRA:** PROJ-123
**Created:** 2024-01-15

## Context
Users need secure login functionality with OAuth 2.0 support
and JWT token management for session handling.

## Steps
- [x] Set up auth context and providers
- [x] Create login/logout components  
- [ ] Implement JWT token handling
- [ ] Add password reset functionality
- [ ] Write comprehensive tests
- [ ] Update documentation

## Notes
- Use NextAuth.js for OAuth integration
- Store tokens in httpOnly cookies
- Consider refresh token rotation
- Need to handle mobile app integration
```

### Best Practices:

**🎯 Task Creation:**
- Use descriptive task names that explain the goal
- Include JIRA IDs for traceability
- Break large tasks into smaller, actionable steps
- Add context that future you will appreciate

**📊 Task Management:**
- Check `/task-list` before starting new work
- Use `/task-continue` to maintain context across sessions
- Move completed tasks to done/ folder
- Keep active folder focused on current priorities

**🔄 Workflow Integration:**
- Tasks automatically integrate with TodoWrite for progress tracking
- JIRA IDs are included in commit messages automatically
- Generated scripts are stored in tasks/scripts/ for reuse
- Task context is preserved across Claude sessions

### Integration Features:

**📝 TodoWrite Integration:**
- Tasks are automatically loaded into todo lists
- Progress is tracked with checkboxes
- Status updates are synchronized

**🔧 Commit Message Generation:**
- JIRA IDs are automatically included in conventional commits
- Format: `feat(PROJ-123): implement user authentication`

**🤖 Context Preservation:**
- Claude maintains awareness of active tasks
- Task context is restored when continuing work
- Related files and dependencies are tracked

**📊 Progress Tracking:**
- Visual progress indicators in task lists
- Completion statistics and summaries
- Identification of stale or blocked tasks

### Tips:

- Start with `/task-list` to see what's already in progress
- Use `/task-from-text` to quickly capture ideas from notes
- Let `/task-new` create tasks from conversation context
- Use `/task-continue` to seamlessly resume complex work
- Keep task descriptions focused but include enough context for later

The task management system is designed to capture your thoughts and maintain continuity across all development work, making it easy to switch between projects and pick up exactly where you left off.