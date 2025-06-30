# LIA Commit Command

## Description
Creates Git commits following the Conventional Commits specification with mandatory Jira ticket integration for LIA projects.

## Commit Message Format
```
<type>(TICKET-ID): <description>

[optional body]

[optional footer]
```

**Key Difference**: Scope is **mandatory** and must be a Jira ticket ID in the format `TICKET-ID` (e.g., `LIA-123`, `PROJ-456`).

## Types
- **feat**: A new feature (correlates with MINOR in semantic versioning)
- **fix**: A bug fix (correlates with PATCH in semantic versioning)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Other changes that don't modify src or test files

## Jira Ticket ID (Mandatory)
- **Required for all commits** in LIA projects
- Must be a valid Jira ticket ID in format: `ABC-123`
- Contained within parentheses: `feat(LIA-123): add ability to parse arrays`
- Automatically extracted from branch names when following naming convention
- Examples: `LIA-456`, `PROJ-789`, `TASK-101`

## Breaking Changes
- Must be indicated by `BREAKING CHANGE:` in body or footer
- Correlates with MAJOR version in semantic versioning
- Example:
  ```
  feat: allow config object to extend other configs

  BREAKING CHANGE: `extends` key now used for extending config files
  ```

## LIA Workflow
When user requests a commit in LIA projects:

1. **Check Status**: `git status` to see current state
2. **Review Changes**: `git diff` to understand modifications
3. **Check History**: `git log --oneline -5` for context and existing patterns
4. **Extract Jira Ticket**: 
   - Try to extract from current branch name (e.g., `feature/LIA-123-description`)
   - If not found, **ask user for ticket ID**
   - Validate format matches `[A-Z]+-[0-9]+` pattern
5. **Stage Files**: Add relevant files to staging area
6. **Analyze Changes**: Determine appropriate type based on actual modifications
7. **Create Commit**: Follow format `<type>(TICKET-ID): <description>`
8. **Verify**: `git status` to confirm success

## LIA Rules
- **Type is mandatory**
- **Jira ticket ID is mandatory** in parentheses after type
- **Description is mandatory** (lowercase, no period at end)
- **Body and footer are optional**
- **NEVER commit without explicit user request**
- **Each commit requires individual authorization**
- **NEVER include AI generation attribution**
- **Focus on actual file changes, not conversation**
- **Stage only files directly related to the change**
- **Always ask for ticket ID if not extractable from branch**
- **Validate ticket ID format: [A-Z]+-[0-9]+**

## LIA Examples
```bash
# Feature with Jira ticket
git commit -m "feat(LIA-123): add user authentication"

# Bug fix with Jira ticket
git commit -m "fix(LIA-456): resolve token expiration issue"

# With body
git commit -m "feat(PROJ-789): add email notifications

Send welcome email when user registers and confirmation
email when user updates their profile information."

# Breaking change with Jira ticket
git commit -m "feat(LIA-101): update API response format

BREAKING CHANGE: API now returns user data in nested object
instead of flat structure. Update client code accordingly."

# Various project prefixes
git commit -m "chore(TASK-202): update dependencies"
git commit -m "docs(BUG-303): improve API documentation"
git commit -m "test(STORY-404): add integration tests"
```

## Branch Name Extraction
The ticket ID will be automatically extracted from branch names following these patterns:
- `feature/LIA-123-description` → `LIA-123`
- `fix/PROJ-456-bug-description` → `PROJ-456`
- `LIA-789-hotfix` → `LIA-789`
- `bugfix/TASK-101-issue` → `TASK-101`