# General AI Agent Guidelines

This document defines general behavioral guidelines for AI assistants working with codebases.

---

## 1. Purpose

- Ensure consistent, safe interaction with repositories
- Leverage project-specific tools rather than ad-hoc shell commands
- Maintain existing conventions and avoid unintended side effects

---

## 2. Preferred Tooling Order

1. **grep** – locate code by content (functions, constants)
2. **find_path** – locate files by name or glob
3. **read_file** – inspect file contents once you have the path
4. **list_directory** – explore directory structure
5. **edit_file** – create or modify source files
6. **create_directory** – add new directories
7. **move_path / copy_path / delete_path** – refactor or restructure files
8. **terminal** – run one-off shell commands (e.g. `make dev`, `docker ps`, `npm test`)

> Always prefer project-specific tools over free-form shell commands.

---

## 3. Markdown & Code Block Conventions

- Use path-anchored, language-labeled backtick blocks with the path immediately following the label:

  ```ts path/to/file.ext#Lstart-end
  // code snippet with TypeScript types
  ```

- Paths must begin at one of the root directories
- Include the appropriate language label (`ts`, `js`, `vue`, etc.) after the opening backticks for syntax highlighting

---

## 4. Core Behavioral Guidelines

### File & Path Management

- **Never** guess or hard-code file paths; always discover via `grep` or `find_path`
- **Do not** add new dependencies unless declared in `package.json` or explicitly approved
- Ask clarifying questions if a request is ambiguous

### Git & Version Control

- **NEVER commit unless explicitly requested** by the user - always wait for explicit permission to commit
- **Each commit requires individual authorization** - no wildcards or blanket permissions for multiple commits
- **Only use Git commands when explicitly requested** by the user
- **When committing on user request**, adhere to these rules:
  - Use Conventional Commit format: `<type>(TICKET-ID): clear description of change`
  - Types include: `feat`, `fix`, `chore`, `docs`, `style`, `refactor`, `test`, `perf`
  - Always include the ticket/issue ID in parentheses immediately after the type
  - The commit message subject must be concise (≤ 72 characters) and start lowercase
  - Provide a longer commit description in the body, wrapping lines around ~100 characters
  - Stage only the files directly modified for the requested change
  - **NEVER include AI generation attribution** in commit messages (no "Generated with Claude Code" or similar)

### Code Quality & Standards

- Conform to existing code style and linting rules
- **Analyze actual file changes for commit messages** - don't include everything from chat conversation, investigate the real changes made and write focused commit messages based on actual code modifications
- **Study existing patterns** before proposing solutions
- **Check package versions** and compatibility before suggesting changes

---

## 5. AI Assistant Best Practices

### Always Do First

- **NEVER commit unless explicitly requested** - only commit when user specifically asks
- **Each commit needs individual user authorization** - no assumptions or batch commits
- **Ask for ticket/issue ID** if not provided for commits
- **Analyze actual file changes for commit messages** - focus on real code modifications
- **Study existing patterns** before proposing solutions
- **Use project tools** - prefer project-specific scripts over ad-hoc commands

### Common Mistakes to Avoid

- Making commits without proper authorization
- Suggesting shell commands instead of project scripts
- Adding dependencies without checking compatibility
- Guessing file paths instead of discovering them
- Not following existing code patterns and conventions

---

## 6. Communication Protocol

### User Interaction Guidelines

1. **Wait for User Input**: When presenting multiple choices, options, or implementation approaches, ALWAYS wait for the user to specify their preference before proceeding
2. **Present Clear Options**: When multiple solutions are possible, present them clearly numbered or bulleted with brief descriptions
3. **Confirm Before Implementation**: Before implementing any significant changes, confirm the chosen approach with the user
4. **Ask for Clarification**: If the user's request could be interpreted in multiple ways, ask for clarification rather than assuming
5. **Respect User Decisions**: Once the user makes a choice, implement exactly what they requested without second-guessing

### Information Sharing

- **Configuration**: Environment variables are in `.env` files (never share actual values)
- **API Keys**: Reference them by environment variable names only
- **User Data**: Follow GDPR principles and never expose personal information
- **Debugging**: Share sanitized logs without sensitive information

---

## 7. Code Quality & Testing

### Post-Change Quality Checks

After any code modifications, run the project's quality assurance tools:
1. **Auto-fix and format**: Run linting tools with auto-fix flags (e.g., `eslint --cache --fix`)
2. **Verify compliance**: Run linting tools to verify all rules pass
3. **Security checks**: Run security validation when applicable
4. **Test thoroughly**: Run relevant test suites before committing

### Development Workflow

1. **Always run code quality checks after changes**
2. **Use project-specific tools**: Prefer project scripts over direct tool usage
3. **Maintain type safety**: Ensure TypeScript/typing compliance when applicable
4. **Document changes**: Update relevant documentation when adding features

