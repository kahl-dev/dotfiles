# Commands

### Copilot CLI

- `??` Ask for cli commands
- `git?` Ask for git commands
- `gh?` Ask for github cli commands

### Git recent

[https://github.com/paulirish/git-recent](https://github.com/paulirish/git-recent)

## Usage

```zsh
git recent
```

Optionally, add `-n<int>` to see the most recent `<n>` branches

```zsh
git recent -n5
```

### Git recall

An interactive way to peruse your git history from the terminal

[https://github.com/Fakerr/git-recall](https://github.com/Fakerr/git-recall)

## Usage

```sh
$ git recall   [-a <author name>]
               [-d <days-ago>]
               [-b <branch name>]
               [-p <paths>]
               [-f]
               [-h]
               [-v]
```

##### Options description:

- `-a` - Restrict search for a specific user (use -a "all" for all users)
- `-d` - Display commits for the last n days
- `-b` - Specify branch to display commits from
- `-p` - Specify path/s or file/s to display commits from
- `-f` - Fetch the latest changes
- `-h` - Show help screen
- `-v` - Show version

##### How to use:

Once the commits are displayed, you can use either the `arrow keys` or `j/k` to switch between commits,
press `TAB` or `e` to `expand/reduce` the commit's diff or `q` to quit.
