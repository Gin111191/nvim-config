-- Standalone plugins with less than 10 lines of config go here
return {
  {
    -- Tmux & split window navigation
    'christoomey/vim-tmux-navigator',
  },
  {
    -- Detect tabstop and shiftwidth automatically
    'tpope/vim-sleuth',
  },
  {
    -- Powerful Git integration for Vim
    'tpope/vim-fugitive',
  },
  {
    -- GitHub integration for vim-fugitive
    'tpope/vim-rhubarb',
  },
  {
    -- Hints keybinds
    'folke/which-key.nvim',
  },
  {
    -- Autoclose parentheses, brackets, quotes, etc.
    'windwp/nvim-autopairs',
    event = 'InsertEnter',
    config = true,
    opts = {},
  },
  {
    -- Auto-close and auto-rename HTML/JSX tags: <div> + > gives <div></div>.
    -- Needs the html and tsx treesitter parsers (both in treesitter.lua).
    'windwp/nvim-ts-autotag',
    event = 'InsertEnter',
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    opts = {},
  },
  {
    -- Add / change / delete surrounding pairs and tags: ys, cs, ds (Normal), S (Visual).
    -- e.g. Visual-line + S{ wraps a block in braces; ysiwt then "div" wraps a word in <div>.
    'kylechui/nvim-surround',
    version = '*',
    event = 'VeryLazy',
    opts = {},
  },
  {
    -- Highlight todo, notes, etc in comments
    'folke/todo-comments.nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-lua/plenary.nvim' },
    opts = { signs = false },
  },
  {
    -- High-performance color highlighter
    'norcalli/nvim-colorizer.lua',
    -- It paints hex codes in their own colour, which needs 24-bit colour to mean
    -- anything. Without it the plugin only prints "&termguicolors must be set" at
    -- every startup, so in a 256-colour terminal it simply does not load.
    cond = function()
      return vim.o.termguicolors
    end,
    config = function()
      require('colorizer').setup()
    end,
  },
}
