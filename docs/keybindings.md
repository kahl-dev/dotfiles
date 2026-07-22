# Keybindings across the stack

Read this before changing any keyboard shortcut in this repo. Keybindings here
are spread across seven files in two repositories, stacked in layers where an
upper layer can silently swallow a key that a lower one needs. Most conflicts
are invisible until something you use daily stops working.

## The layers

Each layer sees a key first and can consume it. Nothing below ever learns the
key was pressed.

```
Karabiner-Elements       rewrites raw key events before any app
AeroSpace / Hammerspoon  global hotkeys
Ghostty                  the terminal window
tmux                     prefix and root-table bindings
nvim / zsh / lazygit / yazi / claude / opencode
```

A binding added at the top costs every layer beneath it. That asymmetry is the
whole problem: adding `ctrl+g` to Ghostty took the key away from nvim, Claude
Code and opencode at once, and none of them can report it.

## Ownership rule

| Layer | Owns | Rationale |
|---|---|---|
| Ghostty | `Cmd` | Cmd never reaches a program inside the terminal, so binding it costs nothing below. Ghostty's own macOS defaults already work this way. |
| tmux | its prefix (`Ctrl+S`) plus a small root set | One reserved key, not a family. |
| TUIs | `Ctrl`, `Alt` | Ctrl-chords are readline and vim territory; every TUI expects them. |

Before binding a key in Ghostty, check whether Ghostty already has a Cmd default
for that action:

```bash
ghostty +list-keybinds --default | grep <action>
ghostty +list-actions
```

The command palette (`Cmd+Shift+P`) is the interactive equivalent.

## Files that carry keybindings

| File | Layer |
|---|---|
| `.config/karabiner/karabiner.json` | Karabiner (homerow mods, caps, Meh/Hyper) |
| `.config/aerospace/aerospace.toml` | window manager |
| `.config/ghostty/config` | terminal |
| `tmux/tmux.conf` | tmux |
| `zsh/config/keybindings.zsh` | shell |
| `.config/nvim/lua/config/keymaps.lua` + `lua/plugins/*.lua` | editor |
| `.config/lazygit/config.yml` | lazygit `customCommands` (`N`, `Ctrl+C`, `Ctrl+T`) |
| `.config/btop/btop.conf` | btop, via `vim_keys` |
| `.config/wezterm/wezterm.lua` | wezterm (currently only a disabled block) |
| `~/.claude/keybindings.json` | Claude Code — **lives in the `claude-config` repo** |

`.config/yazi/` carries no custom keymap today and runs on yazi's defaults; it
still belongs on the checklist because a `keymap.toml` added later would not
announce itself.

`.config/kanata/kanata.kbd` remaps the same physical keys as Karabiner but is
not running. Do not enable it without removing the Karabiner rules first.

## Register of deliberate deviations

Only what departs from a default, with the reason. A register listing every
binding would drift; one listing the exceptions stays maintainable.

Locations are given as search terms, not line numbers — line numbers rot on the
first unrelated edit.

| Key | Find it via | Deviation | Why |
|---|---|---|---|
| `Ctrl+S` | `tmux.conf` → `set -g prefix` | prefix, not `Ctrl+B` | Frees `Ctrl+B`, which Claude Code uses for `task:background`. Costs `chat:stash`, whose default is `Ctrl+S`. |
| `Alt+S` | `claude-config/keybindings.json` | `chat:stash` | Replaces the default `Ctrl+S`, which the tmux prefix takes. Deliberately in the Alt layer rather than a `ctrl+x` chord: a chord prefix reserves the bare key, which is how the previous workaround broke `Ctrl+X` in the agent view. |
| `Ctrl+H/J/K/L` | `tmux.conf` → `forward_programs` | root bindings for pane navigation | Uniform pane movement. `forward_programs` lists who gets them passed through: `view`, `nvim`, `fzf` — these hand the key back to tmux. Claude Code, opencode, yazi and lazygit are deliberately absent; they cannot hand it back, so adding them would trade pane navigation for little gain. |
| `Ctrl+R` | `keybindings.zsh` → `atuin-search` | atuin instead of reverse-search | Synced shell history. |
| `Ctrl+U` / `Ctrl+N` | `keybindings.zsh` → `bindkey -s` | macros | Session manager, fzf-to-nvim. Note these shadow the readline defaults. |
| `Ctrl+G` | `nvim keymaps.lua` → `<C-g>` | copies the relative path | Replaces vim's file-info display. |
| Option | `ghostty/config` → `macos-option-as-alt` | `= right` | See the note below — the observed behaviour is broader than the setting suggests. |
| homerow `a s d f j k l ;` | `karabiner.json` → `Home row mods` | hold produces a modifier | Thresholds: 180 ms hold, 200 ms tap. Side effect: holding these keys never repeats, so hold-to-scroll does not work in any app except Terminal.app and iTerm2, which are excluded. `l` = right Option is what supplies Alt on keyboards without a physical right Option. |
| `Ctrl+Space` | `setup_defaults_write.sh` → `symbolichotkeys` | macOS input-source switcher disabled | Frees the key for editor completion. |

