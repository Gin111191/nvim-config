#!/bin/sh
# ==============================================================================
#  Install the Neovim config — macOS / Linux / WSL
#  https://github.com/Gin111191/nvim-config
#
#  Usage: ./install.sh            install by symlink (recommended)
#         ./install.sh --copy     install by copying
#         ./install.sh --dry-run  only show what it would do
# ==============================================================================
set -eu

SRC_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
DEST="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"

MODE=symlink
DRY=0
for arg in "$@"; do
    case "$arg" in
        --copy)    MODE=copy ;;
        --dry-run) DRY=1 ;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
        *) echo "Unknown argument: $arg" >&2; exit 1 ;;
    esac
done

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# ---------- 1. Platform ----------
OS="$(uname -s 2>/dev/null || echo unknown)"
case "$OS" in
    Darwin) PLATFORM="macOS" ;;
    Linux)
        if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
            PLATFORM="WSL (${WSL_DISTRO_NAME:-Linux})"
        else PLATFORM="Linux"; fi ;;
    *) PLATFORM="$OS" ;;
esac
say "Operating system : $PLATFORM"

# ---------- 2. Neovim ----------
if ! command -v nvim >/dev/null 2>&1; then
    say ""
    say "ERROR: Neovim is not installed. Version 0.12 or newer is needed."
    say "  macOS        : brew install neovim"
    say "  Ubuntu/Debian: sudo apt install neovim   (apt's build is often old — consider the release binary)"
    say "  Arch         : sudo pacman -S neovim"
    exit 1
fi
NVIM_VER="$(nvim --version | head -1)"
say "Neovim           : $NVIM_VER"

case "$NVIM_VER" in
    *v0.[0-9].*)
        MINOR="$(printf '%s' "$NVIM_VER" | sed -n 's/.*v0\.\([0-9]*\)\..*/\1/p')"
        if [ -n "$MINOR" ] && [ "$MINOR" -lt 12 ] 2>/dev/null; then
            say "  WARNING: this config needs Neovim >= 0.12."
            say "    - vim.lsp.config()               needs >= 0.11"
            say "    - nvim-treesitter's main branch  needs >= 0.12"
        fi ;;
esac

# ---------- 3. Supporting tools ----------
say ""
say "Supporting tools:"
missing=""
for tool in git gcc curl unzip tar node npm; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '  have     %s\n' "$tool"
    else
        printf '  MISSING  %s\n' "$tool"
        missing="$missing $tool"
    fi
done
if [ -n "$missing" ]; then
    say ""
    say "  Missing:$missing"
    say "    git, curl, unzip, tar → lazy.nvim, Mason and treesitter need these to download"
    say "    gcc                  → treesitter needs it to compile parsers"
    say "    node, npm            → the LSPs written in JavaScript (typescript, json, css,"
    say "                           html, tailwind, eslint_d, prettier) will NOT install"
    say "  The install still runs, but those parts will report errors."
fi

# ---------- 4. Backups ----------
STAMP="$(date +%Y%m%d-%H%M%S)"
say ""
REPLACED_OTHER=0
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC_DIR" ]; then
        say "Already there    : $DEST -> $SRC_DIR"
    else
        say "Backing up       : $DEST -> $DEST.bak.$STAMP"
        run mv "$DEST" "$DEST.bak.$STAMP"
        REPLACED_OTHER=1
    fi
fi

# Plugin data belonging to a DIFFERENT config can clash (mismatched plugin versions,
# treesitter parsers compiled against the old API). Only clear it when another config
# has just been replaced; reinstalling this same config keeps it, to avoid
# re-downloading everything.
if [ "$REPLACED_OTHER" -eq 1 ]; then
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" "${XDG_STATE_HOME:-$HOME/.local/state}/nvim"; do
        if [ -d "$d" ]; then
            say "Backing up       : $d -> $d.bak.$STAMP"
            run mv "$d" "$d.bak.$STAMP"
        fi
    done
fi

# ---------- 5. Install ----------
if [ ! -e "$DEST" ]; then
    run mkdir -p "$(dirname "$DEST")"
    if [ "$MODE" = symlink ]; then
        say "Symlinking       : $DEST -> $SRC_DIR"
        run ln -sfn "$SRC_DIR" "$DEST"
    else
        say "Copying          : $SRC_DIR -> $DEST"
        run cp -r "$SRC_DIR" "$DEST"
    fi
fi

# ---------- 6. Download the plugins ----------
if [ "$DRY" -eq 0 ]; then
    say ""
    say "1/3  Downloading plugins (the first run takes a few minutes)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

    # Mason MUST run before treesitter: nvim-treesitter's 'main' branch compiles
    # parsers with the tree-sitter CLI, and Mason is what installs that CLI. In the
    # other order every parser fails with ENOENT ... (cmd): 'tree-sitter'.
    say "2/3  Installing LSPs, formatters, linters and the tree-sitter CLI via Mason..."
    nvim --headless "+MasonToolsUpdateSync" +qa 2>/dev/null || true

    say "3/3  Compiling treesitter parsers (takes a few minutes)..."
    nvim --headless "+TSInstallAll" +qa 2>/dev/null || true
fi

say ""
say "Done. Open nvim and try:"
say "  Space          wait 300ms → the key hint panel appears"
say "  Space + e      the file tree"
say "  Space + s + f  find a file"
say "  Space + s + g  find text across the project"
say "  :checkhealth   see what is still missing"
