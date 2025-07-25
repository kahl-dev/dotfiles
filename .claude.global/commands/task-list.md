---
name: task-list
description: List all open tasks across active and backlog
---

# List All Tasks

Show comprehensive overview of all tasks in the current project.

Arguments: `$ARGUMENTS` (optional: filter by status, type, or jira-id)

## Instructions:

1. **Directory Verification**: 
   - Check if `.tasks/` directory exists in current project
   - If not found, inform user and suggest creating first task
   - Create directory structure overview if helpful

2. **Task Discovery**: Scan and catalog all task files:
   - **Active Tasks**: List all files in `.tasks/active/`
   - **Backlog Tasks**: List all files in `.tasks/backlog/`
   - **Completed Count**: Show count of files in `.tasks/done/`
   - **Generated Scripts**: List any files in `.tasks/scripts/`

3. **Task Parsing**: For each task file, extract:
   - Task name/title from filename and header
   - JIRA ID if present
   - Task type (feature, bug, refactor, etc.)
   - Creation date
   - Progress indicators (completed vs total checkboxes)
   - Last modified date

4. **Smart Filtering**: If arguments provided:
   - **By Type**: Show only tasks matching type (feature, bug, etc.)
   - **By JIRA**: Show tasks for specific ticket or project
   - **By Keyword**: Search in task names and content
   - **By Age**: Show tasks older than X days or recently created

5. **Display Format**:
   ```
   📋 Active Tasks (3):
   🎯 PROJ-123-user-authentication.md (feature) - 2/5 steps complete
   🐛 PROJ-124-login-bug-fix.md (bug) - 0/3 steps complete  
   🔧 refactor-api-endpoints.md (refactor) - 1/4 steps complete

   📝 Backlog (2):
   🆕 PROJ-125-dashboard-widgets.md (feature)
   📚 update-documentation.md (docs)

   ✅ Completed: 8 tasks in done/
   🔧 Generated Scripts: 2 files
   ```

6. **Smart Suggestions**:
   - Highlight tasks that haven't been touched in >7 days
   - Suggest which task to work on next based on priority/type
   - Show tasks that might be blockers for others
   - Identify tasks that could be moved to done

7. **Summary Statistics**:
   - Total tasks by status
   - Tasks by type breakdown
   - Average completion rate
   - Oldest active task

8. **Quick Actions**: Suggest relevant next steps:
   - `/task-continue TASK-NAME` for resuming work
   - `/task-new` for creating new tasks
   - Identify tasks ready to be archived

This command provides a comprehensive project overview and helps prioritize what to work on next.