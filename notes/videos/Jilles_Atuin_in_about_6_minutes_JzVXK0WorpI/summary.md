# Atuin in about 6 minutes

**Video:** https://www.youtube.com/watch?v=JzVXK0WorpI
**Channel:** Jilles
**Published:** 2026-07-16
**Duration:** 5:50

---

## Description

If you use the terminal every day, Atuin makes your shell history dramatically more useful. In this video I walk through installing Atuin, importing and syncing shell history, fuzzy searching commands, switching between directory/host/session/workspace scopes, customizing keybindings and filters, viewing command statistics, and using the optional Atuin AI features.

Check it out: https://atuin.sh/

### Chapters

| Time | Topic |
|------|-------|
| 0:00 | Intro: better shell history with Atuin |
| 0:41 | Installing Atuin and importing history |
| 0:49 | Encrypted history sync across machines |
| 1:24 | Searching commands with Ctrl+R |
| 1:38 | Host, session, directory, and workspace scopes |
| 2:04 | Fuzzy, prefix, and full-text search |
| 2:36 | Quick selection and configuration |
| 2:50 | Mapping directory history to the up arrow |
| 3:10 | Running vs. inserting commands |
| 3:24 | History filters and privacy settings |
| 3:43 | Changing the search interface height |
| 4:03 | Syncing history across computers |
| 4:15 | Command details and statistics |
| 4:39 | Using Atuin AI in your shell |
| 5:29 | Final thoughts |

---

## Key Insights

### Filter scopes cycle on repeated Ctrl+R (01:38)

Pressing Ctrl+R again while the TUI is open switches the scope rather than closing it. The cycle is **global → host → session → directory → workspace**. Workspace scope covers every command run anywhere inside a Git repository tree, so a subfolder still shows the whole repo's history.

### Search mode cycles on Ctrl+S (02:04)

Independent of the scope. **Fuzzy** (default, `gtdf` → `git diff`), **prefix** (everything starting with `git`), **full-text** (matches the actual word). Two orthogonal dimensions — scope on Ctrl+R, matching on Ctrl+S.

### Up-arrow can be scoped to the current directory (02:50)

`filter_mode_shell_up_key_binding = "directory"` makes the up arrow show only commands run in the current directory, but with the full Atuin TUI instead of plain scrollback. The presenter calls this his most-used setting.

### Enter runs, Tab inserts (03:10)

Enter executes the selected command immediately; Tab puts it on the prompt for editing. Governed by `enter_accept`.

### Alt+N jumps to result N (02:36)

Numbered results in the list are directly selectable with Alt+number — no arrow-key scrolling.

### Two privacy settings worth knowing (03:24)

- `history_filter` — regex; matching commands are never written to history
- `cwd_filter` — regex on the working directory; commands run there are never stored

Suggested uses: `node_modules`, or any directory holding confidential work.

### Ctrl+O opens command details (04:15)

Per-command stats: which host, which user, when, duration over time, and an exit-code distribution.

### Atuin AI is opt-in and self-hostable (04:39)

Bound to `?` by default. Generates commands or answers questions with the shell history as context; Enter executes the suggestion, Tab inserts it. Both the sync server and the AI backend can be self-hosted.

### The presenter's own cautionary tale (00:49)

He skipped sync at first, bought a new MacBook, and lost his entire shell history. Sync is end-to-end encrypted and optional — but that is the argument for turning it on.

---

## Relevance to this repo

Reviewed 2026-07-24 against the local Atuin setup. Notes for the pending upgrade work:

- The video's install path is the same `curl | sh` route used in `zsh/config/atuin.zsh`. That block is install-if-missing only — it never updates. The local binary has sat at 18.3.0 since 2024-06-10 while 18.17.1 is current.
- **Workspace scope** (01:38) is the single most relevant feature here given the `gwta`/`gwts` worktree helpers in `zsh/config/worktree.zsh`. Needs `workspaces = true`; 18.14.0 fixed worktree-to-main-repo resolution for it.
- **Host scope** (01:38) matters for the Mac/Pi/server fleet. Pairs with the `[ui] columns` option (18.x) to actually show a `host` column in results.
- `filter_mode_shell_up_key_binding` (02:50) already exists in 18.3.0 — this one is usable before upgrading.
- The video does not cover several features that postdate its framing but exist in 18.17.1: `atuin mcp`, `atuin scripts`, `atuin config`, `[tmux]` popup search, and `[theme]`.

---

## Resources

### Links from Description

- [Atuin — official site](https://atuin.sh/)

### Related Notes

- `CLAUDE.md` → "atuin: Shell history sync/search in `zsh/config/atuin.zsh`"
- `zsh/config/atuin.zsh` — init and install block
- `zsh/config/keybindings.zsh:60-62` — Ctrl+R bound to `atuin-search` in viins/vicmd
- `zsh/config/aliases.zsh:487-551` — `av*` helpers around `atuin dotfiles var`
- `remote-bridge/lib/bridge-token.sh` — uses `atuin dotfiles var` as the token store

---

**Retrieved:** 2026-07-24
