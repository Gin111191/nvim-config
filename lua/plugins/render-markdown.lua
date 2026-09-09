-- Show Markdown files "rendered" inside Neovim: headings on a coloured background,
-- bullets as symbols, tables drawn with borders, checkboxes as tick boxes, code
-- blocks with a language icon — instead of the raw #, * and | characters.
--
-- Entering Insert mode (pressing i) drops back to raw Markdown for editing, and
-- leaving it renders again. That is what render_modes = { 'n', 'c', 't' } means —
-- and it is also the default, so it need not be declared.
--
-- Commands: :RenderMarkdown toggle | enable | disable | expand
return {
  'MeanderingProgrammer/render-markdown.nvim',
  -- This config already uses nvim-web-devicons in 4 other places (alpha, neo-tree,
  -- bufferline, telescope). The plugin probes for an icon provider: it tries
  -- mini.icons first and falls back to nvim-web-devicons. Naming the one already in
  -- use avoids pulling in a second icon set that draws the same file type differently.
  dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
  ft = { 'markdown' }, -- only load on a .md file, matching the default file_types
  ---@module 'render-markdown'
  ---@type render.md.UserConfig
  opts = {},
}
