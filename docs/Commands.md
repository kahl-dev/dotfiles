# Command Tool Reference

## 1. Shell-GPT

- [Repository Link](https://github.com/TheR1D/shell_gpt)

Shell-GPT provides a command-line interface for querying OpenAI's GPT models. This can be particularly handy for quick answers or for obtaining shell commands for specific tasks.

### Commands:

- **General Queries**:
  ```
  sgpt "<your-query>"
  ```
- **Shell Commands**:

  ```
  sgpt -s "<shell-related-query>"
  ```

- **Chat Management**:
  - List chats: `sgpt --list-chats`
  - Show a specific chat: `sgpt --show-chat <number>`

### Sample Usage:

```sh
sgpt "1 hour and 30 minutes to seconds"
# Output: 5,400 seconds

git diff | sgpt "Generate git commit message, for my changes"
# Output: Implement Model enum and get_edited_prompt()

sgpt --shell "make all files in current directory read only"
# Suggestion: chmod 444 *
# [E]xecute, [D]escribe, [A]bort: e
```

## 2. Copilot CLI

GitHub Copilot's CLI provides intelligent code suggestions right from your terminal.

### Commands:

- **CLI Queries**: `??`
- **Git Related Queries**: `git?`
- **GitHub CLI Queries**: `gh?`

## 3. Git recent

- [Repository Link](https://github.com/paulirish/git-recent)

Git recent displays your most recently checked-out branches.

### Usage:

```zsh
git recent # Displays recent branches
git recent -n5 # Displays the 5 most recent branches
```

## 4. Git recall

- [Repository Link](https://github.com/Fakerr/git-recall)

Git recall is an interactive CLI tool to navigate through your git history.

### Usage:

```sh
git recall [-a <author name>]
           [-d <days-ago>]
           [-b <branch name>]
           [-p <paths>]
           [-f]
           [-h]
           [-v]
```

### Options:

- `-a`: Filter by author (use `-a "all"` for all users)
- `-d`: Filter commits from the last `n` days
- `-b`: Filter commits from a specific branch
- `-p`: Filter commits by path or file
- `-f`: Fetch the latest changes
- `-h`: Show the help screen
- `-v`: Display version

### Navigation:

- Use `arrow keys` or `j/k` to navigate commits.
- Press `TAB` or `e` to expand/reduce a commit's diff.
- Press `q` to exit the interface.
