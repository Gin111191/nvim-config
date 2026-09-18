# Nvim Config, LSP & Language Tooling

Notes as of 2026-09-18.

## 1. Nguyên tắc cốt lõi: config tự tìm theo project

Hầu hết formatter/linter/LSP hiện đại **tự tìm file config riêng của project** bằng cách đi ngược thư mục lên, bắt đầu từ file đang mở, cho tới khi gặp file config (`eslint.config.mjs`, `.prettierrc`, `pyproject.toml`, `.clang-format`...) hoặc gốc project.

Đây là hành vi của **chính tool** (ESLint, Prettier, Ruff, clang-format...), không phải của Neovim. Neovim/plugin chỉ cần **gọi đúng tool** — phần đọc config theo project là tự động, không cần cấu hình riêng cho từng project.

Hệ quả thực tế: thêm 1 file config vào project mới thì tool áp dụng ngay, không cần sửa gì trong `~/.config/nvim`.

## 2. lazy.nvim vs Mason

Hai hệ thống quản lý khác nhau, dễ nhầm:

|  | Quản lý gì | Là gì | Update bằng |
| --- | --- | --- | --- |
| lazy.nvim | Plugin Neovim (`nvim-lspconfig`, `mason.nvim`, `none-ls.nvim`, `nvim-cmp`...) | Code Lua chạy bên trong Neovim, tải từ git repo | `:Lazy update` hoặc `:Lazy sync` (update + dọn plugin không dùng) |
| Mason | LSP server / formatter / linter thật (`typescript-language-server`, `pylsp`, `prettier`...) | Binary/npm/pip package chạy như tiến trình riêng, không phải code Neovim | `:Mason` → chọn tool → `u` (1 tool) hoặc `U` (tất cả) |

Khi ngôn ngữ ra bản mới cần server hiểu cú pháp/API mới → đó là việc của **Mason**, không phải lazy.nvim. lazy.nvim chỉ giữ *cách bạn cấu hình* các server đó (file `.lua`) được cập nhật, không đụng tới bản thân server.

## 3. Server chạy ở đâu?

Chạy hoàn toàn **local trên máy**, không phải dịch vụ internet. Chữ "server" chỉ là thuật ngữ giao thức (LSP = Language Server **Protocol**: nvim đóng vai client, tool ngôn ngữ đóng vai server) — cả hai đều là process chạy chung trên máy, giao tiếp qua stdin/stdout, không qua mạng.

Mỗi lần mở file, Neovim tự spawn 1 tiến trình con (ví dụ `typescript-language-server`, `pylsp`) đọc file/project, trả kết quả qua pipe nội bộ. Internet chỉ cần đúng 1 lần lúc Mason tải binary về `~/.local/share/nvim/mason/bin` — sau đó chạy offline hoàn toàn, kể cả khi ngắt mạng.

## 4. Trạng thái tooling theo ngôn ngữ

| Ngôn ngữ | Autocomplete / Definition / Hover | Lint | Format |
| --- | --- | --- | --- |
| TS/JS | `ts_ls` — đã bật | `eslint` LSP — đã bật, đọc `eslint.config.mjs` | Prettier — đã mở rộng sang `js/jsx/ts/tsx/css` |
| Python | `pylsp` (dùng Jedi) — đã bật sẵn | `ruff` — đã bật sẵn, đọc `pyproject.toml`/`ruff.toml` | `ruff_format` — đã bật sẵn |
| C/C++ | Chưa có | Chưa có | Chưa có |

C/C++ cần thêm `clangd` (nav + lint, đọc `compile_commands.json`) và `clang-format` (đọc `.clang-format`) — chưa làm.

JS/TS **tách 2 server** riêng cho nav và lint; Python/C thường dùng **1 server** lo cả hai (`pylsp`/`clangd`), chỉ tách riêng phần format.

## 5. Autocomplete, goto-definition, hover đến từ đâu

Không phải từ Prettier/ESLint (chúng chỉ format/lint) — mà từ chính **LSP server** của từng ngôn ngữ, kết hợp engine `nvim-cmp` (`autocompletion.lua`) hiển thị gợi ý.

Các phím `gd` (definition), `gD` (declaration), `gr` (references), `gI` (implementation), `<leader>rn` (rename), `<leader>ca` (code action) đã bind **generic** qua `LspAttach` trong `lsp.lua` — tự động hoạt động cho bất kỳ server nào đang attach, không cần cấu hình riêng theo ngôn ngữ.

Chỉ cần 1 LSP server đúng cho ngôn ngữ được bật trong `servers = {}`, autocomplete + goto-definition + hover + rename tự động có theo, không cần cấu hình thêm.

## 6. Prettier và ESLint — chi tiết

**ESLint** chạy dưới dạng LSP server thật (không phải `eslint_d` qua null-ls nữa) — tự đọc `eslint.config.mjs` theo từng project, hỗ trợ `EslintFixAll` khi lưu file.

**Prettier** chạy qua `none-ls` formatting source, chỉ format đúng các filetype được liệt kê rõ trong config (ban đầu chỉ `html/json/yaml/markdown`, giờ đã mở rộng thêm `js/jsx/ts/tsx/css`). Có file `.prettierrc` trong project chỉ có ý nghĩa với các filetype đã nằm trong danh sách — thêm config không tự làm Prettier chạy trên filetype chưa được khai báo.

## 7. Thay đổi đã áp dụng (nvim-config repo)

Repo: `github.com/Gin111191/nvim-config`, commit `787b0cf`.

| File | Thay đổi |
| --- | --- |
| `lua/plugins/lsp.lua` | Thêm `eslint` LSP server vào `servers`; auto-fix (`EslintFixAll`) khi lưu file |
| `lua/plugins/none-ls.lua` | Xóa `eslint_d` (không dùng); mở rộng filetypes Prettier thêm `js/jsx/ts/tsx/css` |

Còn sót: binary `eslint_d` vẫn còn trong Mason (chưa tự gỡ), có thể gỡ tay qua `:Mason` (chọn `eslint_d`, nhấn `X`).

## 8. Checklist: thêm hỗ trợ 1 ngôn ngữ mới (ví dụ C)

1. Thêm LSP server vào bảng `servers` trong `lsp.lua` (ví dụ `clangd = {}`).
2. Không cần sửa gì thêm ở Mason — nó tự thấy tên mới qua `vim.tbl_keys(servers)` và tự tải binary khi mở lại nvim.
3. (Tùy chọn) Thêm formatter tương ứng vào `sources` trong `none-ls.lua` (ví dụ `clang-format`).
4. Mở lại nvim để kích hoạt cài đặt tự động.
