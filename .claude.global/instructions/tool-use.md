## Directory Navigation

- I replaced `cd` with `zoxide`. Use `command cd` to change directories.
  - This is the only command that needs to be prefixed with `command`.
  - Don't prefix `git` with `command git`.
- Try not to use `cd` or `zoxide` at all. It's usually not necessary with CLI commands.
  - Don't run `cd <dir> && git <subcommand>`
  - Prefer `git -C <dir> <subcommand`

## Tool Selection Priority

**For searching and exploration:**
1. **Use Task tool** for complex searches requiring multiple rounds of globbing/grepping
2. **Use Grep/Glob directly** for specific, targeted searches when you know what to look for
3. **Never use bash commands** like `find` or `grep` - use the specialized tools instead

## Performance-Optimized Tools

The following tools are automatically aliased for maximum performance:
- `grep` → executes ripgrep (`rg`) - 100x faster
- `find` → executes fd - 100x faster  
- `sed` → executes sd - simpler syntax

You can use standard commands and get optimized versions automatically.
Direct paths also available:
- `/opt/homebrew/bin/rg`
- `/opt/homebrew/bin/fd`
- `/opt/homebrew/bin/sd`

**For file operations:**
1. **Read tool** for viewing file contents (supports images too)
2. **Edit/MultiEdit** for modifying existing files
3. **Write tool** only when creating new files (avoid when possible)

## Parallel Execution

**Always batch operations when possible:**
```
# Good - Single message with multiple tool calls
- git status
- git diff
- git log --oneline -5

# Bad - Sequential separate messages
```

**Common parallel patterns:**
- Multiple file reads when exploring a feature
- Git status + diff + log when understanding changes
- Multiple grep searches with different patterns

## Error Handling

**When tools fail:**
1. Read error messages carefully - they often contain the solution
2. Check file paths are absolute, not relative
3. Verify permissions with appropriate tools
4. Never use --force flags without explicit user permission

## Security Constraints

**Never use these patterns:**
- `rm -rf` operations
- `git push` without explicit permission
- Long-running processes (`npm run dev`, `npm start &`)
- Commands that modify production systems

**Always validate:**
- File paths to prevent traversal attacks
- Input from external sources
- Credentials are from environment variables, not hardcoded
