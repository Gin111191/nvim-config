-- Treesitter: phân tích code thành cây cú pháp thật, thay cho regex.
-- Nhờ đó tô màu chính xác hơn, và biết được "khối này là một hàm", "chỗ này là chuỗi".
--
-- ── Vì sao dùng nhánh 'main' ──────────────────────────────────────────────────
-- Nhánh 'master' đã LƯU TRỮ (commit cuối 2026-03-23) và không còn theo kịp Neovim.
-- Cụ thể nó đăng ký directive `set-lang-from-info-string!` theo API cũ, trong đó
-- match[id] là MỘT TSNode; từ Neovim 0.11 match[id] là DANH SÁCH TSNode. Hậu quả:
-- mọi lần parse markdown đều vỡ với "attempt to call method 'range' (a nil value)",
-- hỏng cả tô màu trong khối ```code lẫn plugin nào đụng tới injection của markdown.
--
-- Nhánh 'main' bỏ hẳn query_predicates.lua và thư mục queries/, dùng thẳng query
-- có sẵn của Neovim — lỗi biến mất tận gốc, không cần vá.
--
-- ── Khác biệt so với nhánh 'master' ───────────────────────────────────────────
-- Nhánh main KHÔNG còn "modules". Không có ensure_installed / auto_install /
-- highlight / indent trong opts nữa. Thay vào đó:
--   - cài parser  : require('nvim-treesitter').install{...}
--   - tô màu      : tự gọi vim.treesitter.start() trong autocmd FileType
--   - thụt lề/fold: tự đặt indentexpr / foldexpr
-- Đó là lý do file này dài hơn bản cũ.
--
-- YÊU CẦU: Neovim >= 0.12. Máy nào còn 0.11 thì phải quay về nhánh 'master'.

local LANGUAGES = {
  'bash',
  'cmake',
  'css',
  'dockerfile',
  'gitignore',
  'go',
  'graphql',
  'groovy',
  'html',
  'java',
  'javascript',
  'json',
  'lua',
  'make',
  'markdown',
  'markdown_inline',
  'python',
  'regex',
  'sql',
  'terraform',
  'toml',
  'tsx',
  'typescript',
  'vim',
  'vimdoc',
  'yaml',
}

return {
  'nvim-treesitter/nvim-treesitter',
  branch = 'main',
  lazy = false, -- plugin này KHÔNG hỗ trợ lazy-load, README ghi rõ
  build = ':TSUpdate',
  config = function()
    local ts = require 'nvim-treesitter'

    ts.setup {
      -- Parser và query cài vào đây; thư mục được đưa lên đầu runtimepath.
      install_dir = vim.fn.stdpath 'data' .. '/site',
    }

    -- Chạy bất đồng bộ. Parser nào đã có thì bỏ qua, nên gọi mỗi lần khởi động
    -- cũng không tốn gì.
    ts.install(LANGUAGES)

    -- Cài đồng bộ, dùng cho install.sh trên máy mới: ts.install() ở trên chạy
    -- bất đồng bộ nên nvim --headless thoát trước khi parser biên dịch xong.
    vim.api.nvim_create_user_command('TSInstallAll', function()
      require('nvim-treesitter').install(LANGUAGES):wait(600000)
    end, { desc = 'Cài toàn bộ parser trong danh sách, chờ tới khi xong' })

    -- Ruby dựa vào bộ tô màu regex của Vim cho luật thụt lề, nên để riêng.
    local NO_TS_INDENT = { ruby = true }

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        -- Chưa cài parser thì im lặng bỏ qua — file vẫn mở bình thường,
        -- chỉ là tô màu bằng syntax cũ của Vim.
        if not pcall(vim.treesitter.start, args.buf, lang) then
          return
        end

        -- Fold theo cấu trúc code (Neovim lo).
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'

        -- Thụt lề theo cây cú pháp (nvim-treesitter lo). README ghi là còn
        -- thử nghiệm; thấy thụt lề lạ ở ngôn ngữ nào thì thêm vào NO_TS_INDENT.
        if not NO_TS_INDENT[ft] then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
