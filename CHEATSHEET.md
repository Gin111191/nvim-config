# Cheatsheet

Leader = **`Space`**. `Space + e` means press `Space`, then press `e`.

> **Forgotten a key?** Press `Space` and **wait 300ms** — `which-key` shows a panel of every key
> that could come next. Or `Space + s + k` to search the whole list of bindings.
>
> Shell keys (fzf, rg, vi-mode) are in `~/.config/zsh/CHEATSHEET.md`, tmux keys in
> `~/.local/share/tmux-config/CHEATSHEET.md`.

---

## Three ideas to get straight first

```
  BUFFER   =  the contents of a file, held in memory   →  a sheet of paper
  WINDOW   =  a box you LOOK INTO a buffer through     →  a window frame
  TAB      =  one arrangement of windows               →  how the frames are laid out
```

Opening 10 files = **10 buffers**, but the screen shows only 1. The other nine are still in memory.
`:q` closes a **window**, it does not throw the buffer away. To throw a buffer away, use `Space + x`.

The strip of tabs along the top (`bufferline`) exists to **show** the buffer list that Vim otherwise hides.

⚠️ **Those boxes are buffers, not tabs** — `mode = 'buffers'` in `lua/plugins/bufferline.lua:10`.
Real tab pages are not drawn up there at all (`show_tab_indicators = false`, line 33), so opening a
tab changes nothing you can see. `:tabs` is the only way to find out how many you have.

---

## Files & searching — Telescope

| Key | What it does |
|---|---|
| **`Space + s + f`** | **Find a file** by name (Telescope) |
| `Space + s + a` | Same as above, but **including** what `.gitignore` hides (`node_modules`, `.git`...) — still Telescope |
| `Space + s + i` | Find a file — **snacks.picker, not Telescope**, same no-ignore/no-hidden-filter reach as `sa`. An experiment to compare against `sf`/`sa`; `telescope.lua` has the note |
| **`Space + s + g`** | **Find text** across the whole project (grep) |
| `Space + s + w` | Search for the word under the cursor |
| `Space + Space` | List the open buffers |
| `Space + s + .` | Recently opened files |
| `Space + s + d` | List the errors/warnings |
| `Space + s + h` | Search the Neovim documentation |
| `Space + s + k` | **Search the list of key bindings** |
| `Space + s + r` | Reopen the previous search |
| `Space + s + s` | List every Telescope command |
| `Space + /` | Fuzzy-search **inside the current file** |
| `Space + s + /` | Grep, but only **in the files already open** |
| `Space + s + m` | **Find an image/video**, previewed as you move (snacks.picker — `image.lua`). Moved here from `Space + s + i`, freed up for the snacks file-picker experiment above |

### Inside a Telescope window

It opens in Insert mode, ready for typing. `Esc` once drops to Normal mode, where `j`/`k` move;
`Esc` again closes.

| Key | What it does |
|---|---|
| `Ctrl+n` / `Ctrl+p` **or** `Ctrl+j` / `Ctrl+k` | Down / up the results |
| `Enter` **or** `Ctrl+l` | Open |
| `Ctrl+x` / `Ctrl+v` / `Ctrl+t` | Open in a horizontal split / a vertical split / a new tab |
| `Ctrl+u` / `Ctrl+d` | Scroll the preview up / down |
| `Tab` / `Shift+Tab` | Mark several results |
| `Ctrl+q` | Send every result to the quickfix list (`Alt+q`: only the marked ones) |
| `Ctrl+/` (Insert) · `?` (Normal) | Show every key this picker knows |
| `Ctrl+c` | Close |

`Ctrl+j/k/l` are this config's addition (`telescope.lua:53-57`) — the same h/j/k/l fingers as
everywhere else. Telescope's own `Ctrl+k` (scroll the preview sideways) is gone as a result.

### Seeing where a match sits, and jumping to it

While still inside Telescope (before pressing anything else), moving `Ctrl+j`/`Ctrl+k` through the
results already scrolls the preview pane to each match in turn — no need to open the file first.
Two things are highlighted there, both colours tuned in `colortheme.lua` so they actually stand out
against Dusk-Navy (the stock colours were close to invisible):

| Highlight group | Marks |
|---|---|
| `TelescopePreviewLine` | The whole matched **line** |
| `TelescopePreviewMatch` | The exact matched **text**, in the palette's search-highlight colour (`base0A`) |

`Ctrl+q` (table above) sends every result into the quickfix list and opens it — one row per match,
so a file with 3 hits gets 3 rows. From there, step through them without leaving the buffer:

| Key | What it does |
|---|---|
| `]q` / `[q` | Jump to the next / previous match — **this config's addition** (`keymaps.lua`) |
| `:copen` / `:cclose` | Reopen / close the quickfix list window |
| `:cc N` | Jump straight to match number `N` |

The query box understands fzf syntax, from `telescope-fzf-native`:

| Type | Matches |
|---|---|
| `abc` | fuzzy — `a`, `b`, `c` in that order, gaps allowed |
| `'abc` | exactly `abc`, somewhere |
| `^abc` / `abc$` | starts with / ends with `abc` — `.html$` keeps only HTML files |
| `!abc` | does **not** contain `abc` |

### Where does it search?

**Neither "this folder" nor "everywhere" — it searches Neovim's working directory**, the folder you
were standing in when you typed `nvim`. It does **not** move when you open a file somewhere else.

```
cd ~/my-project && nvim   →  Space + s + f searches the whole project   ✅
nvim   (from your home)   →  it tries to search all of ~                ⚠️ slow
```

| Command | What it does |
|---|---|
| **`:pwd`** | **Show where the search will start** — the live answer, never a guess |
| `:cd path` | Move it, for every window |
| `:lcd path` | Move it, for this window only |

What it skips (`lua/plugins/telescope.lua:60-71`): anything in `.gitignore` — Telescope shells out to
`fd` and `rg`, and both obey it — plus every path containing `node_modules`, `.git` or `.venv`.

⚠️ Those three are Lua patterns matched **anywhere in the path**, so `%.git` also hides `.github/`,
`.gitignore` and `.gitattributes`.

⚠️ `hidden = true` is set, so dotfiles **are** listed — a `.env` that `.gitignore` does not cover
will appear in the picker.

To reach what it skips:

