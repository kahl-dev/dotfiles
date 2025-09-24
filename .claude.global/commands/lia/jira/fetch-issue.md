---
description: "Fetch complete Jira ticket information with comments and attachments"
---

# 🎫 Fetch and display complete Jira ticket information

Usage: `/user:jira:fetch-issue TICKET-ID [TICKET-ID ...]`

Examples:
- Single ticket: `/user:jira:fetch-issue HMNLP-2831`
- Multiple tickets: `/user:jira:fetch-issue HMNLP-2831 PROJ-456 TEST-789`

- Run the ai-fetch-jira script: `ai-fetch-jira $ARGUMENTS`
- Display the complete markdown output returned by the script
- The script fetches all ticket data including comments, attachments, and time tracking
- Downloaded attachments are saved to ~/tmp/ai/jira/TICKET-ID/
- Show the full analysis report in markdown format