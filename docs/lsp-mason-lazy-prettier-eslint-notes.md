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

## 9. `eslint-config-prettier` — tránh ESLint và Prettier xung đột rule style

Lệnh `npm install --save-dev prettier eslint-config-prettier` cài 2 thứ khác nhau:

- `prettier` — chính Prettier.
- `eslint-config-prettier` — **không phải** cài lại ESLint (ESLint đã có sẵn từ `create-next-app`). Đây là 1 bộ config chỉ có tác dụng **tắt các rule style của ESLint** có thể đụng với Prettier, để Prettier lo 100% phần hình thức, ESLint chỉ lo logic/chất lượng code.

Cài xong chưa đủ — phải gắn vào `eslint.config.mjs`:

```js
import { defineConfig, globalIgnores } from "eslint/config";
import nextVitals from "eslint-config-next/core-web-vitals";
import nextTs from "eslint-config-next/typescript";
import prettierConfig from "eslint-config-prettier";

const eslintConfig = defineConfig([
  ...nextVitals,
  ...nextTs,
  prettierConfig, // phải đứng SAU nextVitals/nextTs — entry sau đè entry trước trong flat config
  globalIgnores([...]),
]);

export default eslintConfig;
```

`prettierConfig` phải nằm **sau** các config bật rule (`nextVitals`, `nextTs`), vì ESLint flat config áp dụng theo thứ tự mảng — đứng trước sẽ bị đè lại, làm mất tác dụng.

## 10. Local vs global: ai thắng khi cả 2 cùng tồn tại

Mục 1 nói tool tự tìm **config**. Mục này nói tiếp một lớp khác: tool tự tìm **binary** nào để chạy, khi vừa có bản Mason (global) vừa có bản cài riêng trong project (local). Đây là 3 câu hỏi tách biệt, thường bị gộp làm một:

| Lớp | Câu hỏi | Ai quyết định |
| --- | --- | --- |
| 1. Cài đặt | Binary từ đâu ra? | Mason (`~/.local/share/nvim/mason/bin`, dùng chung mọi project) hoặc cài local (`node_modules/.bin`, pip/venv riêng project) |
| 2. Resolution | Neovim gọi bản nào khi có cả 2? | Do chính tool/plugin viết logic ưu tiên — **khác nhau tuỳ tool**, không có luật chung |
| 3. Config | Tool đọc config ở đâu? | Luôn tự tìm theo project (mục 1), không liên quan tool chạy từ binary nào |

```
Bạn gõ :w, hoặc gõ code cần gợi ý
                │
                ▼
    Neovim cần chạy 1 TOOL (ts_ls, eslint, prettier, ruff, pylsp...)
                │
                ▼
┌──────────────────────────────────┐
│  LỚP 2 — RESOLUTION               │  "Chạy bản nào?"
│                                    │
│   project/node_modules/.bin       │◄── LOCAL, riêng project này
│        hoặc venv/bin              │
│              │                    │
│      (ưu tiên nếu tool có tìm)    │
│              ▼                    │
│   ~/.local/share/nvim/mason/bin   │◄── GLOBAL, Mason, dùng chung
│                                    │     mọi project
└────────────────┬───────────────────┘
                 ▼
         binary thực sự chạy
                 │
                 ▼
┌──────────────────────────────────┐
│  LỚP 3 — CONFIG                   │  "Đọc rule/style từ đâu?"
│  Luôn tự đi ngược thư mục tìm     │
│  eslint.config.mjs, .prettierrc,  │
│  pyproject.toml...                │
│  — BẤT KỂ binary vừa chạy là      │
│  local hay global                 │
└──────────────────────────────────┘
```

### 10.1. JS/TS: local thắng, đã kiểm chứng thực tế

`ts_ls` (Mason) chỉ là **vỏ nói chuyện LSP protocol** — bộ engine thật được nạp từ `node_modules/typescript` gần nhất tính từ file đang mở (kiểm chứng bằng `ps aux | grep tsserver`, thấy tiến trình chạy đúng file trong `node_modules` của project, không phải trong `mason/`). `eslint` LSP cũng vậy: vỏ là Mason, nhưng rule/plugin lấy từ gói `eslint` trong `node_modules` của project.

`formatting.prettier` trong `none-ls.lua` cũng ưu tiên `node_modules/.bin/prettier` trước, chỉ rơi về `$PATH` (trỏ tới Mason) khi project không có `node_modules`. Vì vậy plugin kiểu `prettier-plugin-tailwindcss` (chỉ tồn tại trong `node_modules` project) vẫn được áp dụng đúng.

**Kiểm tra thật:** mở file `.tsx`, gõ `:NullLsInfo` — hiện đúng path/command đang active.

### 10.2. Python: KHÔNG cùng concept hoàn toàn — vì mô hình dependency khác hẳn Node

Node cài package **vào một thư mục nằm trong chính project** (`node_modules/`), nên "tìm local" chỉ là đi ngược thư mục tìm 1 tên folder cố định — đơn giản, không cần biết gì thêm.

Python cài package **vào site-packages của một Python interpreter cụ thể** (thường nằm trong `.venv/`), không có tên thư mục cố định nào để "cứ thế đi tìm". Muốn biết project dùng package gì, phải biết **đúng interpreter/venv nào** đang được dùng — đây là lý do 2 công cụ Python trong `lsp.lua` xử lý khác hẳn nhau:

