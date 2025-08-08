📷 Show and display recent screenshots from ~/tmp/ai/screenshots/

Usage: `/utils:screenshots [count]` (default: 1)

- Get the screenshot file paths using the bash command: `$HOME/.claude/shared/get-screenshots.sh [count]`
- Use the Read tool to display each screenshot image 
- If count is 1 (default), show "📷 Latest screenshot" 
- If count is more than 1, show "📷 Last N screenshots" with numbered list
- Always display the actual image content using the Read tool, not just file paths