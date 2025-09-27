# AI Agent Utilities

Centralized utilities for AI agents (Claude, Codex, etc.)

## Available Utilities

### ai-fetch-jira
Fetches complete Jira ticket data including comments and attachments.

**Usage:** `ai-fetch-jira TICKET-ID [TICKET-ID ...]`

**Options:**
- `--json` - Output in JSON format instead of markdown
- `--verbose` - Show progress messages
- `--force` - Force re-download of attachments

**Required Environment Variables:**
- `JIRA_USER_EMAIL`: Your Jira email
- `JIRA_API_KEY` or `JIRA_CLAUDE_KEY`: Your Jira API token
- `JIRA_WORKSPACE`: Your Jira workspace name or full URL

**Output:**
- Markdown format optimized for AI/LLMs
- Attachments saved to `~/tmp/ai/jira/<ticket-id>/`
- Includes title, description, comments, time tracking, and linked issues

### ai-fetch-screenshots
Retrieves recent screenshots from ~/tmp/ai/screenshots/

**Usage:** `ai-fetch-screenshots [count]`

**Parameters:**
- `count` - Number of screenshots to retrieve (default: 1)

**Output:**
- File paths to the most recent screenshots
- Sorted by modification time (newest first)
- Supports common image formats (png, jpg, jpeg, gif, webp)

## Naming Convention

Pattern: `ai-{action}-{source}`

- `ai-` prefix for AI agent utilities
- Action verb (fetch, process, analyze, etc.)
- Source/target (jira, screenshots, github, confluence, etc.)

## Adding New Utilities

When creating new utilities:

1. Follow the naming convention
2. Add executable permission: `chmod +x ai-{name}`
3. Update this README with usage documentation
4. Add to Claude agent configurations as needed
5. Consider adding to `.claude.global/settings.json` permissions if used by agents