| Command | Finds |
|---|---|
| **`Space + s + a`** | Same as `find_files`, but **including** what `.gitignore` hides — the everyday shortcut for the row below |
| `:Telescope find_files no_ignore=true` | Files `.gitignore` hides, such as a `.env` |
| `:Telescope find_files cwd=node_modules` | Files inside `node_modules` — paths are then relative to it, so the pattern no longer matches |
| `:Telescope live_grep cwd=node_modules` | Text inside `node_modules`, the same way |

⚠️ Pressing `.` in Neo-tree sets the **tree's** root. Do not assume that moved Telescope with it —
type `:pwd` and read the answer.

## File tree — Neo-tree

| Key | What it does |
|---|---|
| **`Space + e`** | Toggle the file tree |
| `\` | Open the tree and jump to the current file |
| `Space + n + g + s` | A floating window showing git status |

While inside the tree:

| Key | What it does |
|---|---|
| `a` / `A` | Add a file / add a directory |
| `d` `r` `c` `m` | Delete / rename / copy / move |
| `y` `x` `p` | Copy / cut / paste |
| `S` / `s` | Open in a horizontal / vertical split |
| `t` | Open in a new tab |
| `w` | Choose which window to open into |
| `P` | Preview, without leaving the tree |
| `H` | Show/hide hidden files |
| **`/`** | **Type to filter live** — `Ctrl+n`/`Ctrl+p` or ↑↓ move, `Enter` opens, `Esc` cancels |
| `#` | The same, fuzzy-sorted — `bmed` finds `bom-editor` |
| `D` | Filter **directories** only |
| `f` | Type, press `Enter`, and the filter **sticks** — the tree stays narrowed |
| **`Ctrl + x`** | **Clear a stuck filter** — the way back out of `f` |
| `[g` / `]g` | Jump to the previous / next **git-modified** file |
| `z` | Collapse every branch |
| `?` | Show all of neo-tree's keys |

⚠️ **In the tree, `/` filters — it does not search.** In the editor `/` finds a match and `n` jumps
to the next one. In the tree it *hides* everything that does not match, so there is nothing to jump
between and `n` / `N` do nothing.

