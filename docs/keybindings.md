# Keybindings across the stack

Read this before changing any keyboard shortcut in this repo. Keybindings are
spread across two repositories and a dozen files, stacked in layers where an
upper layer can silently swallow a key that a lower one needs. Most conflicts
are invisible until something you use daily stops working.

## The layers

Each layer sees a key first and can consume it. Nothing below ever learns the
key was pressed.

```text
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

## Hardware and layout

Context a reader needs before judging any Option-key decision. Ask the machine,
not the user.

| | Today | Planned |
|---|---|---|
| Layout | U.S. (`AppleCurrentKeyboardLayoutInputSourceID`) | German |
| Built-in keyboard | left and right Option | unchanged |
| External keyboard | **left Option only, no right** | German external, both |

Consequences that follow from this and keep coming up:

- **Umlauts today** are composed, not typed: `Option+u`, then `a`. The U.S.
  layout has no dedicated `ä ö ü`.
- **The missing right Option** on the external keyboard is supplied by the
  Karabiner homerow mod: holding `l` emits `right_option`, holding `s` emits
  `left_option`. That is why the homerow rules must stay active in Ghostty.
- **After the German switch**, umlauts get their own keys and this whole problem
  disappears. What replaces it: `{ } [ ] @ | ~` all need Option there, which is
  why the left Option must keep composing and Alt lives on the right.

Check the current layout with:

```bash
defaults read ~/Library/Preferences/com.apple.HIToolbox.plist \
  AppleCurrentKeyboardLayoutInputSourceID
