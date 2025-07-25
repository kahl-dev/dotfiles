---
name: task-from-text
description: Convert scratchpad notes, todos, or plans into structured tasks
---

# Convert Text to Task

Convert the provided text, scratchpad notes, or todo items into a properly structured task file.

Arguments: `$ARGUMENTS` (optional: file-path, jira-id, or direct text)

## Instructions:

1. **Input Processing**: Handle different input types:
   - File reference (e.g., `@scratchpad.md`, `notes.txt`)
   - Direct text input provided as arguments
   - Selected text from conversation
   - If no input provided, ask user to paste or select content

2. **Content Analysis**: Extract key information from the provided content:
   - **Main Objective**: Identify the primary goal or task
   - **Action Items**: Find explicit or implicit steps/requirements
   - **Context**: Extract background information and constraints
   - **JIRA References**: Look for ticket IDs in various formats (PROJ-123, #123, etc.)
   - **Type Detection**: Determine if it's a feature, bug fix, refactor, etc.
   - **Priority Indicators**: Look for urgency or importance clues

3. **Content Transformation**:
   - Clean up informal language into structured format
   - Break down run-on descriptions into discrete steps
   - Preserve important details while organizing clearly
   - Convert loose todos into actionable checkboxes
   - Add missing context or clarifying information

4. **Task File Creation**:
   - Create `.tasks/active/` directory if needed
   - Generate appropriate filename:
     - If JIRA found: `JIRA-ID-description.md`
     - Otherwise: `YYYY-MM-DD-description.md`
   - Apply standard task template structure
   - Include original content reference in notes

5. **Quality Assurance**:
   - Ensure all action items are specific and actionable
   - Verify task has clear completion criteria
   - Add any missing context that might be needed later
   - Preserve important details from original content

6. **Integration**:
   - Load created task into TodoWrite for progress tracking
   - Show before/after comparison if helpful
   - Confirm task structure with user
   - Ask if task should be moved to backlog instead of active

## Usage Examples:
- `/task-from-text @scratchpad.md` - Convert entire file
- `/task-from-text "Add user auth with OAuth and JWT tokens"` - Convert text directly
- `/task-from-text PROJ-123` - Convert with specific JIRA ID
- `/task-from-text` - Interactive mode, will ask for content

This command bridges the gap between informal notes and structured task management, making it easy to capture and organize ideas from any source.