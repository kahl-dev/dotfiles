---
name: task-new
description: Create a new task from context, plan, or scratch
---

# Create New Task

Create a new task file, intelligently parsing context from current conversation, plans, or provided arguments.

Arguments: `$ARGUMENTS` (optional: type, jira-id, task-name, or full description)

## Instructions:

1. **Context Analysis**: Check recent conversation for:
   - Plans or feature discussions
   - Implementation ideas
   - Problem statements
   - Requirements or specifications

2. **Content Processing**: If arguments contain detailed text:
   - Parse as full task description
   - Extract action items and goals
   - Identify type and complexity
   - Look for JIRA references

3. **Task Creation**: 
   - Create `.tasks/` structure if needed (active, backlog, done, scripts folders)
   - Generate appropriate filename using format:
     - With JIRA: `JIRA-ID-short-description.md`
     - Without JIRA: `YYYY-MM-DD-short-description.md`
   - Structure content into Context/Steps/Notes sections
   - Add proper metadata (status, type, JIRA)

4. **Smart Defaults**:
   - Infer task type from content (feature, bug, refactor, chore, etc.)
   - Extract JIRA IDs from text automatically
   - Break down complex descriptions into actionable steps
   - Add relevant context from conversation history

5. **Integration**:
   - Load created task into TodoWrite for immediate progress tracking
   - Confirm task creation and show file path
   - Ask if user wants to start working on it immediately

## Task Template:
```markdown
# Task: [Task Name]

**Status:** active
**Type:** [feature|bug|refactor|chore|docs]
**JIRA:** [JIRA-ID or N/A]
**Created:** [YYYY-MM-DD]

## Context
[Background information and requirements]

## Steps
- [ ] [Actionable step 1]
- [ ] [Actionable step 2]
- [ ] [etc.]

## Notes
[Additional considerations, dependencies, or references]
```

This command should understand both simple task creation and complex plan conversion, making it the primary entry point for task management.