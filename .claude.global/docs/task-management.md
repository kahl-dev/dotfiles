# Task Management System Documentation

## Overview

The task management system provides persistent, organized workflows that Claude can seamlessly pick up and continue across sessions. It bridges the gap between informal notes and structured development work, ensuring no ideas or tasks are lost.

## Architecture

### Global Configuration
- **Location**: `~/.claude/CLAUDE.md` contains task management rules
- **Integration**: Claude automatically checks for tasks before starting work
- **Awareness**: Task context is preserved across all Claude sessions

### File Structure
```
~/.claude/
├── CLAUDE.md              # Global configuration with task rules
├── commands/              # Slash command definitions
│   ├── task-new.md        # Create new tasks
│   ├── task-from-text.md  # Convert text to tasks
│   ├── task-list.md       # List and filter tasks
│   ├── task-continue.md   # Resume existing work
│   └── task-help.md       # Usage guide
└── docs/
    ├── task-management.md  # This documentation
    └── README.md          # Documentation index

<project>/
└── .tasks/
    ├── active/            # Current work (high priority)
    ├── backlog/           # Planned tasks (lower priority)
    ├── done/              # Completed tasks (archived)
    └── scripts/           # Generated helper scripts
```

### Task File Format

Each task is a structured markdown file with YAML frontmatter:

```markdown
# Task: Add User Authentication

**Status:** active
**Type:** feature
**JIRA:** PROJ-123
**Created:** 2024-01-15

## Context
Background information, requirements, and constraints.
Links to related issues, documents, or discussions.

## Steps
- [x] Completed step with checkbox
- [ ] Pending step to work on
- [ ] Another pending step

## Notes
Additional considerations, dependencies, gotchas,
or implementation details to remember.
```

**Metadata Fields:**
- **Status**: active, backlog, done
- **Type**: feature, bug, refactor, chore, docs, test
- **JIRA**: Ticket ID for traceability (or N/A)
- **Created**: ISO date format (YYYY-MM-DD)

## Command Reference

### /task-new
**Purpose**: Create new tasks from context, plans, or arguments

**Usage**:
- `/task-new` - Create from conversation context
- `/task-new PROJ-123 "Fix login bug"` - Quick task with JIRA
- `/task-new feature "Add dark mode"` - Specify type
- `/task-new "Complex description with multiple requirements"` - Full description

**Behavior**:
- Analyzes recent conversation for context
- Extracts JIRA IDs automatically
- Infers task type from content
- Creates structured task file
- Loads into TodoWrite for immediate tracking

### /task-from-text
**Purpose**: Convert existing notes, scratchpads, or todos into structured tasks

**Usage**:
- `/task-from-text @scratchpad.md` - Convert file
- `/task-from-text "Unstructured todo text"` - Convert direct text
- `/task-from-text PROJ-125` - With specific JIRA ID

**Behavior**:
- Parses informal content
- Extracts actionable items
- Organizes into structured format
- Preserves important details
- Creates properly formatted task file

### /task-list
**Purpose**: Show overview of all project tasks

**Usage**:
- `/task-list` - Show all tasks
- `/task-list feature` - Filter by type
- `/task-list PROJ-123` - Filter by JIRA project
- `/task-list auth` - Search by keyword

**Output**:
- Active tasks with progress indicators
- Backlog tasks by priority
- Completed task count
- Summary statistics
- Suggestions for next work

### /task-continue
**Purpose**: Resume work on existing tasks

**Usage**:
- `/task-continue PROJ-123` - Resume specific task
- `/task-continue user-auth` - Partial name match
- `/task-continue` - Choose from active tasks

**Behavior**:
- Loads complete task context
- Shows progress and remaining work
- Integrates with TodoWrite
- Updates task timestamps
- Provides smart next-step suggestions

### /task-help
**Purpose**: Show usage guide and examples

**Usage**: `/task-help`

**Output**: Comprehensive help with examples and best practices

## Workflow Examples

### Starting a New Feature
```bash
# Check what's already in progress
/task-list

# Create new task from JIRA ticket
/task-new PROJ-123 "Implement user dashboard"

# Claude creates structured task and loads into TodoWrite
# Begin working on first step
```

