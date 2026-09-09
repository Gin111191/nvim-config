# nvim-config

Config Neovim chạy trên **macOS, Linux và WSL**. Màu khớp với
[wezterm-config](https://github.com/Gin111191/wezterm-config) — cùng bảng Dusk-Navy.

Dựa trên [hendrikmi/neovim-kickstart-config](https://github.com/hendrikmi/neovim-kickstart-config)
(vốn dựa trên [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim)).

Phím tắt đầy đủ: **[CHEATSHEET.md](CHEATSHEET.md)**

> **Take [tmux-config](https://github.com/Gin111191/tmux-config) with this one.** 24-bit
> colour is arranged across both repos: tmux decides whether to tell Neovim the terminal
> has it, and this repo carries the 256-colour palette for when it does not. Install only
> one and the colours break in a terminal without 24-bit colour, such as macOS Terminal.app.

---

## Cài đặt

```sh
git clone https://github.com/Gin111191/nvim-config ~/.local/share/nvim-config
~/.local/share/nvim-config/install.sh
```

Script tự: nhận diện hệ điều hành → kiểm tra Neovim và công cụ đi kèm → **sao lưu config cũ**
→ symlink vào `~/.config/nvim` → tải plugin, cài LSP, biên dịch parser.

Xem trước không thay đổi gì: `./install.sh --dry-run`

### Yêu cầu

| | Bắt buộc? | Thiếu thì sao |
|---|---|---|
| **Neovim ≥ 0.12** | Có | `vim.lsp.config()` cần ≥ 0.11; **nvim-treesitter nhánh `main` cần ≥ 0.12** |
| `git`, `curl`, `unzip`, `tar` | Có | lazy.nvim, Mason và treesitter không tải được |
| `gcc` | Có | Không biên dịch được parser treesitter |
| `tree-sitter` CLI ≥ 0.26.1 | Có | Nhánh `main` biên dịch parser bằng CLI này. **Mason tự cài** — không cần làm gì |
| **`node`, `npm`** | Nên có | Các LSP viết bằng JS (typescript, json, css, html, tailwind, eslint_d, prettier) **không cài được** |
| **Nerd Font** | Nên có | Icon hiện thành ô vuông |
| Terminal true color | Nên có | Màu sai |

`install.sh` kiểm tra và báo rõ thiếu cái nào.

---

## Có gì

**Tìm kiếm** — Telescope: `Space+sf` tìm file, `Space+sg` tìm chữ trong cả dự án.
**Cây thư mục** — Neo-tree: `Space+e`.
**Hiểu code** — LSP + Mason (tự tải language server) + treesitter (tô màu theo cú pháp thật).
**Gợi ý khi gõ** — nvim-cmp, nguồn từ LSP, buffer, đường dẫn, snippet.
**Format & lint** — none-ls chạy prettier, eslint_d, shfmt khi lưu file.
**Git** — gitsigns (dấu thay đổi ở cột trái) + fugitive (`:Git commit`).
**Học phím** — which-key: bấm `Space` đợi 300ms là hiện bảng gợi ý.
**Đi lại chung với tmux** — `Ctrl+h/j/k/l` nhảy qua cả cửa sổ nvim lẫn pane tmux; chia cửa sổ và đổi kích thước dùng chung ký hiệu với [tmux-config](https://github.com/Gin111191/tmux-config).
**Markdown** — render-markdown.nvim: mở file `.md` là tự dựng hình (tiêu đề, bảng, checkbox, khối code).

44 plugin, ghim phiên bản trong `lazy-lock.json`.

---

## Cấu trúc

```
init.lua                    nạp core rồi liệt kê 14 nhóm plugin
lua/core/options.lua        43 tuỳ chọn cơ bản
lua/core/keymaps.lua        leader = Space, phím tắt chung
lua/core/snippets.lua       cách hiển thị lỗi (tên file kế thừa từ bản gốc, không chứa snippet)
lua/core/theme-source.lua   đọc theme.lua của WezTerm
lua/plugins/*.lua           mỗi file một nhóm plugin
lazy-lock.json              KHOÁ PHIÊN BẢN — đừng xoá, xem mục dưới
```

### Đừng xoá `lazy-lock.json`

File này ghim từng plugin ở đúng commit đã chạy được. Xoá đi rồi cài lại trên máy khác
sẽ lấy bản mới nhất của mọi plugin, và không có gì bảo đảm chúng còn hợp nhau.
Chạy `:Lazy update` xong nhớ commit lại file này.

### Treesitter dùng nhánh `main`

`nvim-treesitter` có hai nhánh, khác nhau hoàn toàn:

| | `master` | `main` |
|---|---|---|
| Trạng thái | **Đã lưu trữ**, commit cuối 2026-03-23 | Đang bảo trì |
| Neovim | ≤ 0.10 | **≥ 0.12** |
| Cấu hình | "modules": `ensure_installed`, `highlight`, `indent` | Tự gọi `install()` và `vim.treesitter.start()` |
| Biên dịch parser | `gcc` trực tiếp | **`tree-sitter` CLI** |
| Parser nằm ở | thư mục plugin | `~/.local/share/nvim/site/parser` |

Config này dùng `main`. Lý do: nhánh `master` đăng ký directive
`set-lang-from-info-string!` theo API cũ (`match[id]` là MỘT node), nhưng từ Neovim 0.11
`match[id]` là DANH SÁCH node. Hậu quả là **mọi lần parse markdown đều vỡ** với
`attempt to call method 'range' (a nil value)` — hỏng cả tô màu trong khối ```code
lẫn render-markdown. Nhánh `main` bỏ hẳn file gây lỗi và dùng query có sẵn của Neovim.

Đổi danh sách ngôn ngữ: sửa `LANGUAGES` ở đầu `lua/plugins/treesitter.lua`, rồi `:TSInstallAll`.

---

## Màu — đồng bộ với WezTerm

`lua/plugins/colortheme.lua` chứa nguyên 16 màu **Dusk-Navy** chép từ `CUSTOM_SCHEMES`
trong [wezterm.lua](https://github.com/Gin111191/wezterm-config/blob/main/wezterm.lua).

Nền để **trong suốt** cho gradient và độ mờ của WezTerm hiện xuyên qua.

`lua/core/theme-source.lua` đọc `theme.lua` của WezTerm để biết đang dùng scheme nào.
Trong WSL nó tự dò sang phía Windows (`/mnt/c/Users/*/.config/wezterm/theme.lua`).
Bấm `Space + t + t` trong nvim để xem đang đọc từ đâu.

Hệ điều hành chuyển sang chế độ sáng thì nvim đổi sang **Everforest Light Medium**,
khớp với `light` trong `theme.lua`.

**Đổi màu:** sửa bảng `DUSK_NAVY` trong `colortheme.lua` cho khớp `wezterm.lua`. Hai nơi,
sửa cả hai.

---

## Khác gì bản gốc hendrikmi

| | hendrikmi | Bản này |
|---|---|---|
| Theme | Nord cố định | **Dusk-Navy**, khớp WezTerm; tự đổi sang Everforest khi hệ thống sang chế độ sáng |
| `lualine` | `theme = 'nord'` | `theme = 'auto'` — bám theo colorscheme |
| `bufferline` | Vạch ngăn `#434C5E` (màu Nord) | `#3D4A6B` (`selection_bg` của Dusk-Navy) |
| `nvim-treesitter` | Chỉ ghim qua `lazy-lock.json` | Ghim thêm `branch = 'master'` ngay trong spec |
| Markdown | — | **render-markdown.nvim** dựng hình file `.md` ngay trong nvim |
| `nvim-treesitter` | Nhánh `master` (đã lưu trữ, vỡ khi parse markdown trên Neovim ≥ 0.11) | **Nhánh `main`** — viết lại theo API mới, hết lỗi tận gốc |
| `image.nvim` | Bật | **Tắt** — cần `luarocks`, thiếu thì lazy build lặp vô hạn rồi báo `Too many rounds of missing plugins`. Bật lại bằng `enabled = true` sau khi cài luarocks |
| Cài đặt | Clone thủ công | `install.sh` đa nền tảng, có sao lưu và kiểm tra công cụ |
| Tài liệu | README tiếng Anh | README + CHEATSHEET tiếng Việt |

## Ghi công

[hendrikmi/neovim-kickstart-config](https://github.com/hendrikmi/neovim-kickstart-config) ·
[kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) (MIT) ·
bảng màu Dusk-Navy port từ profile Terminal.app cùng tên.
