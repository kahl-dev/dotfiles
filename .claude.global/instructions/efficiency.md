## Efficiency Patterns

**Mandatory Parallel Operations:**

- **Git workflows**: ALWAYS batch `git status` + `git diff` + `git log` in single message
- **File exploration**: Multiple file reads when investigating features
- **Search operations**: Batch Grep/Glob searches with different patterns
- **Agent research**: Launch multiple agents simultaneously for complex analysis
- **Read-only investigations**: Any operations that don't modify state

**Parallel Pattern Examples:**

```markdown
# ✅ Optimal - Single message with multiple tools
- git status (check working directory)
- git diff (see staged changes)
- git log --oneline -5 (recent commits)

# ❌ Inefficient - Sequential messages
Message 1: git status
Message 2: git diff  
Message 3: git log
```

**When NOT to Parallelize:**
- Sequential file modifications (order matters)
- Build → test → deploy sequences
- Operations with dependencies
- High system load periods (> 8.0 load average)

**Intelligent Batching:**
- Batch operations by independence, not convenience
- Consider system resources (load protection active)
- Group related context gathering
- Separate investigation from implementation

**Tool Priority:**

- Use Task for complex searches across many files
- Direct tools (Grep/Glob) for specific operations
- Project scripts over generic commands

Remember: Focus on maintainable solutions. When uncertain, ask for guidance.