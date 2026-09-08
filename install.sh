#!/bin/sh
# ==============================================================================
#  Cài đặt Neovim config — macOS / Linux / WSL
#  https://github.com/Gin111191/nvim-config
#
#  Dùng:  ./install.sh            cài bằng symlink (khuyến nghị)
#         ./install.sh --copy     cài bằng cách copy
#         ./install.sh --dry-run  chỉ xem sẽ làm gì
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
        *) echo "Tham số không hiểu: $arg" >&2; exit 1 ;;
    esac
done

say() { printf '%s\n' "$*"; }
run() { if [ "$DRY" -eq 1 ]; then say "  [dry-run] $*"; else "$@"; fi; }

# ---------- 1. Nền tảng ----------
OS="$(uname -s 2>/dev/null || echo unknown)"
case "$OS" in
    Darwin) PLATFORM="macOS" ;;
    Linux)
        if [ -n "${WSL_DISTRO_NAME:-}" ] || grep -qi microsoft /proc/version 2>/dev/null; then
            PLATFORM="WSL (${WSL_DISTRO_NAME:-Linux})"
        else PLATFORM="Linux"; fi ;;
    *) PLATFORM="$OS" ;;
esac
say "Hệ điều hành : $PLATFORM"

# ---------- 2. Neovim ----------
if ! command -v nvim >/dev/null 2>&1; then
    say ""
    say "LỖI: chưa cài Neovim. Cần bản 0.11 trở lên."
    say "  macOS        : brew install neovim"
    say "  Ubuntu/Debian: sudo apt install neovim   (bản apt thường cũ — cân nhắc tải bản release)"
    say "  Arch         : sudo pacman -S neovim"
    exit 1
fi
NVIM_VER="$(nvim --version | head -1)"
say "Neovim       : $NVIM_VER"

case "$NVIM_VER" in
    *v0.[0-9].*)
        MINOR="$(printf '%s' "$NVIM_VER" | sed -n 's/.*v0\.\([0-9]*\)\..*/\1/p')"
        if [ -n "$MINOR" ] && [ "$MINOR" -lt 11 ] 2>/dev/null; then
            say "  CẢNH BÁO: config này cần Neovim >= 0.11 (dùng API vim.lsp.config)."
        fi ;;
esac

# ---------- 3. Công cụ đi kèm ----------
say ""
say "Công cụ đi kèm:"
missing=""
for tool in git gcc curl unzip node npm; do
    if command -v "$tool" >/dev/null 2>&1; then
        printf '  có     %s\n' "$tool"
    else
        printf '  THIẾU  %s\n' "$tool"
        missing="$missing $tool"
    fi
done
if [ -n "$missing" ]; then
    say ""
    say "  Thiếu:$missing"
    say "    git, curl, unzip  → lazy.nvim và Mason cần để tải"
    say "    gcc               → treesitter cần để biên dịch parser"
    say "    node, npm         → các LSP viết bằng JavaScript (typescript, json, css,"
    say "                        html, tailwind, eslint_d, prettier) sẽ KHÔNG cài được"
    say "  Vẫn cài tiếp được, nhưng các phần trên sẽ báo lỗi."
fi

# ---------- 4. Sao lưu ----------
STAMP="$(date +%Y%m%d-%H%M%S)"
say ""
REPLACED_OTHER=0
if [ -e "$DEST" ] || [ -L "$DEST" ]; then
    if [ -L "$DEST" ] && [ "$(readlink "$DEST")" = "$SRC_DIR" ]; then
        say "Đã cài sẵn   : $DEST -> $SRC_DIR"
    else
        say "Sao lưu      : $DEST -> $DEST.bak.$STAMP"
        run mv "$DEST" "$DEST.bak.$STAMP"
        REPLACED_OTHER=1
    fi
fi

# Dữ liệu plugin của MỘT config khác có thể xung đột (phiên bản plugin lệch,
# parser treesitter biên dịch bằng API cũ). Chỉ dọn khi vừa thay thế config khác;
# cài lại chính config này thì giữ nguyên để khỏi tải lại từ đầu.
if [ "$REPLACED_OTHER" -eq 1 ]; then
    for d in "${XDG_DATA_HOME:-$HOME/.local/share}/nvim" "${XDG_STATE_HOME:-$HOME/.local/state}/nvim"; do
        if [ -d "$d" ]; then
            say "Sao lưu      : $d -> $d.bak.$STAMP"
            run mv "$d" "$d.bak.$STAMP"
        fi
    done
fi

# ---------- 5. Cài ----------
if [ ! -e "$DEST" ]; then
    run mkdir -p "$(dirname "$DEST")"
    if [ "$MODE" = symlink ]; then
        say "Tạo symlink  : $DEST -> $SRC_DIR"
        run ln -sfn "$SRC_DIR" "$DEST"
    else
        say "Copy         : $SRC_DIR -> $DEST"
        run cp -r "$SRC_DIR" "$DEST"
    fi
fi

# ---------- 6. Tải plugin ----------
if [ "$DRY" -eq 0 ]; then
    say ""
    say "Tải plugin (lần đầu mất vài phút)..."
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true
    say "Cài LSP, formatter, linter qua Mason..."
    nvim --headless "+MasonToolsUpdateSync" +qa 2>/dev/null || true
    say "Biên dịch parser treesitter..."
    nvim --headless "+TSUpdateSync" +qa 2>/dev/null || true
fi

say ""
say "Xong. Mở nvim và thử:"
say "  Space          đợi 300ms → hiện bảng gợi ý phím"
say "  Space + e      cây thư mục"
say "  Space + s + f  tìm file"
say "  Space + s + g  tìm chữ trong dự án"
say "  :checkhealth   soi xem còn thiếu gì"
