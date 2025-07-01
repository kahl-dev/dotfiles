# General AI Agent Guidelines

This document defines general behavioral guidelines for AI assistants working with codebases.

---

## 1. Purpose

- Ensure consistent, safe interaction with repositories
- Leverage project-specific tools rather than ad-hoc shell commands
- Maintain existing conventions and avoid unintended side effects

---

## 2. Preferred Tooling Order

1. **Grep** – locate code by content (functions, constants, patterns)
2. **Glob** – locate files by name patterns or wildcards
3. **Read** – inspect file contents once you have the path
4. **LS** – explore directory structure and list files
5. **Edit/MultiEdit** – create or modify source files
6. **Write** – create new files when absolutely necessary
7. **Task** – delegate complex search tasks to specialized agents
8. **Bash** – run project-specific commands (e.g. `make dev`, `npm test`, linting)

> Always prefer project-specific scripts and tools over ad-hoc shell commands.

---

## 3. Task Management & Planning

### TodoWrite/TodoRead Usage

**When to Use Todo Lists:**
- Complex multi-step tasks requiring 3+ distinct operations
- User provides multiple tasks or requirements
- Large-scale refactoring or system-wide changes
- When explicit task tracking would benefit user visibility

**When NOT to Use Todo Lists:**
- Single, straightforward tasks
- Trivial operations requiring <3 steps
- Purely conversational or informational requests

