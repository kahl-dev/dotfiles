## Code Principles

**Architecture:**

- Prefer boring solutions over clever abstractions
- Clear function names over magic
- Small, focused functions
- Explicit over implicit
- Start simple, add complexity only when proven necessary

**Quality:**

- Code is read more than written - optimize for clarity
- Run linters/tests after every implementation
- Delete old code completely when replacing
- No deprecated functions or versioned names

**File System:**

- Use `~/.cache` for temporary files, never `/tmp`
- Cache files should use stable paths: `${XDG_CACHE_HOME:-$HOME/.cache}/app-name`
- Avoid PID-based filenames (`$$`) - defeats caching purpose
- Set restrictive permissions on cache directories: `chmod 700`