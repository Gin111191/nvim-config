# nvim-config

A Neovim config that runs on **macOS, Linux and WSL**. Its colours match
[wezterm-config](https://github.com/Gin111191/wezterm-config) — the same Dusk-Navy palette.

Based on [hendrikmi/neovim-kickstart-config](https://github.com/hendrikmi/neovim-kickstart-config)
(itself based on [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)).

Every key binding: **[CHEATSHEET.md](CHEATSHEET.md)**

> **Take [tmux-config](https://github.com/Gin111191/tmux-config) with this one.** 24-bit
> colour is arranged across both repos: tmux decides whether to tell Neovim the terminal
> has it, and this repo carries the 256-colour palette for when it does not. Install only
> one and the colours break in a terminal without 24-bit colour, such as macOS Terminal.app.

---

## Install

```sh
git clone https://github.com/Gin111191/nvim-config ~/.local/share/nvim-config
~/.local/share/nvim-config/install.sh
```

The script does it all: identify the operating system → check Neovim and the supporting tools →
**back up the old config** → symlink it into `~/.config/nvim` → download the plugins, install the
LSPs, compile the parsers.

To see what it would do without changing anything: `./install.sh --dry-run`

### Requirements

| | Required? | What breaks without it |
|---|---|---|
| **Neovim ≥ 0.12** | Yes | `vim.lsp.config()` needs ≥ 0.11; **nvim-treesitter's `main` branch needs ≥ 0.12** |
| `git`, `curl`, `unzip`, `tar` | Yes | lazy.nvim, Mason and treesitter cannot download |
| `gcc` | Yes | treesitter parsers cannot be compiled |
| `tree-sitter` CLI ≥ 0.26.1 | Yes | The `main` branch compiles parsers with this CLI. **Mason installs it** — nothing to do |
| **`node`, `npm`** | Recommended | The LSPs written in JS (typescript, json, css, html, tailwind, eslint_d, prettier) **cannot install** |
| **A Nerd Font** | Recommended | Icons show as empty boxes |
| A true-colour terminal | Recommended | Wrong colours |
| **ImageMagick** | For images | Only PNG can show; see [Images](#images--snacksimage) |
| Kitty or Ghostty | For images | No images at all (WezTerm: a float only, not verified here) |

`install.sh` checks for each and says plainly what is missing.

---

## What it does

**Searching** — Telescope: `Space+sf` finds a file, `Space+sg` finds text across the whole project.
**File tree** — Neo-tree: `Space+e`.
**Understanding code** — LSP + Mason (downloads the language servers) + treesitter (highlighting from a real syntax tree).
**Completion** — nvim-cmp, sourced from the LSP, the buffer, paths and snippets.
**Format & lint** — none-ls runs prettier, eslint_d and shfmt on save.
**Git** — gitsigns (change marks in the left column) + fugitive (`:Git commit`).
**Learning the keys** — which-key: press `Space`, wait 300ms, and the hint panel appears.
**Moving around with tmux** — `Ctrl+h/j/k/l` crosses both nvim windows and tmux panes; splitting and resizing share their symbols with [tmux-config](https://github.com/Gin111191/tmux-config).
**Markdown** — render-markdown.nvim: opening a `.md` file renders it in place (headings, tables, checkboxes, code blocks).
**Images** — snacks.image: an image file opens as a picture; an image a document references pops up while the cursor is on it; `Space+si` finds images with a live preview.

45 plugins, with versions pinned in `lazy-lock.json`.

---

## Layout

```
init.lua                    loads core, then lists the 16 plugin groups
lua/core/options.lua        43 basic options
lua/core/keymaps.lua        leader = Space, the general key bindings
lua/core/snippets.lua       how errors are displayed (the filename is inherited from the
                            original config; it holds no snippets)
lua/core/theme-source.lua   reads WezTerm's theme.lua
lua/plugins/*.lua           one file per plugin group
lazy-lock.json              THE VERSION LOCK — do not delete, see below
```

### Do not delete `lazy-lock.json`

This file pins every plugin at the exact commit that was known to work. Delete it, reinstall on
another machine, and you get the newest version of every plugin with no guarantee they still fit
together. After running `:Lazy update`, remember to commit this file again.

### Treesitter uses the `main` branch

`nvim-treesitter` has two branches, and they are completely different:

| | `master` | `main` |
|---|---|---|
| Status | **Archived**, last commit 2026-03-23 | Maintained |
| Neovim | ≤ 0.10 | **≥ 0.12** |
| Configuration | "modules": `ensure_installed`, `highlight`, `indent` | Call `install()` and `vim.treesitter.start()` yourself |
| Compiling parsers | `gcc` directly | **the `tree-sitter` CLI** |
| Parsers live in | the plugin directory | `~/.local/share/nvim/site/parser` |

This config uses `main`. The reason: the `master` branch registers the
`set-lang-from-info-string!` directive against the old API (`match[id]` is ONE node), but from
Neovim 0.11 `match[id]` is a LIST of nodes. The result is that **every markdown parse breaks**
with `attempt to call method 'range' (a nil value)` — taking out both the highlighting inside ```code
blocks and render-markdown. The `main` branch drops the offending file entirely and uses Neovim's
own queries.

To change the list of languages: edit `LANGUAGES` at the top of `lua/plugins/treesitter.lua`, then
run `:TSInstallAll`.

---

## Images — snacks.image

The terminal draws the picture itself (Kitty graphics protocol), so it needs Kitty or Ghostty.

| Where | What you see |
|---|---|
| An image file opened (`nvim a.png`, Telescope, Neo-tree) | The window is the picture |
| An image a document references (markdown, html, css, latex, typst, …) | A float while the cursor is on the reference — `inline = false`, so a document with many images is not drawn all at once |
| `Space+si` | snacks.picker listing only images, previewing each one as you move |

Formats: png jpg jpeg gif bmp webp tiff heic avif pdf icns svg ico, plus the first frame of
mp4/mov/avi/mkv/webm. Everything except PNG goes through ImageMagick first: 0.3–1 s the first time
(an 8K wallpaper is the slow end), then cached in `~/.cache/nvim/snacks/image`.

### ImageMagick — the same line on the Mac and on WSL

```sh
brew install imagemagick-full && brew link --force imagemagick-full
magick -list format | grep -i svg     # expect "RSVG" in the description
```

On WSL this is linuxbrew, so no sudo. `imagemagick-full`, not `imagemagick`: the plain formula has
no librsvg and registers no fonts, so an SVG with text fails (`unable to read font`) and gradients
come out black. `-full` also brings ghostscript, which is what draws a PDF page.

### WSL, viewed from Kitty on the Mac over SSH

Nvim runs on WSL; the picture is drawn by Kitty on the Mac. snacks sees `SSH_CONNECTION` and sends
the image bytes down the connection instead of a path. No X server and no WSLg are involved, so this
works even while WSLg is broken.

On WSL, after installing ImageMagick as above:

```sh
git -C ~/.config/nvim pull
nvim                                  # lazy installs snacks.nvim at the commit in lazy-lock.json, then :q
```

WSL must also know `TERM=xterm-kitty`, which plain `ssh` does not carry across. Any one of:

```sh
kitten ssh wsl                                                          # from Kitty: copies the terminfo by itself
curl -fsSL https://raw.githubusercontent.com/kovidgoyal/kitty/master/terminfo/kitty.terminfo | tic -x -o ~/.terminfo -   # on WSL, once
infocmp -a xterm-kitty | ssh wsl 'tic -x -o ~/.terminfo /dev/stdin'    # on the Mac inside Kitty, once — quoted, so ~ expands on WSL
```

Then, in nvim on WSL, `:checkhealth snacks`: the `Snacks.image` block should report `kitty` detected
and supported, and find `magick`. A missing `magick` looks exactly like a missing image — nothing
errors — so check health before hunting for the file.

### What breaks it

- **Two tmux between nvim and Kitty.** snacks wraps an image for one tmux; a second one swallows it.
  Open the SSH from Kitty directly; a tmux on WSL alone is fine (`allow-passthrough on` is in
  [tmux-config](https://github.com/Gin111191/tmux-config)). Even then tmux passes the image
  through without tracking it, so a scroll or a pane resize can strand it; reopening the buffer
  redraws it.
- **A tmux hides Kitty.** snacks finds the terminal by asking it (XTVERSION), and the tmux in the
  way answers `tmux` instead, so `:checkhealth snacks` reports no graphics protocol and nothing is
  drawn. `lua/plugins/image.lua` asks tmux for the attached client's `#{client_termname}` and, if
  it is kitty, sets `SNACKS_KITTY=1`. That works for a pane created before the attach too — the
  usual ssh-in-then-`tmux attach`. It does not cover a tmux on the Mac side: from WSL there is no
  way to see past it.
- **An image over 10000 px on either side.** Kitty rejects it (`Image too large`) and shows nothing,
  no error. A long single-page PDF does this at snacks' 192 dpi — 870x8100 pt comes out 21314 px
  tall — so `lua/plugins/image.lua` caps pdf and svg output at 4096 px. Such a page still shows only
  as a narrow strip; read it on the Mac.
- **A blank buffer when going back to an image already open** — upstream bug
  [folke/snacks.nvim#2896](https://github.com/folke/snacks.nvim/issues/2896), patched in
  `lua/plugins/image.lua` until snacks fixes it.

---

## Colours — kept in step with WezTerm

`lua/plugins/colortheme.lua` holds the 16 **Dusk-Navy** colours verbatim, copied from
`CUSTOM_SCHEMES` in [wezterm.lua](https://github.com/Gin111191/wezterm-config/blob/main/wezterm.lua).

The background is left **transparent** so WezTerm's gradient and opacity show through.

`lua/core/theme-source.lua` reads WezTerm's `theme.lua` to find out which scheme is in use.
Inside WSL it probes the Windows side by itself (`/mnt/c/Users/*/.config/wezterm/theme.lua`).
Press `Space + t + t` in nvim to see where it is reading from.

When the operating system switches to light mode, nvim switches to **Everforest Light Medium**,
matching `light` in `theme.lua`.

**To change the colours:** edit the `DUSK_NAVY` table in `colortheme.lua` to match `wezterm.lua`.
Two places, both need changing.

---

## How it differs from hendrikmi's original

| | hendrikmi | This one |
|---|---|---|
| Theme | Nord, fixed | **Dusk-Navy**, matching WezTerm; switches to Everforest when the system goes light |
| `lualine` | `theme = 'nord'` | `theme = 'auto'` — follows the colorscheme |
| `bufferline` | Separator `#434C5E` (a Nord colour) | `#3D4A6B` (Dusk-Navy's `selection_bg`) |
| `nvim-treesitter` | Pinned only through `lazy-lock.json` | Also pinned with `branch = 'master'` in the spec itself |
| Markdown | — | **render-markdown.nvim** renders `.md` files inside nvim |
| `nvim-treesitter` | The `master` branch (archived, breaks parsing markdown on Neovim ≥ 0.11) | **The `main` branch** — rewritten against the new API, the bug gone at the root |
| `image.nvim` | On | **Off** — it needs `luarocks`, and without it lazy rebuilds endlessly and reports `Too many rounds of missing plugins`. Images come from **snacks.image** instead, which only calls the ImageMagick binary — see [Images](#images--snacksimage) |
| Installing | Clone it by hand | A cross-platform `install.sh`, with backups and a tool check |
| Documentation | README only | README + a full CHEATSHEET |

## Credits

[hendrikmi/neovim-kickstart-config](https://github.com/hendrikmi/neovim-kickstart-config) ·
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (MIT) ·
the Dusk-Navy palette, ported from the Terminal.app profile of the same name.
