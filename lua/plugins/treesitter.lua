return { -- Highlight, edit, and navigate code
  'nvim-treesitter/nvim-treesitter',
  -- BẮT BUỘC ghim nhánh: nhánh mặc định của nvim-treesitter đã chuyển sang 'main',
  -- bản viết lại bỏ hẳn module 'nvim-treesitter.configs' mà file này đang gọi.
  -- Không có dòng này thì lỗi "module 'nvim-treesitter.configs' not found".
  branch = 'master',
  build = ':TSUpdate',
  -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
  opts = {
    ensure_installed = {
      'lua',
      'python',
      'javascript',
      'typescript',
      'vimdoc',
      'vim',
      'regex',
      'terraform',
      'sql',
      'dockerfile',
      'toml',
      'json',
      'java',
      'groovy',
      'go',
      'gitignore',
      'graphql',
      'yaml',
      'make',
      'cmake',
      'markdown',
      'markdown_inline',
      'bash',
      'tsx',
      'css',
      'html',
    },
    -- Autoinstall languages that are not installed
    auto_install = true,
    highlight = {
      enable = true,
      -- Some languages depend on vim's regex highlighting system (such as Ruby) for indent rules.
      --  If you are experiencing weird indenting issues, add the language to
      --  the list of additional_vim_regex_highlighting and disabled languages for indent.
      additional_vim_regex_highlighting = { 'ruby' },
    },
    indent = { enable = true, disable = { 'ruby' } },
  },
  config = function(_, opts)
    require('nvim-treesitter.configs').setup(opts)

    -- ── Vá lỗi tương thích của nhánh master ─────────────────────────────────
    -- nvim-treesitter master đã LƯU TRỮ (commit cuối 2026-03-23) và đăng ký
    -- directive `set-lang-from-info-string!` theo API cũ:
    --
    --     Neovim <= 0.10 :  match[id]  là MỘT TSNode
    --     Neovim >= 0.11 :  match[id]  là DANH SÁCH TSNode
    --
    -- Hàm gốc (query_predicates.lua:141) truyền thẳng cái table đó vào
    -- get_node_text; hàm này gọi node:range() -> "attempt to call method
    -- 'range' (a nil value)", làm VỠ MỌI lần parse markdown.
    --
    -- Directive này được queries/markdown/injections.scm dùng để đoán ngôn ngữ
    -- của khối ```lang. Vỡ nó là hỏng cả tô màu bên trong khối code lẫn mọi
    -- plugin đụng tới injection của markdown (render-markdown.nvim chẳng hạn).
    --
    -- Xoá được đoạn này khi nào chuyển nvim-treesitter sang nhánh 'main'.
    local ALIASES = { ex = 'elixir', pl = 'perl', sh = 'bash', uxn = 'uxntal', ts = 'typescript' }
    vim.treesitter.query.add_directive('set-lang-from-info-string!', function(match, _, bufnr, pred, metadata)
      local nodes = match[pred[2]]
      -- Nhận cả hai dạng: TSNode đơn (API cũ) và danh sách TSNode (0.11+).
      local node = nodes
      if type(nodes) == 'table' and type(nodes.range) ~= 'function' then
        node = nodes[#nodes]
      end
      if not node then
        return
      end
      local alias = vim.treesitter.get_node_text(node, bufnr):lower()
      metadata['injection.language'] = vim.filetype.match { filename = 'a.' .. alias } or ALIASES[alias] or alias
    end, { force = true, all = false })
  end,
}
