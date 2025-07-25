📋 Find and implement the next incomplete task from the project todo list.

- Read the file `.llm/todo.md`
  - The file will only exist in this directory or in the main repository if we're in a worktree.
  - First try reading `./.llm/todo.md`
  - If that doesn't exist, use `git rev-parse --git-common-dir` to find the main repository and check if `.llm/todo.md` exists there.
  - Don't look in other locations. Don't look in the home directory.
- Find the first line with an incomplete task, with `- [ ] <task>` (not `[x]` or `[>]`)
  - Keep in mind that the completed tasks might not be contiguous, since it's common to prepend new tasks at the top
- Show the user the task we just found. Use the format:

```markdown
The next incomplete task is:

- [ ] Replace DEF with ABC.
```

- Think hard about the plan
- Implement the task
- Focus ONLY on implementing this specific task
- Ignore all other tasks in the `.llm/todo.md` file or TODOs in the source code
- Work through the implementation methodically and completely, addressing all aspects of the task
- Run appropriate tests and validation to ensure the implementation works
- ✅ After the implementation is complete and verified, update `.llm/todo.md` to mark the completed task as done by changing `- [ ]` to `- [x]`
