# Cheatsheet

Leader = **`Space`**. `Space + e` means press `Space`, then press `e`.

> **Forgotten a key?** Press `Space` and **wait 300ms** — `which-key` shows a panel of every key
> that could come next. Or `Space + s + k` to search the whole list of bindings.

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
| **`Space + s + f`** | **Find a file** by name |
| **`Space + s + g`** | **Find text** across the whole project (grep) |
| `Space + s + w` | Search for the word under the cursor |
| `Space + Space` | List the open buffers |
| `Space + s + .` | Recently opened files |
| `Space + s + d` | List the errors/warnings |
| `Space + s + h` | Search the Neovim documentation |
| `Space + s + k` | **Search the list of key bindings** |
| `Space + s + r` | Reopen the previous search |
| `Space + s + s` | List every Telescope command |

Inside a Telescope window: `Ctrl+n`/`Ctrl+p` move up and down, `Enter` opens, `Ctrl+v` opens in a vertical split, `Esc` leaves.

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
| `/` | Quick filter by name |
| `z` | Collapse every branch |
| `?` | Show all of neo-tree's keys |

---

## Buffers, windows, tabs

| Key | What it does |
|---|---|
| **`Tab`** / **`Shift+Tab`** | Next / previous buffer |
| **`Space + x`** | **Close the buffer** — ⚠️ runs `:bdelete!`, unsaved changes are lost |
| `Space + b` | A new empty buffer |
| `Space + \|` | Split the window **vertically** (tmux: `Prefix + \|`) |
| `Space + -` | Split the window **horizontally** (tmux: `Prefix + -`) |
| **`Ctrl + h/j/k/l`** | **Jump between windows — and straight on into a tmux pane** |
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

⚠️ **`Space + x` is `:bdelete!`, with the bang.** The bang means *do it anyway*: unsaved changes go
in the bin, no question asked. `:bd` is the same thing without the bang — it stops and warns you.

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
| **`Space + c + a`** | **Fix it automatically** (code action) |
| **`Space + r + n`** | **Rename** a variable/function everywhere |
| `Space + d + s` | List the symbols in this file |
| `Space + w + s` | Search symbols across the project |
| `[d` / `]d` | Previous / next problem |
| `Space + d` | Show the problem at the cursor in full |
| `Space + q` | Open the list of every problem |

## Completion

| Key | What it does |
|---|---|
| `Ctrl + n` / `Ctrl + p` | Down / up the suggestion list |
| `Enter` | Accept |
| `Ctrl + Space` | Ask for suggestions by hand |
| `Tab` | Jump to the next slot in a snippet |
| `Ctrl + e` | Close the suggestion panel |

## Git

| Key / command | What it does |
|---|---|
| `:Git` | The git status panel |
| `:Git commit` / `:Git push` | Commit / push |
| `:Gdiffsplit` | Compare against the committed version |
| `Space + n + g + s` | Git status as a floating window |

The left column shows the marks by itself: `+` added, `~` changed, `_` deleted.

---

## Editing text

| Key | What it does |
|---|---|
| `Ctrl + s` | Save |
| `Space + s + n` | Save **without** running the auto-format |
| `Ctrl + q` | Quit |
| `gcc` | Comment out the current line |
| `gc` (visual) | Comment out the selection |
| `Ctrl+d` / `Ctrl+u` | Scroll half a page, **re-centring automatically** |
| `n` / `N` | Next match, **re-centring automatically** |
| `x` | Delete 1 character, **without overwriting the clipboard** |
| `<` `>` (visual) | Indent, **keeping the selection** |
| `p` (visual) | Paste **without losing what was copied** |
| `Space + w` | Toggle line wrapping |

### Reloading

| Command | What it does |
|---|---|
| `:e` | Re-read the file from disk — refuses if you have unsaved changes |
| **`:e!`** | **Re-read from disk, throwing away everything unsaved** |
| `:checktime` | Reload only if the file changed on disk underneath you |
| `:source %` | Re-apply the config file you are looking at, without restarting |

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

⚠️ `r` on a selection does **not** swap in a word — it stamps one character over every character
selected (`viw` then `rx` on "hello" gives "xxxxx"). Use `c` to replace a selection with new text.

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

> **Why a file opens with everything already shut:** `lua/plugins/treesitter.lua` switches folding
> on, and nothing sets `foldlevel`, so Neovim's default of `0` applies — and level 0 means every
> fold closed. To have files open flat instead, add `vim.o.foldlevelstart = 99` to
> `lua/core/options.lua`.

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

The background is left **transparent** so WezTerm's gradient shows through.

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