**To jump to the file you are editing: `\` (backslash)** — it runs `:Neotree reveal`
(`neotree.lua:308`), opening the folders and putting the cursor on your file. You have to press it
because `follow_current_file.enabled = false` (`neotree.lua:218`); set that to `true` and the tree
follows you by itself.

For *finding* a file, `Space + s + f` beats the tree — type part of the name, press `Enter`. The
tree is better for seeing where things sit, and for `a` `d` `r` `m` on files.

---

## Buffers, windows, tabs

| Key | What it does |
|---|---|
| **`Tab`** / **`Shift+Tab`** | Next / previous buffer |
| **`Space + x`** | **Close the buffer, keep the windows** — ⚠️ runs `:Bdelete!` (vim-bbye), unsaved changes are lost |
| `Space + b` | A new empty buffer |
| `Space + \|` | Split the window **vertically** (tmux: `Prefix + \|`) |
| `Space + -` | Split the window **horizontally** (tmux: `Prefix + -`) |
| **`Ctrl + h/j/k/l`** | **Jump between windows — and straight on into a tmux pane** |
| `Ctrl + \` | Back to the window you were just in (Neovim only — tmux does not bind it) |
| `Space + h/j/k/l` | Resize by **5** (tmux: `Prefix + h/j/k/l`) |
| `Ctrl + ←/↓/↑/→` | Resize by **1** — hold to repeat |
| `Ctrl+w` then `>` `<` `+` `-` | Resize by **2**; a count multiplies it (`3 Ctrl+w >` = 6) |
| `Space + s + e` | Make the windows equal in size |
| `Space + x + s` | Close the current window |
| `Space + t + o` / `t + x` | Open / close a tab |
| `Space + t + n` / `t + p` | Next / previous tab |

> `Ctrl+h/j/k/l` are the keys **shared with tmux**, thanks to `vim-tmux-navigator`. Sitting in the
> leftmost nvim window and pressing `Ctrl+h` jumps straight into the tmux pane beside it — one set
> of keys for both, with no need to know where you are.
>
> **Inside a terminal buffer** (`:terminal`) the same four keys also work in one press —
> `lua/core/keymaps.lua` maps them in terminal-mode, so there they no longer reach the program
> inside. `Ctrl + ]` leaves terminal-mode for normal mode in one chord (instead of `Ctrl+\`
> `Ctrl+n`; a bare `Ctrl+\` is taken — it starts that very chord, and vim-tmux-navigator binds it
> in normal mode). Claude is not one of these terminals: it runs in a tmux popup, not in Neovim,
> so there `Ctrl+h/j/k/l` stay Claude's own (`Ctrl+j` = new line, `Ctrl+k` = delete to end of line).
>
> Both sides are needed: the plugin on the nvim side (already here) **and** the "Seamless navigation
> with Neovim" section in [tmux-config](https://github.com/Gin111191/tmux-config). Without the tmux
> half it only works one way.

### The keys shared with tmux

| Action | Neovim | tmux |
|---|---|---|
| Move between boxes | `Ctrl + h/j/k/l` | `Ctrl + h/j/k/l` — **the same keys** |
| Split vertically | `Space + \|` | `Prefix + \|` |
| Split horizontally | `Space + -` | `Prefix + -` |
| Resize by 5 | `Space + h/j/k/l` | `Prefix + h/j/k/l` |
| Resize by 1 | `Ctrl + arrow` | `Prefix + Ctrl + arrow` ⚠️ |

⚠️ One place where the **letters match but the meaning does not**: `Space + x` in nvim closes a
**buffer**, while `Prefix + x` in tmux closes a **pane**.

⚠️ The 1-cell resize is the one key that cannot match. Neovim uses a **bare** `Ctrl+arrow`; if tmux
bound the bare key it would swallow it and Neovim would never see it, so tmux keeps its prefix there.

**Nothing to resize?** A window can only take space from a neighbour. With a single full-screen
window every resize key does nothing and says nothing — open a split first.

---

## Buffers & tabs — the rest of the keys

The four keys in the table above cover the daily work. These are the ones worth adding when that
starts to feel slow.

### Buffers — stock Vim, nothing installed

| Key / command | What it does |
|---|---|
| **`Ctrl + ^`** | **Back to the buffer you were just in** — press again to return |
| `:b part-of-name` | Jump to a buffer by any part of its name (`Tab` completes it) |
| `:ls` | Print the buffer list, with each buffer's number |
| `:b 3` | Jump to buffer number 3 |
| `:bd` | Close the buffer, but **stop and warn** if it has unsaved changes |

Almost all real work is bouncing between two files. `Ctrl + ^` does that in one key — pressing `Tab`
nine times to get back where you were is wasted motion. It is the one to learn first.

⚠️ **`Space + x` is `:Bdelete!`, with the bang.** The bang means *do it anyway*: unsaved changes go
in the bin, no question asked. `:Bdelete` is the same thing without the bang — it stops and warns you.

Capital **B** is vim-bbye's command, the same one the bufferline `✗` uses: the buffer goes but every
window showing it stays, switching to another buffer, so splits keep their layout. The built-in
lowercase `:bd` closes *every* window that shows the buffer and collapses the splits around it —
that is why `Space + x` used to rearrange the panels.

### Buffers — bufferline's own commands

Installed, but no key is bound to any of them.

| Command | What it does |
|---|---|
| `:BufferLinePick` | Draws a letter on each box in the top strip — press that letter to jump there |
| `:BufferLineCloseOthers` | Close every buffer except this one |
| `:BufferLineMoveNext` / `MovePrev` | Shift the current box left / right, to reorder the strip |
| `:BufferLineTogglePin` | Pin a buffer so it stays at the front |

### Tabs — stock Vim

Shorter than the `Space + t` keys above, and they take a number.

| Key | What it does |
|---|---|
| **`gt`** / **`gT`** | Next / previous tab — two keys, no leader |
| **`2gt`** | Jump straight to **tab 2**; any number works |
| `g<Tab>` | Back to the tab you were just in |
| `:tabs` | **List the tab pages that actually exist** |
| `:tabfirst` / `:tablast` | First / last tab |

---

## Writing code — LSP

Only active when the open file has a language server (Mason already installs them for lua, ts/js, json, css, html, python, sql, yaml, docker, terraform, tailwind).

| Key | What it does |
|---|---|
| **`K`** | **Show the description** of the function/variable under the cursor |
| **`gd`** | **Jump to the definition** (`Ctrl+o` to come back) |
| `gr` | Show every place it is used |
| `gI` | Jump to the implementation |
| `gD` | Jump to the declaration |
| `Space + D` | Jump to the type definition |
| **`Space + c + a`** | **Fix it automatically** (code action) — also how you **add a missing import**, see below |
| **`Space + r + n`** | **Rename** a variable/function everywhere |
| `Space + d + s` | List the symbols in this file |
| `Space + w + s` | Search symbols across the project |
| `[d` / `]d` | Previous / next problem |
| `Space + d` | Show the problem at the cursor in full |
| `Space + q` | Open the list of every problem |
| `Space + t + h` | Toggle inlay hints (types written inline), when the server offers them |
| `Ctrl + s` in Insert mode | Show the parameters of the function being typed |

Neovim's own LSP keys work too: `grn` rename · `gra` code action · `grr` references ·
`gri` implementation · `grt` type definition · `gO` symbols in this file.

⚠️ `gr` fires after a **300ms pause**: Neovim's `grr` `grn` … also begin with `gr`, so it waits to
see whether another key follows. Type `grr` for the same list with no pause.

### Adding a missing import (`useState`, `Link`, …) — ts/js/tsx

Two routes, both handled by `ts_ls`:

| Situation | Do |
|---|---|
| Still typing the name | Pick it from the completion menu (its detail says the module, e.g. `react`) and press **`Ctrl + y`** — the `import` line is inserted for you |
| Name already typed, menu gone | **`Space + c + a`** with the cursor **on the name**, choose **`Add import from "…"`** |
| Same, but wanting the menu back | Insert mode, cursor at the end of the word, **`Ctrl + Space`**, then `Ctrl + y` |

`Add import` is missing from the `Space + c + a` list when:

- **The red `Cannot find name '…'` error has not appeared yet.** ts_ls reports it a few seconds after
  opening or editing the file, and the import action is offered *for that error*. Before it shows up
  the list holds only refactors (`Extract function`, `Convert to template string`, …).
- **The cursor is not on the name** — at the end of the line or after a space, no error is under it.
- It is further down a long list: look through all of it, it sits with the quick fixes.

Nothing to check on the config side: `ts_ls` is enabled in `lua/plugins/lsp.lua` and both routes
were verified against it. `:LspInfo` shows whether `ts_ls` is attached to the current file.

## Completion

| Key | What it does |
|---|---|
| `Ctrl + n` / `Ctrl + p` | Down / up the suggestion list |
| **`Ctrl + y`** | **Accept** the highlighted suggestion |
| `Tab` / `Shift + Tab` | Down / up the list — or, with no list open, next / previous slot in a snippet |
| `Ctrl + Space` | Ask for suggestions by hand |
| `Ctrl + e` | Close the suggestion panel |
| `Ctrl + b` / `Ctrl + f` | Scroll the documentation shown beside the list |
| `Ctrl + l` / `Ctrl + h` | Next / previous slot in a snippet |

⚠️ **`Enter` does not accept** — it starts a new line. The `<CR>` mapping is commented out in
`lua/plugins/autocompletion.lua:99`; uncomment it to make `Enter` accept.

## Git

| Key / command | What it does |
|---|---|
| `:Git` | The git status panel — its keys are below |
| `:Git commit` / `:Git push` | Commit / push |
| `:Git blame` | Who last changed each line — `g?` for its keys, `gq` to close |
| `:Gdiffsplit` | Compare against the committed version |
| `:GBrowse` | Open this file on GitHub (vim-rhubarb) |
| `Space + n + g + s` | Git status as a floating window (Neo-tree) — its keys are below |

**Inside `:Git`** (fugitive), on a file line:

| Key | What it does |
|---|---|
| `s` / `u` / `-` | Stage / unstage / toggle between the two |
| `=` | Show the diff inline, right under the file name |
| `dv` | Open the diff in a vertical split |
| `X` | ⚠️ Throw the change away |
| `cc` / `ca` | Commit / amend the last commit |
| `o` | Open the file in a split |
| `g?` | Every key |

**Inside `Space + n + g + s`** (Neo-tree): `ga` stage · `gu` unstage · `A` stage everything ·
`gc` commit · `gp` push · `gg` commit and push · `gr` ⚠️ revert the file · `q` close.

The left column shows the marks by itself: `+` added, `~` changed, `_` deleted. That is gitsigns;
no key is bound to it, but its commands are useful:

| Command | What it does |
|---|---|
| `:Gitsigns preview_hunk` | Show what changed in the block under the cursor |
| `:Gitsigns nav_hunk next` / `prev` | Jump to the next / previous changed block |
| `:Gitsigns stage_hunk` / `reset_hunk` | Stage just that block / ⚠️ throw it away |
| `:Gitsigns blame_line` | Who changed this line, and in which commit |
| `:Gitsigns toggle_current_line_blame` | Keep that blame showing at the end of the line |
| `:Gitsigns diffthis` | Diff this file against the index, side by side |

---

## AI — Claude in a tmux popup (`lua/core/claude-popup.lua`)

> Why it is built this way, what broke along the way and how to check things when it misbehaves:
> `docs/claude-popup-notes.md`.

Claude is a **plain `claude` in a tmux pane**, shown in a **90% tmux popup** over Neovim. Inside the
popup it is an ordinary terminal: every Claude key works, `Ctrl+b` reaches tmux, scrolling back is
tmux's own. Hiding the popup never stops Claude. Needs Neovim running inside tmux (otherwise the
keys only say so). Claude edits files itself and asks for permission in its own prompt — review the
result with `Space g d` (next section).

```
tmux session (the one you work in)
 1:nvim   2:…   3:·claude:job-application-tracker#1   4:·claude:portfolio#1
   │                    ▲                                   ▲
   └─ Space a c ────────┘ shown in a popup over Neovim      └─ another project's Claude