### Converting Notes to Tasks
```bash
# Have scratchpad with ideas
/task-from-text @meeting-notes.md

# Claude parses content and creates structured task
# Ready to start organized development
```

### Continuing Previous Work
```bash
# Resume after break or session
/task-continue dashboard

# Claude loads full context and progress
# Pick up exactly where you left off
```

### Project Overview
```bash
# See all work in progress
/task-list

# Filter to specific area
/task-list feature

# Continue highest priority item
/task-continue PROJ-123
```

## Integration Features

### TodoWrite Integration
- Tasks automatically load into Claude's todo system
- Progress tracked with checkboxes
- Status updates synchronized between systems
- Context preserved across sessions

### JIRA Integration
- Automatic JIRA ID extraction from text
- Consistent ticket ID formatting
- Commit message generation includes JIRA IDs
- Traceability from code to requirements

### Git Integration
- Commit messages automatically include JIRA IDs
- Format: `feat(PROJ-123): implement user authentication`
- Task context guides commit message content
- Progress tracking linked to version control

### File Organization
- Automatic directory structure creation
- Consistent naming conventions
- Status-based organization (active/backlog/done)
- Generated scripts stored with tasks

## Best Practices

### Task Creation
- **Descriptive Names**: Use clear, action-oriented task titles
- **JIRA Traceability**: Include ticket IDs when available
- **Granular Steps**: Break large tasks into manageable pieces
- **Context Rich**: Add enough background for future reference

### Task Management
- **Check First**: Always run `/task-list` before starting new work
- **Single Focus**: Keep limited number of active tasks
- **Regular Updates**: Update progress as work completes
- **Archive Completed**: Move finished tasks to done/ folder

### Workflow Integration
- **Session Continuity**: Use `/task-continue` to restore context
- **Progress Tracking**: Let TodoWrite manage step-by-step progress
- **Commit Discipline**: Include JIRA IDs in all relevant commits
- **Documentation**: Keep task notes updated with discoveries

### Organization
- **Status Management**: Move tasks between active/backlog/done appropriately
- **Priority Ordering**: Keep highest priority items in active/
- **Regular Cleanup**: Archive old completed tasks periodically
- **Script Management**: Store generated helpers in tasks/scripts/

## Troubleshooting

### Common Issues

**Tasks not appearing in /task-list**
- Verify `.tasks/` directory exists in project root
- Check file extensions are `.md`
- Ensure proper frontmatter format

**JIRA IDs not recognized**
- Use standard format: `PROJ-123`
- Include in task filename or frontmatter
- Verify extraction in task content

**Context not preserved**
- Check global CLAUDE.md has task management section
- Verify slash commands are in `~/.claude/commands/`
- Ensure task files have proper structure

**TodoWrite not loading tasks**
- Verify task has proper checkbox format `- [ ]`
- Check task status is set correctly
- Ensure `/task-continue` is used to load context

### File Recovery
If task files become corrupted or lost:
1. Check `.tasks/done/` for archived versions
2. Review git history for task file changes
3. Recreate from commit messages and JIRA tickets
4. Use `/task-from-text` to rebuild from notes

## Advanced Usage

### Custom Task Types
Extend beyond standard types (feature, bug, etc.):
- **research**: Investigation and analysis tasks
- **spike**: Technical exploration or prototyping
- **maintenance**: Routine upkeep and updates
- **security**: Security-focused improvements

### Batch Operations
Use command combinations for efficiency:
```bash
# Create multiple related tasks
/task-new PROJ-123 "Backend API endpoints"
/task-new PROJ-124 "Frontend integration"
/task-new PROJ-125 "End-to-end testing"

# Convert multiple notes
/task-from-text @backend-notes.md
/task-from-text @frontend-notes.md
```

### Project Templates
Create reusable task templates for common workflows:
- Feature development checklist
- Bug investigation process
- Release preparation tasks
- Code review guidelines

This task management system transforms development workflow from ad-hoc work to organized, traceable, and resumable processes that scale across projects and team members.