```

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
| `.config/wezterm/wezterm.lua` | wezterm — holds a commented-out `keys` block, no active bindings |
| `~/.claude/keybindings.json` | Claude Code — **lives in the `claude-config` repo** |

`.config/yazi/` carries no custom keymap today and runs on yazi's defaults; it
still belongs on the checklist because a `keymap.toml` added later would not
announce itself.

This document covers how the layers interact, not what every key does. For the
full tmux binding list see [docs/tmux.md](tmux.md) and
[tmux/cheatsheet.md](../tmux/cheatsheet.md); this file only records the tmux
bindings that collide with something else.

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

## Settled decisions — do not re-litigate

Investigated, decided, and closed on 2026-07-22. Each was a real question with a
plausible case for the other answer. Re-open only with new evidence, and do not
put these to the user again as open choices.

**Karabiner homerow mods stay untouched, including inside Ghostty.**
They were the prime suspect at first: holding a homerow key past 180 ms turns it
into a modifier, so hold-to-repeat cannot work. But they have been active for
years, which means holding `j` never worked in Ghostty — a thing that never
worked cannot explain a key that stopped working. Navigation runs through
flash.nvim, hold-to-scroll is not part of the workflow. Independently, `l` must
keep emitting `right_option` because it supplies Alt on the external keyboard.

**No umlaut keybinding in Ghostty.**
Ghostty has a `text:` action, so `keybind = <combo>=text:ä` is possible. Rejected:
it would work only in Ghostty, not in Slack, Mail or the browser, and the problem
is temporary — it disappears with the German keyboard. The homerow route works
everywhere and costs nothing to maintain.

**`macos-option-as-alt = right`, not the alternatives.**
`true` would break every `{ } [ ] @ | ~` on a German layout, which is unusable
for development. `false` is the old state and yields no Alt at all. `left` would
put Alt on exactly the Option key that types those characters on a German
layout. `right` keeps the frequently-used side composing and dedicates the
rarely-used side to Alt. Note that measurement shows both sides yielding Alt in
practice — see the note above — so `left` and `right` may be indistinguishable
here; the choice is documented for the German future, not for today's behaviour.

**tmux `forward_programs` is not extended to the AI TUIs.**
Adding `claude` and `opencode` would deliver `Ctrl+H/J/K/L` to them but kill pane
navigation in exactly the panes used most, because unlike nvim they cannot hand
the key back to tmux. The gain is small: `Ctrl+H` is unbound in both, opencode
has `Shift+Enter`, `Ctrl+Enter` and `Alt+Enter` for newline. The only real loss
is Claude Code's `Ctrl+J`; if that ever matters, rebind it in
`claude-config/keybindings.json` rather than widening the forward list.

**The tmux prefix stays `Ctrl+S`.**
It frees `Ctrl+B` for Claude Code's `task:background`. It costs `chat:stash`,
which is why that moved to `Alt+S`. Changing the prefix is a separate decision
with its own retraining cost and was deliberately not bundled here.

**No enforcement hook for this document.**
A `PreToolUse` hook on the keybinding files would be more reliable than the
pointer in `CLAUDE.md`, but it adds a moving part. Chosen consciously; it remains
the obvious upgrade if the pointer turns out to be overlooked in practice.

## Where each program's defaults come from

Look these up rather than reasoning from memory — several of today's wrong turns
came from assuming a default instead of reading it.

| Program | How to get its defaults |
|---|---|
| Ghostty | `ghostty +list-keybinds --default`, `ghostty +list-actions`, `ghostty +show-config --default --docs` |
| tmux | `tmux list-keys`, `tmux list-keys -T copy-mode-vi` |
| zsh | `bindkey -L`, plus `bindkey -L -M viins` / `-M vicmd` / `-M menuselect` |
| nvim | `:map`, `:verbose map <key>` to find the source; LazyVim defaults live in `lua/lazyvim/config/keymaps.lua` |
| Claude Code | `code.claude.com/docs/en/keybindings` for the action table, `.../agent-view` for the session list (its keys are documented nowhere else), `/keybindings` in-app |
| opencode | `packages/tui/src/config/keybind.ts` in the repo — the authoritative source, more complete than `opencode.ai/docs/keybinds` |
| lazygit | `?` in-app; customCommands in `.config/lazygit/config.yml` |
| Karabiner | parse the selected profile out of `karabiner.json`; the GUI hides thresholds |

Version matters for the terminal itself: `ghostty --version`. Behaviour around
`option-as-alt` and `extended-keys` has changed between releases.

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
  value collapses to zero and silently breaks `jk`. It also gates every key that
  starts a multi-character binding: with `jk` bound, a trailing `j` is held back
  for the whole timeout, so large values feel laggy. `20` is the current value.
- "Terminal takes Cmd, TUIs keep Ctrl" is a widely used heuristic, **not a
  standard**. Every dotfiles repo surveyed picks a different split, and none
  cites a canonical source. Ghostty's own macOS defaults do follow it, which is
  the practical argument for adopting it here.
- The tmux prefix question has no settled answer either: `Ctrl+A` collides with
  readline, `Ctrl+Space` breaks nested-session prefix forwarding, `Ctrl+S` is
  nominally flow control. Every choice trades something.

## Tooling — checked, nothing fits yet

No tool found covers this stack, and the two that come closest do something
other than what the name suggests. Recorded so the search is not repeated.

| Tool | What it actually does | Why it does not solve this |
|---|---|---|
| `mifwar/key-bee` | TUI to **browse and search** keybindings across skhd, tmux, nvim, Karabiner, zsh, Hammerspoon | Conflict detection is not among the advertised features — an earlier claim here that it "reports conflicts" was wrong and is retracted. Ghostty and AeroSpace, the two layers that caused the July 2026 breakage, are unsupported. |
| `adames/rune` | Generates one cheatsheet for the whole machine from the real configs — "which-key, but cross-tool" (`rune-cheatsheet` on PyPI) | Closest to what the deleted Hammerspoon overlay tried to be, and generated rather than hand-maintained. Still a viewer, not a conflict detector. Ghostty support unverified. |
| `hoornet/keybind-audit` | Detects shortcut conflicts across applications | Linux-oriented; not evaluated for this macOS stack. |

The thing that actually solved the July 2026 problem was not a tool but a
question — *did it ever work?* — followed by `git log -S` on the config file.
That costs nothing and needs no maintenance.

If the cheatsheet the overlay used to provide is missed, `rune` is the candidate
worth evaluating. Do not adopt anything here expecting collision warnings.
