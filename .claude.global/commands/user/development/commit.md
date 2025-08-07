# Commit Command

## Description
Creates Git commits following the Conventional Commits specification v1.0.0-beta.2.

## Commit Message Format
```
<type>[optional scope]: <description>

[optional body]

[optional footer]
```

## Types
- **feat**: A new feature (correlates with MINOR in semantic versioning)
- **fix**: A bug fix (correlates with PATCH in semantic versioning)
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **chore**: Other changes that don't modify src or test files

## Scope (Optional)
- Provides additional contextual information
- Contained within parentheses: `feat(parser): add ability to parse arrays`
- Should be a noun describing the section of codebase

## Breaking Changes
- Must be indicated by `BREAKING CHANGE:` in body or footer
- Correlates with MAJOR version in semantic versioning
- Example:
  ```
  feat: allow config object to extend other configs

  BREAKING CHANGE: `extends` key now used for extending config files
  ```

## Workflow
When user requests a commit:

1. **Check Status**: `git status` to see current state
2. **Review Changes**: `git diff` to understand modifications
3. **Check History**: `git log --oneline -5` for context
4. **Stage Files**: Add relevant files to staging area
5. **Analyze Changes**: Determine appropriate type and scope
6. **Create Commit**: Follow conventional format
7. **Verify**: `git status` to confirm success

## Rules
- **Type is mandatory**
- **Description is mandatory** (lowercase, no period at end)
- **Body and footer are optional**
- **NEVER commit without explicit user request**
- **Each commit requires individual authorization**
- **NEVER include AI generation attribution**
- **Focus on actual file changes, not conversation**
- **Stage only files directly related to the change**

## Examples
```bash
# Simple feature
git commit -m "feat: add user authentication"

# With scope
git commit -m "fix(auth): resolve token expiration issue"

# With body
git commit -m "feat: add email notifications

Send welcome email when user registers and confirmation
email when user updates their profile information."

# Breaking change
git commit -m "feat: update API response format

BREAKING CHANGE: API now returns user data in nested object
instead of flat structure. Update client code accordingly."
```