### Note on `macos-option-as-alt = right`

The setting says only the right Option acts as Alt. **Measured behaviour on this
machine is broader:** `Alt+T` reaches Claude Code through the left Option, the
right Option, homerow `s` (left Option) and homerow `l` (right Option) alike —
while `Option+u` followed by `a` still composes `ä`. Both work at once, which the
setting alone does not promise.

The likely cause is `extended-keys on` with `csi-u` (`tmux.conf`): in that
protocol Ghostty reports modifier bits to the TUI instead of composing a
character, so a TUI sees Alt while dead-key composition keeps working for
sequences that ask for it.

Two consequences worth knowing:

- `right` and `left` may be indistinguishable in this setup. The value was chosen
  for the German-keyboard future, where the left Option must keep producing
  `{ } [ ] @ | ~` exactly as it does in GUI apps.
- If those characters ever misbehave in the terminal, this setting is the first
  place to look. Verify against the machine, not against this table.

Ghostty's own default for this option is layout-dependent: `true` on U.S. and
U.S. International layouts, `false` otherwise.

## Diagnosing a broken key

The first question decides everything:

**Did it ever work?**

*Yes, it stopped* — this is a regression, and something was added above the app
that now eats the key. Find it:

```bash
git log --oneline -S "<the key>" -- <config file>
git log -1 --format=%ad --date=short <commit>
```

*No, it never worked* — this is a standing conflict, not a regression. It is
worth understanding, but it is not what broke your day, and it usually has a
different cause than the thing you just noticed.

Then walk the layers top-down and ask which one binds the key. `Ctrl` bindings
in Ghostty and tmux are the usual culprits, because those two sit above every
TUI.

### Do not patch downstream

When a key disappears, the tempting fix is to rebind the affected app. That
moves the symptom and hides the cause, and the replacement binding can break
something else in turn. In July 2026, a Ghostty remap of `Ctrl+T` led to two
workaround chords in `keybindings.json`, and those chords reserved `Ctrl+X`,
which broke deleting sessions in Claude Code's agent view. One binding, three
casualties. Fix the layer that took the key.

## Findings worth keeping

- Ghostty ships Cmd defaults for every split, zoom, navigate, equalize, close
  and fullscreen action. A custom leader table for window management duplicates
  them and costs a Ctrl key.
- `macos-option-as-alt` accepts `true`, `false`, `left` and `right`. An
  Option sequence that produces no printable character is treated as Alt
  regardless of the setting.
- Ghostty's `unbind` frees a default so it passes through to the TUI unchanged.
- A chord prefix in Claude Code (`ctrl+x ctrl+k` and friends) reserves the bare
  key. Reservation is documented as per-context; the agent view is not a
  documented context, so behaviour there is unverified.
- tmux `extended-keys on` with `csi-u` (`tmux.conf` → `extended-keys`) is required for
  Ghostty and Kitty. It historically interacted badly with `option-as-alt`;
  test Alt bindings both inside and outside tmux after changing either.
- `KEYTIMEOUT` in zsh is an integer in hundredths of a second. A fractional
  value collapses to zero and silently breaks `jk`.

## Tooling

No tool currently covers this whole stack. `key-bee`
(github.com/mifwar/key-bee) parses skhd, tmux, nvim, Karabiner, zsh and
Hammerspoon together and reports cross-tool conflicts; Ghostty and AeroSpace
would need custom parsers. Worth revisiting if this document starts drifting
from reality.