**Best Practices:**
- Create todos BEFORE starting work on complex tasks
- Mark tasks as `in_progress` when beginning work
- Complete tasks IMMEDIATELY after finishing (don't batch)
- Only have ONE task `in_progress` at a time
- Use descriptive, actionable task names
- Break large tasks into smaller, manageable steps

**Task States:**
- `pending`: Not yet started
- `in_progress`: Currently working on (limit to one)
- `completed`: Finished successfully

**Example Workflow:**
```
1. User requests complex feature
2. Create todo list with specific steps
3. Mark first task as in_progress
4. Complete task, mark as completed
5. Move to next task
6. Repeat until all tasks completed
```

### Plan Mode Guidelines

**When to Use Plan Mode:**
- Complex implementation tasks requiring code changes
- Multi-file modifications or refactoring
- System architecture changes
- Large feature implementations

**When NOT to Use Plan Mode:**
- Research tasks or information gathering
- Simple file reads or searches
- Understanding existing code
- Answering questions about codebases

**Plan Mode Process:**
1. Analyze requirements thoroughly
2. Research existing codebase patterns
3. Create detailed implementation plan
4. Present plan via `exit_plan_mode`
5. Wait for user approval before proceeding

---

## 4. Markdown & Code Block Conventions

- Use path-anchored, language-labeled backtick blocks with the path immediately following the label:

  ```ts path/to/file.ext#Lstart-end
  // code snippet with TypeScript types
  ```

- Paths must begin at one of the root directories
- Include the appropriate language label (`ts`, `js`, `vue`, etc.) after the opening backticks for syntax highlighting

---

## 4. Core Behavioral Guidelines

### File & Path Management

- **Never** guess or hard-code file paths; always discover via Grep or Glob
- **Do not** add new dependencies unless declared in `package.json` or explicitly approved
- Ask clarifying questions if a request is ambiguous
- **Prefer existing files**: Always edit existing files rather than creating new ones

### Git & Version Control

- **NEVER commit unless explicitly requested** by the user - always wait for explicit permission to commit
- **Each commit requires individual authorization** - no wildcards or blanket permissions for multiple commits
- **Only use Git commands when explicitly requested** by the user
- **Use dedicated commit rules**: When committing, reference and follow dedicated commit guidelines/prompts rather than using ad-hoc commit messages

### Code Quality & Standards

- Conform to existing code style and linting rules
- **Analyze actual file changes for commit messages** - don't include everything from chat conversation, investigate the real changes made and write focused commit messages based on actual code modifications
- **Study existing patterns** before proposing solutions
- **Check package versions** and compatibility before suggesting changes

---

## 5. Parallel Execution & Error Handling

### Parallel Tool Execution

- **Batch Independent Operations**: Use multiple tool calls in a single response when possible
- **Git Operations**: Always run `git status`, `git diff`, and `git log` in parallel for commits
- **Search Operations**: Run multiple Grep/Glob searches concurrently when exploring codebases
- **Quality Checks**: Execute linting, testing, and security checks simultaneously after changes

### Error Handling & Recovery

- **Failed Operations**: Always explain what went wrong and suggest alternatives
- **Missing Dependencies**: Check project configuration before suggesting installations
- **Permission Issues**: Guide users through proper authorization steps
- **Tool Failures**: Provide fallback approaches when primary tools fail

### Workflow Optimization

- **Study Patterns First**: Always analyze existing code patterns before implementing
- **Use Project Tools**: Prefer project-specific scripts over generic commands
- **Validate Changes**: Run appropriate quality checks after modifications
- **Incremental Progress**: Break complex tasks into smaller, testable steps

---

## 6. Communication Protocol

### User Interaction Guidelines

1. **Wait for User Input**: When presenting multiple choices, options, or implementation approaches, ALWAYS wait for the user to specify their preference before proceeding
2. **Present Clear Options**: When multiple solutions are possible, present them clearly numbered or bulleted with brief descriptions
3. **Confirm Before Implementation**: Before implementing any significant changes, confirm the chosen approach with the user
4. **Ask for Clarification**: If the user's request could be interpreted in multiple ways, ask for clarification rather than assuming
5. **Respect User Decisions**: Once the user makes a choice, implement exactly what they requested without second-guessing
6. **Progress Communication**: Keep users informed of progress on complex tasks using todo lists
7. **Error Transparency**: Clearly explain what went wrong and suggest solutions when tools fail

### Response Guidelines

- **Conciseness**: Provide clear, direct answers without unnecessary elaboration
- **Code Context**: Include file paths and line numbers when referencing specific code locations
- **Actionable Feedback**: Always provide next steps or actionable recommendations
- **Scope Awareness**: Focus on the specific request without expanding scope unnecessarily

### Information Sharing

- **Configuration**: Environment variables are in `.env` files (never share actual values)
- **API Keys**: Reference them by environment variable names only  
- **User Data**: Follow GDPR principles and never expose personal information
- **Debugging**: Share sanitized logs without sensitive information
- **File References**: Use format `file_path:line_number` for easy navigation

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

## 9. MCP Server Guidelines

### MCP Best Practices

**General MCP Principles:**
- Only add trusted, verified MCP servers from official sources
- Use minimal required permissions and credentials
- Configure with appropriate scope (local/project/user)
- Regularly review and audit configured servers
- Test MCP servers in development before production use
- Document MCP server configurations and their purposes

**Security Guidelines:**
- Never store credentials in MCP configurations
- Use environment variables for sensitive data
- Limit MCP server access to necessary directories only
- Regularly update MCP servers to latest versions
- Monitor MCP server activity and resource usage

**Performance Considerations:**
- Disable unused MCP servers to reduce overhead
- Use specific, targeted MCP servers rather than generic ones
- Monitor response times and adjust configurations accordingly
- Consider caching when appropriate for frequently accessed data

### Common MCP Server Examples

**Filesystem MCP** (`@modelcontextprotocol/server-filesystem`):
- **Purpose**: Safe file system operations within defined boundaries
- **Security**: Restrict to project directories only, never system directories
- **Use Cases**: Project file management, safe code exploration

**GitHub MCP** (`@modelcontextprotocol/server-github`):
- **Purpose**: Repository management and collaboration
- **Security**: Use read-only tokens when possible, OAuth authentication
- **Use Cases**: PR reviews, issue tracking, repository exploration

**Postgres MCP** (`@modelcontextprotocol/server-postgres`):
- **Purpose**: Database schema inspection and safe queries
- **Security**: Use read-only credentials, never production write access
- **Use Cases**: Schema analysis, development database queries

**Context7 MCP** (`@upstash/context7-mcp`):

- **Purpose**: Real-time, version-specific documentation provider for libraries and frameworks
- **Primary Use Cases**:
  - Get up-to-date official documentation for any library or framework
  - Access version-specific code examples and API references
  - Eliminate outdated documentation issues in AI coding assistance
- **Available Tools**:
  - `resolve-library-id`: Convert general library names to Context7-compatible IDs
  - `get-library-docs`: Fetch current documentation for specified libraries
- **Best Practices**:
  - Use when working with external libraries/frameworks to ensure accuracy
  - Particularly valuable for rapidly evolving libraries (React, Next.js, Nuxt, Nuxt UI v3, etc.)
  - Always specify version numbers when possible for precise documentation
  - Leverage before implementing new features with unfamiliar APIs
- **When to Use**:
  - Starting new projects with external dependencies
  - Upgrading libraries and need migration guidance
  - Debugging issues with third-party APIs
  - Learning new frameworks or libraries
  - Ensuring code examples match current library versions
- **Performance**: Fetches documentation on-demand, minimal overhead

---

## 10. Continuous Improvement & Adaptation

### Learning from User Preferences

- **Document Patterns**: When discovering user preferences or project-specific patterns, suggest adding them to CLAUDE.md files
- **Configuration Updates**: Recommend improvements to project configurations based on observed workflows
- **Tool Usage**: Adapt tool selection based on project characteristics and user feedback

### Quality Assurance

- **Post-Implementation Review**: After completing tasks, verify results match user expectations
- **Error Pattern Recognition**: Learn from failures to improve future approaches
- **Best Practice Evolution**: Update approaches based on successful patterns and user feedback

### Knowledge Management

- **Context Preservation**: Maintain awareness of project architecture and conventions across sessions
- **Documentation Gaps**: Identify and suggest improvements to project documentation
- **Configuration Management**: Help users maintain and improve their development environment configurations

_These guidelines ensure continuous improvement and adaptation in AI-assisted development workflows._

---

## 11. Task Management System

### Task Organization

- **Task Location**: `.tasks/` in each project (active/backlog/done/scripts folders)
- **Always Check First**: Scan `.tasks/active/` before starting any work
- **JIRA Integration**: Include JIRA ticket IDs in task files and commit messages
- **Continuity**: Reference existing tasks when continuing work across sessions

### Available Commands

- `/task-new` - Create new task from context, plans, or arguments
- `/task-from-text` - Convert scratchpad notes or todos into structured tasks
- `/task-list` - Show all open tasks with filtering options
- `/task-continue` - Resume work on existing tasks
- `/task-help` - Display usage guide and examples

### Task File Format

Tasks use structured markdown with YAML frontmatter:
- **Status**: active, backlog, or done
- **Type**: feature, bug, refactor, etc.
- **JIRA**: Ticket ID for traceability
- **Steps**: Actionable checkboxes for progress tracking
- **Context**: Background information and requirements

### Workflow Integration

- **TodoWrite Integration**: Load tasks into todo lists for progress tracking
- **Commit Message Generation**: Automatically include JIRA IDs in conventional commits
- **Context Preservation**: Maintain task awareness across Claude sessions
- **Progress Tracking**: Update task files as work progresses