---

## 8. Security Guidelines

### Universal Security Principles

- **Never hardcode secrets**: No API keys, tokens, or passwords in code
- **Environment variables**: Always use `process.env.VARIABLE_NAME` format
- **Validation**: Validate environment variables at startup
- **Error handling**: Use proper error handling for external APIs
- **Data protection**: Follow GDPR principles for user data
- **Rate limiting**: Implement and respect API rate limits
- **NEVER DEPLOY**: Never deploy code or applications unless explicitly requested
- **NEVER MODIFY PRODUCTION DATABASE**: Never write to, change, or modify production databases under any circumstances

### Sensitive Information Handling

- **Secrets management**: Use proper secret management for deployments
- **Access control**: Implement proper authentication and authorization
- **Input validation**: Sanitize all external data inputs
- **Audit logging**: Monitor access and modifications appropriately

---

---

## 9. Memory Management Guidelines

### Memory MCP Usage Principles

- **What to Remember**: Project architecture, user preferences, recurring patterns, important decisions, and context that spans sessions
- **What NOT to Remember**: Temporary data, sensitive information (API keys, passwords), large code dumps, or session-specific debugging info
- **Privacy First**: Never store personal identifiable information, credentials, or proprietary business logic in memory
- **Contextual Storage**: Store information that helps maintain continuity across sessions without duplicating what's already in the codebase

### Memory Best Practices

1. **Quality over Quantity**: Store concise, actionable insights rather than verbose logs
2. **Regular Cleanup**: Periodically review and update stored memories to keep them relevant
3. **Project-Specific Context**: Remember project conventions, architectural decisions, and user workflow preferences
4. **Development Patterns**: Store recurring solutions, common debugging approaches, and preferred tooling choices

### What Should Be Remembered

- User's preferred code style and conventions
- Project-specific architectural decisions
- Recurring issues and their solutions
- Tool preferences (testing frameworks, linting rules, etc.)
- Workflow patterns and common tasks
- Important project context that isn't in documentation

### What Should NOT Be Remembered

- Sensitive credentials or API keys
- Large code blocks (reference files instead)
- Temporary debugging information
- Personal or proprietary business information
- Session-specific error logs
- Information already documented in the codebase

### Other MCP Server Guidelines

**General MCP Principles:**
- Only add trusted, verified MCP servers
- Use minimal required permissions and credentials
- Configure with appropriate scope (local/project/user)
- Regularly review and audit configured servers

**Common MCP Server Rules:**

**GitHub MCP** (`@modelcontextprotocol/server-github`):
- Use OAuth authentication only - never store tokens in code
- Limit to read-only operations when possible
- Use for repository exploration, not sensitive operations
- Commands: `/mcp__github__list_prs`, `/mcp__github__pr_review`

**Postgres MCP** (`@modelcontextprotocol/server-postgres`):
- Use read-only database credentials
- Only for schema inspection and safe queries
- Never use for production database modifications
- Ensure connection strings use minimal required permissions

**Filesystem MCP** (`@modelcontextprotocol/server-filesystem`):
- Restrict access to specific directories only
- Never grant access to sensitive system directories
- Use for project-specific file operations
- Reference files with `@docs:file://path` syntax

**Brave Search MCP** (`@modelcontextprotocol/server-brave-search`):
- Use for research and documentation lookup only
- Be mindful of API rate limits
- Don't rely on for sensitive or critical information verification

**Supabase MCP** (`@modelcontextprotocol/server-supabase`):
- Write access is enabled - use with extreme caution
- Never modify production data without explicit user permission
- Always confirm database operations before execution
- Use for development and staging environments primarily

**Shell MCP** (`@modelcontextprotocol/server-shell`):
- Never run destructive commands without user confirmation
- Avoid commands that modify system settings
- Prefer project-specific scripts over raw shell commands
- Always explain what shell commands will do before execution

**Docker MCP** (`@modelcontextprotocol/server-docker`):
- Only use for development containers
- Never manipulate production containers
- Always check container status before operations
- Prefer docker-compose commands when available

**Sentry MCP** (`@modelcontextprotocol/server-sentry`):
- Use for error monitoring and debugging only
- Never modify production error settings
- Focus on read-only operations for investigation
- Respect rate limits and API quotas

**Figma MCP** (`@modelcontextprotocol/server-figma`):
- Use for design system documentation and asset retrieval
- Never modify production design files
- Prefer read-only operations unless explicitly requested
- Coordinate with design team for any changes

**Context7 MCP** (`@modelcontextprotocol/server-context7`):
- Use for enhanced context management
- Configured with 10000 minimum tokens
- Leverage for complex codebase analysis
- Ideal for large-scale refactoring tasks

---

_These general guidelines ensure consistent, safe, and effective AI-driven code assistance across projects._
