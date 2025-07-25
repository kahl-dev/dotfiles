---
name: task-continue
description: Continue work on an existing task
---

# Continue Task

Resume work on an existing task, loading context and updating progress.

Arguments: `$ARGUMENTS` (optional: task-name, jira-id, or partial match)

## Instructions:

1. **Task Discovery**: 
   - If specific task provided: Search for exact matches by filename or JIRA ID
   - If partial match: Show options and let user choose
   - If no arguments: List active tasks and ask user to specify
   - Search in both `.tasks/active/` and `.tasks/backlog/`

2. **Task Selection Process**:
   - **Exact Match**: Load task immediately if only one match found
   - **Multiple Matches**: Present numbered list for user selection
   - **No Matches**: Suggest similar tasks or offer to create new one
   - **Fuzzy Matching**: Handle partial names, JIRA IDs, or keywords

3. **Context Loading**:
   - Read and parse the complete task file
   - Understand current state and progress
   - Review completed vs pending steps
   - Load all context, notes, and background information
   - Check last modified date to understand staleness

4. **Progress Assessment**:
   - Analyze which steps are complete (checked boxes)
   - Identify next logical step to work on
   - Review any blockers or dependencies mentioned
   - Check if any steps need updating based on current project state

5. **TodoWrite Integration**:
   - Load task into TodoWrite system for progress tracking
   - Create todo items for remaining uncompleted steps
   - Mark appropriate todo as "in_progress"
   - Preserve task structure and context

6. **Status Updates**:
   - Update task file's last modified timestamp
   - If task was in backlog, offer to move to active
   - Add session notes about continuation
   - Track progress on existing steps

7. **Context Presentation**:
   - Summarize task objective and current status
   - Highlight what's been completed and what remains
   - Show relevant context and constraints
   - Present next suggested actions

8. **Smart Assistance**:
   - Suggest related files that might need attention
   - Check if any dependencies have changed since last work
   - Offer to update task based on project evolution
   - Identify potential blockers or new requirements

## Usage Examples:
- `/task-continue PROJ-123` - Continue specific JIRA task
- `/task-continue user-auth` - Continue task with partial name match
- `/task-continue` - Show list of active tasks to choose from

## Output Format:
```
📋 Continuing Task: Add User Authentication

Status: Active | Type: Feature | JIRA: PROJ-123
Created: 2024-01-15 | Last Modified: 2024-01-20

✅ Completed:
- Set up auth context
- Create login component

🔄 Next Steps:
- [ ] Implement JWT token handling
- [ ] Add password reset functionality
- [ ] Write authentication tests

📝 Notes: Using OAuth 2.0 flow, store tokens in secure storage

Ready to continue work on JWT token handling?
```

This command seamlessly restores context and allows picking up exactly where work left off.