```

Each Claude lives in a **window of its own** in your session, named `·claude:<project>#<n>` — the
"stash window". You see them in the status bar and in `Prefix + w`; `Shift + ←/→` skips them
(tmux-config's `claude-window.sh`; `Prefix + S` toggles that), `Prefix + n/p` and `Alt + <n>` do not. Inside it, Claude runs in your
shell: `/exit` drops you to the shell prompt (in the same popup), where any `claude …` command works.

### Keys in Neovim

| Key | What it does |
|---|---|
| **`Space + a + c`** | **Open the Claude in use** for this project in the popup — starts one if there is none |
| **`Shift + ↑`** | The same from anywhere in the window (a tmux key, tmux-config): opens the float this window had |
| `Space + a + s` | **List every Claude of this project** and pick one, or start a new one (below) |
| `Space + a + t` | Send this **line** as `@file#L42` (visual: these **lines**, `@file#L10-20`) |
| `Space + a + f` | Send this **file** as `@file` |
| `Space + a + v` (visual) | Send the selected **text** itself |

**Sending** (`t` / `f` / `v`) pastes into Claude's input **without pressing Enter**, then opens that
Claude's popup so you can add your question and send it. Details:

- It goes to **the Claude in use** for this project in this tmux window — the last one you opened
  with `Space a c` / `Space a s` — never to another project's.
- `t` and `f` **save the file first**: Claude reads `@file` from disk, so unsaved edits would be
  missed. `v` sends the text, so it does not need to.
- Paths are relative to that Claude's own folder (one started in `app/` gets `@page.tsx`).
- A multi-line selection arrives as one paste — no line is sent on its own.
- If that Claude has exited to its shell, nothing is sent: "No Claude running for this project".

### Inside the popup (it is tmux, not Neovim)

| Key | What it does |
|---|---|
| **`Shift + ↓`** (or `Ctrl + b` then `d`) | **Close the float** — Claude keeps running in its window |
| `Ctrl + b` then `[` | Scroll back (tmux copy mode; `q` to leave) |
| `Shift + ←` / `Shift + →` | Go to the previous / next window; the float follows (below) |
| `/exit` (in Claude) | Quit Claude → you are at a shell prompt, still in the popup |
| `claude --resume` / `claude -c` / `claude --model …` (at that prompt) | Start Claude again any way you like |
| `exit` (at that prompt) | Close the shell → the window and the popup close for good |
| `/resume`, `/model` (in Claude) | Switch conversation / model without leaving Claude |

### Each window keeps its own float

A tmux popup belongs to the terminal, not to a window, so each working window **records its own
float** (window options `@claude_float`, `@claude_float_pane`) and the keys keep the popup in step
with the window on screen (tmux-config's `claude-window.sh`):

```
window A: float OPEN (Claude A)      window B: float CLOSED      window C: float OPEN (Claude C)
   Shift+→  ─►  B: the float closes
   Shift+→  ─►  C: the float opens again, showing Claude C
   Shift+←  ─►  B: closes  ·  Shift+← ─► A: opens, showing Claude A
```

| Key | What it does |
|---|---|
| `Shift + ↑` | Open this window's float. None recorded yet: Neovim in the window does `Space a c` |
| `Shift + ↓` / `Ctrl+b d` | Close it, and record it closed — Shift+←/→ will not bring it back |
| `Shift + ←/→` | Move; the float of the window you arrive at opens if it was left open |
| `Prefix + S` | Toggle whether `Shift + ←/→` also stops at the `·claude:…` windows (whole tmux, starts at "skip") |

A window whose Claude has quit counts as closed. `Prefix + n/p` and `Alt + <n>` switch windows
without touching the float. With the `·claude:…` windows included, landing on one shows that Claude
full-window — it is a Claude window, so no float opens over it — and the floats of your working
windows follow them exactly as before.

### `Space a s` — the list

Every **interactive** Claude running in tmux whose folder is the one Neovim has open, or below it
(`app/`, a worktree inside the project…), from any window or session — including ones you started
by hand. `claude -p …` jobs in scripts are left out. Claude in a terminal outside tmux, on another
machine or in a folder outside the project is not seen. **Background sessions** of the project are
listed too (`☁`, from `claude agents --json`) — see below.

```
┌─ Claude · job-application-tracker ─────────────────────────────────┐
│ #1  ·claude:job-application-tracker#1  [claude]  · 6f02dad4  (in use) │
│ #2  ·claude:job-application-tracker#2  [shell]                        │  ← exited, at its shell
│ #3  ·claude:job-application-tracker#3  [claude]  · 6f02dad4  ⚠ same   │  ← same conversation as #1
│       conversation as #1                                              │
│ window "zsh" (%17) — becomes a ·claude window, opens here             │  ← you ran claude there
│ pane %23, split inside ·claude:…#1 — moves to its own window, …       │  ← you split a stash window
│ ↪ pane next to Neovim (%19) — jump to it                              │  ← left where it is
│ ↪ window "mywork" (%21) — jump to it                                  │  ← left where it is
│ ☁ background  "order-inventory…"  · 3101c4fc  [idle] — attach in a popup│  ← runs in the background
│ + New Claude                                                           │
│ + Continue the latest conversation — already open in #1, shows that one│
│ + Open a past conversation…                                            │
└────────────────────────────────────────────────────────────────────────┘
```

`+ Open a past conversation…` opens a second picker, in Neovim, with this project's conversations:

```
┌─ Past conversations · em.nhumay ────────────────────────────────────┐
│ 10-02 21:31  order-inventory-settlement-design  · 3101c4fc  ← open in #1 │
│ 10-02 20:33  Danh sách việc chờ  · bc1a6445                          │
│ 10-02 07:26  Máy ngủ  · b2fae992                                     │
│ …                                                                    │
└──────────────────────────────────────────────────────────────────────┘
```

Newest first, named by Claude's own title for them. Left out: near-empty placeholders, and older
ids Claude has continued under a newer one (only the newest of such a chain is listed). **Escape
starts nothing** — no window is made until you pick.

`· 6f02dad4` is the start of the **conversation** that Claude has open (Claude Code's session id).

| What you pick | What happens |
|---|---|
| `#n …` | Popup on it |
| A window of yours running only `claude` | It is renamed `·claude:<project>#<n>` and opens in the popup |
| A pane you split **inside a stash window** | It gets its own stash window, then opens in the popup (a popup shows a whole window) |
| A Claude **next to Neovim**, or in any other window of yours with several panes | **Nothing is moved** — the cursor jumps there |
| `+ New` | A new stash window running `claude` |
| `+ Open a past conversation…` → a conversation | One marked `← open in #n`: shows that window. Any other: a new stash window running `claude --resume <id>` |
| `☁ background …` | Only when the agents view is on (claude-config turns it off with `disableAgentView`). A new stash window running `claude attach <id>`, opened in the popup |
| `+ Continue the latest conversation` | A new stash window running `claude --continue` — **unless** that conversation is already open: in a Claude listed here (shows that one) or in a background session (attaches to it) |

Whatever you pick becomes **the Claude in use** for `Space a c` and the send keys.

**No background sessions.** claude-config sets `disableAgentView: true`, which turns off Claude
Code's agents view (`←` in the prompt, `claude agents`), `--bg`, `/background` and its daemon. So
every Claude is a plain process in a tmux pane — tmux keeps it alive when you close the popup,
quit Neovim or detach — and each conversation is open in exactly one place. With the agents view
on, it moved conversations into the daemon behind the popup's back: forked copies, a window titled
for one project showing another's conversation, `--resume` refusing "running elsewhere". Delete
that setting to have it back; the `☁` lines then list the project's background sessions.

**⚠ same conversation as #n** — two Claudes have **one** conversation open and both write to it,
so their messages interleave. It happens when `claude --continue` (or `--resume` of the same
conversation) is run while that conversation is already open elsewhere. Fix: in one of them,
`/exit`, then `claude` (a new conversation) — or open conversations through `Space a s` →
`+ Open a past conversation…`, which never opens one twice.

### Housekeeping

| Task | How |
|---|---|
| Quit one Claude for good | `/exit`, then `exit` at the shell — or `Prefix + &` in its window |
| See every Claude at once | `Prefix + w` (they are the `·claude:…` windows) |
| A popup that will not close | `Prefix + d` inside it; failing that, `tmux kill-session -t <claude-view-…>` from a shell |
| Leftover `claude-view-…` sessions in `tmux ls` | Harmless; cleaned up the next time a popup opens |

### What changed from claudecode.nvim

| Key | Before | Now |
|---|---|---|
| `Space + a + c` | Toggle the Claude split in Neovim | Popup on the Claude in use (hide it with `Ctrl+b d`) |
| `Space + a + s` | Send selection (visual) | List / start Claudes of this project; sending is `Space a t` / `v` |
| `Space + a + f` | Focus the Claude terminal | Send the current file |
| `Space + a + a/b/d/r/C/m` | Accept/deny diff, add buffer, resume, continue, model | **Gone** — `+ Continue` / `+ Open a past conversation…` in `Space a s`, `/model` in Claude |
| `/ide` in Claude | Connected to this Neovim | Nothing to connect to — no IDE server any more |

**Rolling back to claudecode.nvim** (this setup lives on branch `try-claude-popup` of nvim-config and
claude-config): `git checkout main` in `~/.local/share/nvim-config`, open Neovim, `:Lazy restore`
(puts claudecode.nvim back at its locked commit), `:Lazy clean` (drops codediff), restart. Same
`git checkout main` in `~/claude-config`, then copy `hooks/nvim-open.sh` to `~/.claude/hooks/` —
although the hook on this branch reads both registries, so it works either way.

---

## Reviewing what Claude changed — `esmuellert/codediff.nvim`

VSCode-style diffs in a tab of their own: changed files on the left, the diff on the right,
refreshing by itself while Claude keeps editing. Moving `j`/`k` in the file list opens each diff at
once (`auto_open_on_cursor`). It compares with `HEAD`, so **your own uncommitted edits show up too**
— stage them first (`-` / `S`) if you want "Changes" to be only what Claude did.

| Key | What it does |
|---|---|
| **`Space + g + d`** | **Every changed file** (working tree vs HEAD) |
| `Space + g + f` | This file vs HEAD |
| `Space + g + h` | History of this file — pick a commit to see its diff |
| `Space + g + H` | History of the whole repo |

**Inside the CodeDiff tab** (only there):

| Key | What it does |
|---|---|
| `j` / `k` (file list) | Move — and open that file's diff |
| `]c` / `[c` | Next / previous change |
| `]f` / `[f` | Next / previous file |
| `-` | Stage / unstage this file |
| `S` / `U` (file list) | Stage all / unstage all |
| `Space + h + s` / `h + u` | Stage / unstage the hunk under the cursor |
| `Space + h + r` | ⚠️ Throw the hunk away (working tree) |
| `X` (file list) | ⚠️ Throw away all changes to that file |
| `t` | Switch side-by-side ⇄ inline |
| `gc` | Fold unchanged code (compact) |
| `gf` | Open the file in your normal tab |
| `R` (file list) | Refresh |
| `g?` | Every key |
| `q` | Close the CodeDiff tab |

Inside that tab a few of your own keys are shadowed: `Space b` toggles the file list (not "new
buffer"), `Space e` focuses it (not Neo-tree), `t` is the layout toggle (not the `t` motion), and
`Space h` (resize) waits a moment because `Space h s/u/r` exist there. Everywhere else they are
unchanged.

### Reviewing a task, step by step

1. **Before handing over** — `Space g d`, `S` to stage what you were working on (or commit it),
   `q`. From now on "Changes" holds only what Claude does.
2. **Hand over** — `Space a c`, type the task, `Ctrl+b d` to hide the popup while Claude works.
3. **Review** — `Space g d`. The list refreshes while Claude keeps editing. `j`/`k` through the
   files, `]c`/`[c` through the changes.
4. **Decide, piece by piece**
   - Good: `Space h s` (this hunk) or `-` (whole file) — it moves to "Staged".
   - Bad: `Space h r` (this hunk) or `X` (whole file) to throw it away, then tell Claude why
     (`Space a c`).
5. **Done** — when "Changes" is empty, everything you accepted is staged: `q`, then commit.

---

## Editing text

| Key | What it does |
|---|---|
| `Ctrl + s` | Save |
| `Space + s + n` | Save **without** running the auto-format |
| `Ctrl + q` | Quit |
| `gcc` | Comment / uncomment the current line |
| `gc` (visual) | Comment / uncomment the selection |
| `Ctrl + /` or `Ctrl + c` | The same toggle — on the line, or on the selection in Visual mode |
| `gc` + a motion | Comment a stretch: `gcip` the paragraph, `gc2j` this line and the next two |
| `Ctrl+d` / `Ctrl+u` | Scroll half a page, **re-centring automatically** |
| `n` / `N` | Next match, **re-centring automatically** |
| `x` | Delete 1 character, **without overwriting the clipboard** |
| `d` `c` `D` `C` | Delete / change **without copying** — only an explicit `y` touches the clipboard |
| **`X`** + a motion | **Cut** = yank + delete in one go, into the system clipboard: `Xw` a word, `Xd` a line, `Xip` a paragraph |
| `XX` | Cut the whole current line |
| `X` (visual) | Cut the selection |
| `)` | Go to the **end of the line**, same as `$` (also in Visual and after an operator: `y)`, `X)`). The sentence jump it used to be is gone |
| `<` `>` (visual) | Indent, **keeping the selection** |
| `p` (visual) | Paste **without losing what was copied** |
| `Space + w` | Toggle line wrapping |
| `[` + `Space` / `]` + `Space` | Add an empty line above / below, staying in Normal mode |
| `gx` | Open the URL or file path under the cursor |
| `Space + f + p` | Show the current file's full path |
| `Space + f + y` | Show the current file's full path **and copy it to the clipboard** |
| `u` / `Ctrl + r` | Undo / redo |

Yank `y` and paste `p` go through the **system clipboard** (`clipboard = 'unnamedplus'`,
`lua/core/options.lua:3`): copy in Neovim, paste in the browser, and the other way round.

### Reloading

| Command | What it does |
|---|---|
| `:e` | Re-read the file from disk — refuses if you have unsaved changes |
| **`:e!`** | **Re-read from disk, throwing away everything unsaved** |
| `:checktime` | Reload only if the file changed on disk underneath you |
| `:source %` | Re-apply the config file you are looking at, without restarting |

**Files changed behind Neovim's back** (Claude, a formatter, git) reload by
themselves within about a second — a 1 s timer plus `FocusGained`/`CursorHold` run `:checktime`
(`lua/core/options.lua`), including while the Claude popup covers Neovim. What you see
is set by `:ChangeMode` (`lua/core/external-change.lua`):

| Mode | What it looks like |
|---|---|
| **`highlight`** (default) | One column: new/changed lines get a green background and a `▎` sign, removed or replaced lines show above as red `- old text` virtual lines. Stays until you save, the file changes again, or `:ChangeClear`. |
| `split` | Side-by-side diff in the window showing the file: **BEFORE (read-only) left, the real file right**. At most `vim.g.external_change_max_splits` (default 1) at once; a newer one closes the oldest, so many edited files never fill the screen with columns. |

`:ChangeMode split` / `:ChangeMode highlight` switches (and clears what is showing); `:ChangeClear`
removes highlights and closes the diff splits. In both modes any window showing the file, other
than the one you are in, scrolls to the first change. Only buffers loaded before the change are
tracked; a manual `:e!` can leave a stale "before" that shows a few extra lines on the next change.

**Claude opens and shows files by itself.** `~/.claude/hooks/nvim-open.sh` (repo `claude-config`)
is wired to `PreToolUse`/`PostToolUse` on Edit/Write: it opens the file in the Neovim whose
workspace contains it — in a code window, never a terminal, without moving your focus —
*before* the edit (so Neovim has the old text to diff against) and re-reads it right after. Claude
runs `nvim-open.sh open <path>[:line]` when you ask to see a file. It finds Neovim through
`~/.cache/nvim-claude/<pid>.json`, which every Neovim writes at startup (`lua/core/nvim-registry.lua`)
with its working folder — so start Neovim in the project folder (or a parent of it). Works for any
Claude on this machine, in the popup or in a plain tmux pane; with no matching Neovim it silently
does nothing. While the popup covers Neovim you see the highlights once you hide it (`Ctrl+b d`).

**Buffers Claude opened are closed when it finishes a reply** (the `Stop` hook runs
`nvim-open.sh done` → `close_opened()`). Only buffers the hook itself loaded are touched — one you
already had open, one with unsaved changes, and one you saved yourself are left alone — and the file
still showing in a window stays until the next run replaces it. Stale leftovers from before this
existed: `:bd <number>` (see `:ls`).

⚠️ `:source %` is honest only for plain options and keymaps. A plugin spec in `lua/plugins/` will
not fully re-apply that way — quit and reopen Neovim for those.

## Selecting a block — text objects

Stock Vim, no plugin. The pattern is always three keys: `v` + `i` or `a` + the bracket.

- `i` = **inner** — what is inside, brackets excluded
- `a` = **around** — includes the brackets themselves

| Keys | Selects |
|---|---|
| `vi{` or `vi}` | inside `{ … }` |
| `va{` | `{ … }` including the braces |
| `vi(` or `vib` | inside `( … )` |
| `vi[` | inside `[ … ]` |
| `vi<` | inside `< … >` |
| `vi"` `vi'` `` vi` `` | inside quotes |
| `vit` | inside an HTML/JSX tag |

**The cursor can be anywhere inside the block** — it does not have to be on the bracket. Vim
searches outward for you.

Swap `v` for any operator and it acts instead of selecting:

| Keys | Does |
|---|---|
| `di{` | delete everything inside the braces |
| `ci{` | delete inside and start typing |
| `yi{` | copy inside |
| `da(` | delete the parentheses and their contents |

`ci{` and `ci(` are the two you will use most.

**Two extras**

- `%` jumps between a bracket and its match. `V%` selects the whole block **linewise**, brackets
  included — the one for grabbing a whole function body.
- With a selection live, press `i{` again to expand outward to the next enclosing block. Repeat to
  keep widening.

Same idea beyond brackets: `viw` word · `vip` paragraph · `vis` sentence.

**By syntax rather than by bracket (Neovim 0.12):** `v` then `an` selects the syntax node under the
cursor; each further `an` grows it to the enclosing node — argument, call, statement, function — and
`in` shrinks it back. With a selection live, `]n` / `[n` move it to the next / previous node.

⚠️ `r` on a selection does **not** swap in a word — it stamps one character over every character
selected (`viw` then `rx` on "hello" gives "xxxxx"). Use `c` to replace a selection with new text.

---

## Surrounding — wrap, change, delete `{}` `[]` `()` and tags

Plugin `nvim-surround` (`lua/plugins/misc.lua`). The character you type after the command **is the
pair**: `(` `[` `{` `<` `"` `'` `` ` `` work the same way.

| Keys | What it does | Example |
|---|---|---|
| **`V` + move, then `S{`** | Wrap the selected **lines** in braces, each brace on its own line, body indented | 3 lines → `{` … `}` around them |
| `v` + select, then `S(` | Wrap a **partial** selection (braces stay inline) | `foo` → `( foo )` |
| **`ysiw)`** | Wrap the **word** under the cursor | `foo` → `(foo)` |
| `yss]` | Wrap the **whole line** | `a, b` → `[a, b]` |
| `ys$)` | Wrap from the cursor to the end of the line | |
| **`ysiwt`** then `div` `Enter` | Wrap in an HTML/JSX **tag** | `word` → `<div>word</div>` |
| `St` then `div` `Enter` | Same, on a Visual selection | |
| `Sf` then `console.log` `Enter` | Wrap as a **function call** | `x` → `console.log(x)` |
| **`cs)]`** | **Change** the surrounding pair: first key = what is there, second = what you want | `(foo)` → `[foo]` |
| `cs"'` | Change quotes | `"foo"` → `'foo'` |
| **`ds)`** | **Delete** the surrounding pair | `(foo)` → `foo` |

- **Opening vs closing character:** an opening one pads with spaces, a closing one does not.
  `ysiw{` gives `{ old }`, `ysiw}` gives `{old}`. `(` `[` behave the same; in JS/TS `S)` `S]` are usually what you want.
- Aliases for the closing forms: `b` = `)`, `B` = `}`, `r` = `]`, `a` = `>`. So `ysiwb` = `ysiw)`.
- The mnemonic: `ys` = *you surround* + a motion (`iw` word, `ip` paragraph, `$` to end of line, `s` = whole line);
  `cs` = change surround; `ds` = delete surround; `S` = the Visual-mode version.
- `V` (linewise) puts the braces on their own lines; plain `v` keeps them on the same line as the text.
- Checked in a headless run: `ysiw)`, `ysiw{`, `cs)]`, `ysiwt`, `V` + `S{` and `ds]` all behave as above.

---

## Folding — collapsing blocks of code

Folds come from **treesitter**, so a "block" is whatever the language says a block is: a function,
an `if`, a Lua table. In a `.md` file it is a `#` heading plus everything under it.

| Key | What it does |
|---|---|
| **`za`** | **Toggle the block the cursor sits in** — the one key worth memorising |
| `zo` / `zc` | Open it / close it, if you would rather not toggle |
| `zA` `zO` `zC` | The same three, but also every block nested inside |
| **`zR`** / **`zM`** | **Open every fold in the file** / close every fold |
| `zj` / `zk` | Jump to the next / previous fold |
| `zv` | Open just enough to show the line the cursor is on |

Files now open with every fold **expanded**: `lua/core/options.lua` sets `foldlevelstart = 99`.
Without it, `lua/plugins/treesitter.lua` switches folding on but never sets `foldlevel`, so
Neovim's default of `0` applies — level 0 means every fold closed. Want that behaviour back?
Delete the `foldlevelstart` line, or `:set foldlevel=0` for the current session only.

⚠️ **A paragraph cannot be folded.** The syntax tree has no such thing, so there is nothing there to
fold. To fold a chunk you choose by hand: run `:setlocal foldmethod=manual` first, then select the
lines and press `zf`. Skip that first step and `zf` fails with `E350` — `foldmethod=expr` refuses
folds made by hand.

⚠️ Text disappearing in a `.md` file is **not** folding — that is *conceal*, see
[Markdown](#markdown).

---

## Appearance

| Key | What it does |
|---|---|
| `Space + b + g` | Toggle the transparent background |
| `Space + t + t` | Show where Neovim is reading the theme from |
| `Space + t + i` | Toggle the **image hover float** for the current buffer (see below) |

### Image hover float — off by default

An image referenced inside a file (`<Image src="/x.png">` in tsx, `![](x.png)` in Markdown, `<img>`
in html, `url()` in css…) used to pop up in a float whenever the cursor crossed it, which covered
the code in `.tsx` files. It is now **off** (`doc.enabled = false` in `lua/plugins/image.lua`);
`Space + t + i` switches it on for **the buffer you are in**, and again to switch it off.
The float is sized to **80% of the Neovim window** (columns and lines, worked out again on every resize — `fit_doc` in
`lua/plugins/image.lua`): drag the tmux pane larger and the next float is larger. Change `0.8` there for another share.

- Per buffer, not global: turning it on in `page.tsx` does not touch other files.
- Opening an image file itself (`:e photo.png`, or a pick from `Space + s + m`) is unaffected —
  that fills the buffer and never used the float.
- To get the old always-on behaviour back, set `enabled = true` on the `doc` line.

---

## Colours — kept in step with WezTerm

Neovim's palette takes the **16 Dusk-Navy colours verbatim** from `wezterm.lua`:

| Part | Colour | Source |
|---|---|---|
| Background | `#1d2837` | `background` |
| Text | `#EDEEF7` | `foreground` |
| Comments | `#93a1b3` | `BRIGHT_BLACK.dark` |
| Strings | `#8fbfa9` | `brights[2]` |
| Function names | `#7d9bd4` | `brights[4]` |
| Keywords | `#a99ad4` | `brights[5]` |
| Selection | `#3d4a6b` | `selection_bg` |
| Current line (`CursorLine`) | `#2f3f5c` | **Not** from wezterm.lua — set in `colortheme.lua` |

The background is left **transparent** so WezTerm's gradient shows through.

The current-line highlight is the one colour that is deliberately **not** a palette slot. base16's
`base01` (`#26334a`) gave it only 1.17:1 contrast against the background, so it was near invisible;
`#2f3f5c` is 1.41:1, and still lighter than the Visual selection (`#3d4a6b`) so the two do not blur
together. Want it stronger? Raise the hex in the `CURSORLINE` table (`#334464` is 1.52:1, but is then
hard to tell from a Visual selection). `Space + b + g` re-runs the theme and keeps the change.

To change the colours: edit `DUSK_NAVY` in `lua/plugins/colortheme.lua` to match `CUSTOM_SCHEMES` in `wezterm.lua`.

---

## Markdown

Opening a `.md` file renders it in place: headings get an icon and a background, `**bold**`
`*italic*` `` `code` `` hide their markup, bullets become `●` `○`, checkboxes become `󰄱` `󰱒`,
tables are drawn with borders `┌─┬─┐`, and code blocks get a language label.

Pressing `i` to enter Insert mode drops back to raw Markdown for editing; leaving it renders again.

### Why text "disappears" — and how to get it back

This is **not folding**, it is *conceal*: the plugin hides the markdown markup and draws the result
in its place. `[Read the docs](https://exa.mple/very/long)` shows only `󰌷 Read the docs` — the URL is still
sitting in the file, it is just not displayed.

Ways to see the raw text again, from gentlest to strongest:

| To | Do |
|---|---|
| See **one line** raw | **Put the cursor on that line** — the line under the cursor is always shown raw |
| Hide it again | Move the cursor to another line |
| See **the area around the cursor** raw | `:RenderMarkdown expand` — each call opens up 1 more line above and below |
| Shrink that area | `:RenderMarkdown contract` — each call takes 1 line back, stopping at 0 |
| See **the whole file** raw | `:RenderMarkdown toggle`, or press `i` for Insert mode |

The mechanism behind it is `anti_conceal` with `above = 0`, `below = 0` — meaning only the line the
cursor is on drops its conceal. `expand`/`contract` add to and subtract from those two numbers
(`contract` stops at a floor of 0).

### Every command

| Command | What it does |
|---|---|
| `:RenderMarkdown toggle` | Toggle rendering for everything |
| `:RenderMarkdown expand` / `contract` | Widen / shrink the raw area around the cursor (±1 line per call) |
| `:RenderMarkdown enable` / `disable` | Turn it fully on / off |
| `:RenderMarkdown buf_toggle` | Toggle it for the current buffer only |
| `:RenderMarkdown preview` | Open a preview |
| `:RenderMarkdown config` | Print the config that differs from the default |

---

## Other plugins — what they do on their own

| Plugin | What you notice | Commands / keys |
|---|---|---|
| which-key | Press `Space` and wait — a panel lists every key that can follow | — |
| todo-comments | `TODO:` `FIXME:` `NOTE:` `HACK:` light up inside comments | `:TodoTelescope` search them all · `:TodoQuickFix` |
| nvim-autopairs | Typing `(` `[` `{` `"` adds the closing half | — |
| nvim-surround | Wrap / change / delete pairs and tags: `ysiw)`, `cs)]`, `ds)`, Visual `S{` — see [Surrounding](#surrounding--wrap-change-delete----and-tags) | — |
| nvim-ts-autotag | In html/jsx/tsx, typing `<div>` adds `</div>`; renaming the opening tag renames the closing one. Works only while typing in Insert mode, not on pasted text | — |
| nvim-colorizer | `#7d9bd4` is painted in its own colour (true-colour terminals only) | `:ColorizerToggle` |
| indent-blankline | Thin vertical lines mark each indent level | — |
| vim-sleuth | Indent width is read from the file itself | — |
| fidget | LSP progress messages in the bottom-right corner | — |
| none-ls | Formats on save — prettier (html/json/yaml/md), stylua, shfmt, ruff | `Space + s + n` saves without it |
| alpha | The start screen when `nvim` opens with no file | `e` new file · a number opens that recent file |

---

## Maintenance commands

| Command | What it does |
|---|---|
| `:Lazy` | The plugin manager panel |
| `:Lazy update` | Update the plugins (remember to commit `lazy-lock.json` afterwards) |
| `:Mason` | The LSP / formatter / linter manager panel |
| `:TSUpdate` | Update the treesitter parsers |
| `:TSInstallAll` | Reinstall every parser in the list, waiting until it is done |
| **`:checkhealth`** | **See what is still missing** — run it when something does not work |
| `:LspInfo` | Show which LSP is running for the current file |
| `:messages` | Read back the messages that have scrolled past |

⚠️ **Run `:Lazy update` in a Neovim you opened AFTER the last plugin was added to `lua/plugins/`.**
A session that started earlier does not know the new spec, so when it rewrites `lazy-lock.json` it
leaves that plugin's line out (`nvim-ts-autotag` was dropped this way). The plugin keeps working on
this machine, but it is then unpinned, and `:Lazy restore` on another machine will not install the
locked version. Check `git diff lazy-lock.json` before committing: a plugin line that vanished is the sign.

---

## When it breaks

| Symptom | The usual cause |
|---|---|
| `ENOENT ... (cmd): 'tree-sitter'` | No tree-sitter CLI. Run `:MasonInstall tree-sitter-cli`, then `:TSInstallAll` |
| `module 'nvim-treesitter.configs' not found` | Someone moved treesitter back to the `master` branch. This config uses `main`, which has no such module |
| `attempt to call method 'range' (a nil value)` when opening a `.md` | A sign the `master` branch is running on Neovim ≥ 0.11. Check for `branch = 'main'` in `treesitter.lua` |
| No syntax highlighting | The parser is not installed. `:TSInstallAll`, or `:checkhealth vim.treesitter` |
| The JavaScript LSPs will not install | No `node` / `npm` |
| Treesitter parsers will not compile | No `gcc` |
| `Too many rounds of missing plugins` | A plugin's build is failing over and over. Check `:Lazy` to see which |
| Icons show as empty boxes | The terminal is not using a Nerd Font |
| The colours look wrong | The terminal does not have true colour on |
