-- Treesitter: parses code into a real syntax tree instead of using regexes.
-- That gives more accurate highlighting, and lets it know "this block is a function",
-- "this bit is a string".
--
-- ── Why the 'main' branch ─────────────────────────────────────────────────────
-- The 'master' branch is ARCHIVED (last commit 2026-03-23) and no longer keeps up
-- with Neovim. Specifically it registers the `set-lang-from-info-string!` directive
-- against the old API, where match[id] is ONE TSNode; from Neovim 0.11 match[id] is a
-- LIST of TSNodes. The result: every markdown parse breaks with "attempt to call
-- method 'range' (a nil value)", taking out both the highlighting inside ```code
-- blocks and any plugin that touches markdown injection.
--
-- The 'main' branch drops query_predicates.lua and the queries/ directory entirely and
-- uses Neovim's own queries — the bug disappears at the root, with nothing to patch.
--
-- ── How it differs from the 'master' branch ───────────────────────────────────
-- The main branch has NO "modules" any more. No ensure_installed / auto_install /
-- highlight / indent in opts. Instead:
--   - installing parsers : require('nvim-treesitter').install{...}
--   - highlighting       : call vim.treesitter.start() yourself in a FileType autocmd
--   - indent/fold        : set indentexpr / foldexpr yourself
-- That is why this file is longer than the old one.
--
-- REQUIRES: Neovim >= 0.12. A machine still on 0.11 has to go back to 'master'.

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
  lazy = false, -- this plugin does NOT support lazy-loading; its README says so
  build = ':TSUpdate',
  config = function()
    local ts = require 'nvim-treesitter'

    ts.setup {
      -- Parsers and queries install here; the directory goes to the front of runtimepath.
      install_dir = vim.fn.stdpath 'data' .. '/site',
    }

    -- Runs asynchronously. Parsers already present are skipped, so calling this on
    -- every startup costs nothing.
    ts.install(LANGUAGES)

    -- The synchronous install, for install.sh on a new machine: ts.install() above is
    -- asynchronous, so nvim --headless exits before the parsers finish compiling.
    vim.api.nvim_create_user_command('TSInstallAll', function()
      require('nvim-treesitter').install(LANGUAGES):wait(600000)
    end, { desc = 'Install every parser in the list, waiting until it is done' })

    -- Ruby relies on Vim's regex highlighter for its indent rules, so it is left out.
    local NO_TS_INDENT = { ruby = true }

    vim.api.nvim_create_autocmd('FileType', {
      group = vim.api.nvim_create_augroup('treesitter-start', { clear = true }),
      callback = function(args)
        local ft = vim.bo[args.buf].filetype
        local lang = vim.treesitter.language.get_lang(ft)
        if not lang then
          return
        end

        -- No parser installed yet: skip silently — the file still opens normally,
        -- just highlighted by Vim's old syntax engine.
        if not pcall(vim.treesitter.start, args.buf, lang) then
          return
        end

        -- Fold along the code structure (Neovim's job).
        vim.wo[0][0].foldexpr = 'v:lua.vim.treesitter.foldexpr()'
        vim.wo[0][0].foldmethod = 'expr'

        -- Indent from the syntax tree (nvim-treesitter's job). Its README calls this
        -- experimental; if a language indents oddly, add it to NO_TS_INDENT.
        if not NO_TS_INDENT[ft] then
          vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end
      end,
    })
  end,
}
