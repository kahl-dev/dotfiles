# https://gist.github.com/usrbinkat/a57de05914686084ec89c6cfd864ca7d
# https://docs.anthropic.com/en/docs/claude-code/mcp
# https://github.com/punkpeye/awesome-mcp-servers?tab=readme-ov-file
# https://github.com/wong2/awesome-mcp-servers
# https://freedium.cfd/https://medium.com/@joe.njenga/claude-code-remote-mcp-now-supported-heres-how-it-works-fe54305c78cf
# https://github.com/modelcontextprotocol/servers?tab=readme-ov-file
# https://github.com/modelcontextprotocol/inspector

claude mcp add context7 -s user -- npx -y @upstash/context7-mcp@latest

# https://www.npmjs.com/package/@nova-mcp/mcp-nova
# npm install -g @nova-mcp/mcp-nova
# claude mcp add mcp-nova -s user mcp-nova

# @NOTE: use playwrite instead of puppeteer
# claude mcp add-json -s user puppeteer '{
#   "command": "npx",
#   "args": ["-y", "@modelcontextprotocol/server-puppeteer"],
#   "env": {
#     "PUPPETEER_LAUNCH_OPTIONS": "{\"headless\": \"new\", \"args\": [\"--no-sandbox\", \"--disable-setuid-sandbox\", \"--disable-dev-shm-usage\", \"--window-size=1280,720\"]}",
#     "ALLOW_DANGEROUS": "true"
#   }
# }'

claude mcp add-json -s user github '{
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-github"
  ],
  "env": {
    "GITHUB_PERSONAL_ACCESS_TOKEN": "'"$GITHUB_PERSONAL_ACCESS_TOKEN"'"
  }
}'

claude mcp add-json -s user gitlab '{
  "command": "npx",
  "args": [
    "-y",
    "@modelcontextprotocol/server-gitlab"
  ],
  "env": {
    "GITLAB_PERSONAL_ACCESS_TOKEN": "'"$GITLAB_PERSONAL_ACCESS_TOKEN"'",
    "GITLAB_API_URL": "'"$GITLAB_API_URL"'"
  }
}'

# docs: https://github.com/microsoft/playwright-mcp
claude mcp add playwright -s user npx @playwright/mcp@latest

claude mcp add-json -s user figma '{
  "command": "npx",
  "args": [
    "-y", 
    "figma-developer-mcp", 
    "--stdio"
  ],
  "env": {
    "FIGMA_API_KEY": "'"$FIGMA_API_KEY"'"
  }
}'

claude mcp add-json -s user n8n '{
  "command": "npx",
  "args": [
    "-y",
    "n8n-mcp" 
  ],
  "env": {
    "MCP_MODE": "stdio",
    "LOG_LEVEL": "error",
    "DISABLE_CONSOLE_OUTPUT": "true",
    "N8N_API_URL": "'"$N8N_API_URL"'",
    "N8N_API_KEY": "'"$N8N_API_KEY"'"
  }
}'

# SENTRY_ACCESS_TOKEN=your-token
# SENTRY_HOST=your-sentry-host
# "env": {
#   "SENTRY_ACCESS_TOKEN": "$SENTRY_ACCESS_TOKEN",
#   "SENTRY_HOST": "$SENTRY_HOST",
#   "SENTRY_DSN": "$SENTRY_DSN"
# }

claude mcp add-json -s user sentry '{
  "command": "npx",
  "args": [
    "-y",
    "@sentry/mcp-server@latest",
    "--access-token='$SENTRY_ACCESS_TOKEN'",
    "--host='$SENTRY_HOST'"
  ]
}'

# claude mcp add fetch uvx mcp-server-fetch
# https://cloudinary.com/documentation/cloudinary_llm_mcp
claude mcp add-json -s user cloudinary-asset-mgmt '{
  "command": "npx",
  "args": ["-y", "--package", "@cloudinary/asset-management", "--", "mcp", "start"],
  "env": {
    "CLOUDINARY_CLOUD_NAME": "'"$CLOUDINARY_CLOUD_NAME"'",
    "CLOUDINARY_API_KEY": "'"$CLOUDINARY_API_KEY"'",
    "CLOUDINARY_API_SECRET": "'"$CLOUDINARY_API_SECRET"'"
  }
}'

# WORKING ATLASSIAN MCP CONFIGURATIONS
# These configurations were tested and work without OAuth

# Jira MCP Server - Uses @atlassian-dc-mcp/jira package
# claude mcp add-json -s user jira '{
#   "command": "npx",
#   "args": ["-y", "@atlassian-dc-mcp/jira"],
#   "env": {
#     "JIRA_HOST": "louis-internet.atlassian.net",
#     "JIRA_API_TOKEN": "'$JIRA_CLAUDE_KEY'"
#   }
# }'

# Confluence MCP Server - Uses @aashari/mcp-server-atlassian-confluence package
# claude mcp add-json -s user confluence '{
#   "command": "npx",
#   "args": ["-y", "@aashari/mcp-server-atlassian-confluence"],
#   "env": {
#     "CONFLUENCE_URL": "'$JIRA_WORKSPACE'",
#     "CONFLUENCE_USERNAME": "'$JIRA_USER_EMAIL'",
#     "CONFLUENCE_API_TOKEN": "'$JIRA_API_KEY'"
#   }
# }'