**`ruff` (LSP diagnostics) + `ruff_format`/`none-ls.formatting.ruff` (formatter) — giống JS ở lớp config, KHÁC ở lớp resolution:**
- Đọc config đúng kiểu mục 1 (`pyproject.toml [tool.ruff]` hoặc `ruff.toml`, tự tìm theo project) — **giống Prettier/ESLint**.
- Nhưng Ruff là static analyzer, không cần "chạy được" code hay import package thật để lint hầu hết rule, nên **không cần biết venv nào** để hoạt động đúng cơ bản.
- Điểm khác biệt thật sự: `none-ls`'s `ruff`/`ruff_format` source **không có logic ưu tiên local** như Prettier — nó luôn gọi thẳng `ruff` qua `$PATH`, tức **luôn là bản Mason**, bất kể project có tự pin version `ruff` riêng trong `pyproject.toml`/`requirements.txt` hay không. Nếu Mason có bản `ruff` mới/cũ hơn bản project mong muốn, kết quả lint/format trong nvim có thể khác với khi chạy `ruff check .` từ terminal (dùng bản trong venv của project) — **một khác biệt cần nhớ, không tự động khớp như Prettier**.

**`pylsp` (autocomplete/hover/definition, dùng Jedi bên trong) — hoàn toàn không tự dò theo project:**
- Không có dòng nào trong config trỏ `pylsp.plugins.jedi.environment`, cũng không có plugin dò venv (`venv-selector.nvim`...).
- Mason cài `python-lsp-server` vào **venv riêng của chính Mason** (`~/.local/share/nvim/mason/packages/python-lsp-server/venv`), tách biệt hoàn toàn với venv của bất kỳ project Python nào.
- Hệ quả: Jedi phân tích `import` dựa trên **site-packages của venv Mason**, không phải venv project. Nếu project cài `pandas`, `fastapi`... trong venv riêng, `pylsp` **không tự thấy** các package đó — autocomplete/hover có thể báo "không tìm thấy module" hoặc thiếu gợi ý, dù `pip list` trong venv project vẫn có đầy đủ.

```
NODE/TS — có thư mục CỐ ĐỊNH, dễ "cứ thế mà tìm"
──────────────────────────────────────────────────
project/
├── node_modules/
│   ├── typescript/        ← ts_ls tự tìm thấy, nạp đúng bản này
│   ├── eslint/             ← eslint LSP tự tìm thấy
│   └── .bin/prettier       ← none-ls tự tìm thấy, ưu tiên trước Mason
└── package.json

  ts_ls (vỏ, từ Mason) ──tự nạp──► node_modules/typescript (bộ não thật)

  kết quả: LUÔN đúng theo project, tự động 100%, không cấu hình gì


PYTHON — package nằm trong 1 venv, KHÔNG có vị trí/tên cố định
──────────────────────────────────────────────────────────────
project_A/.venv/lib/.../site-packages/    ← project A dùng venv này
project_B/venv/lib/.../site-packages/     ← project B lại đặt tên KHÁC
~/anaconda3/envs/xyz/site-packages/       ← hoặc conda env, tên tuỳ ý

  pylsp (Mason) ──chạy bằng──► venv RIÊNG của chính Mason
                                (KHÔNG phải venv của project nào cả!)

  ruff (Mason) ──luôn gọi qua $PATH──► Mason
                (không có bước "check thư mục local trước" như Prettier)

  kết quả: KHÔNG tự động — phải tự khai `jedi.environment`,
           hoặc chấp nhận Jedi không thấy package đã cài trong venv project
```

**Cách khắc phục nếu gặp (chưa cần làm nếu chưa có project Python thật):**
```lua
pylsp = {
  settings = {
    pylsp = {
      plugins = { ... },
    },
  },
  -- trỏ thẳng interpreter của venv project (cách đơn giản nhất, phải sửa mỗi project)
  before_init = function(_, config)
    config.settings.pylsp.plugins.jedi = {
      environment = vim.fn.getcwd() .. '/.venv/bin/python',
    }
  end,
}
```
Hoặc dùng plugin `linux-cultist/venv-selector.nvim` để tự dò và chọn venv theo project, cập nhật `jedi.environment` linh hoạt hơn — chưa cài trong setup hiện tại.

### 10.3. Các ngôn ngữ/tool còn lại: đa số không có khái niệm "local install" như Node

| Server | Có khái niệm local install? | Ghi chú |
| --- | --- | --- |
| `lua_ls` | Không | `runtime.version` đang cố định `'LuaJIT'` (mục 4 cũ) — đúng cho việc sửa config Neovim, cần đổi tay nếu mở project Lua 5.4 thường |
| `jsonls`, `yamlls`, `cssls`, `html`, `dockerls`, `sqlls`, `terraformls` | Không | Không có ecosystem "cài riêng theo project" cho các định dạng này — luôn chạy bản Mason, chỉ có phần **config** (lược đồ JSON Schema, style YAML...) là tự tìm theo project |
| `tailwindcss` | **Có, một phần** | `tailwindcss-language-server` tự đọc `node_modules/tailwindcss` để biết đang chạy **v3 hay v4** (cú pháp `@theme`, `@tailwind` khác nhau giữa 2 bản) — quan trọng vì project này đang dùng Tailwind v4 |

### 10.4. Tóm gọn nguyên tắc chung

> Tool càng có ecosystem "cài theo từng project vào một chỗ cố định, dễ đoán" (Node → `node_modules`) thì càng dễ tự động ưu tiên local. Tool mà dependency nằm trong một **interpreter/venv không có vị trí cố định** (Python) thì **không tự động** — phải tự chỉ đường, hoặc chấp nhận dùng bản Mason chung cho mọi project (đủ dùng nếu chỉ cần cú pháp cơ bản, không cần biết chính xác package nào đã cài).
