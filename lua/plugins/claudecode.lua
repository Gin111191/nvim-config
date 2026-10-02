-- coder/claudecode.nvim — the deep IDE-style integration, NOT greggh/claude-code.nvim (which
-- just opens the CLI in a terminal buffer with no awareness of Neovim's state).
--
-- How it actually works: `:ClaudeCode` makes THIS Neovim open a WebSocket server (pure Lua,
-- vim.loop, no extra binary) and write its address to ~/.claude/ide/<port>.lock. The `claude`
-- CLI then opens (in a split here, via snacks) and connects to that socket, so it is talking
-- to Neovim directly over MCP, not just reading files off disk: it sees the current buffer,
-- cursor, and selection live, and can push a diff that opens as a real Neovim diff split
-- (<leader>aa to accept = write the file for real, <leader>ad to reject).
--
-- Needs the `claude` CLI on $PATH (confirmed: ~/.local/bin/claude) — terminal_cmd is left at
-- its default (nil = "claude") rather than hardcoded, so this keeps working if that path
-- ever changes. provider = "auto" picks snacks.nvim automatically since it is already a
-- dependency here (see image.lua) — no extra config needed for that.
return {
  'coder/claudecode.nvim',
  dependencies = { 'folke/snacks.nvim' },
  cmd = {
    'ClaudeCode',
    'ClaudeCodeFocus',
    'ClaudeCodeSelectModel',
    'ClaudeCodeAdd',
    'ClaudeCodeSend',
    'ClaudeCodeTreeAdd',
    'ClaudeCodeStatus',
    'ClaudeCodeStart',
    'ClaudeCodeStop',
    'ClaudeCodeOpen',
    'ClaudeCodeClose',
    'ClaudeCodeDiffAccept',
    'ClaudeCodeDiffDeny',
    'ClaudeCodeCloseAllDiffs',
  },
  -- <leader>a was free (checked: nothing else in this config uses it) -- kept as the
  -- plugin's own default group, so its which-key label ("AI/Claude Code") still applies.
  keys = {
    { '<leader>a', nil, desc = '[A]I / Claude Code' },
    { '<leader>ac', '<cmd>ClaudeCode<cr>', desc = 'Toggle Claude' },
    { '<leader>af', '<cmd>ClaudeCodeFocus<cr>', desc = 'Focus Claude' },
    { '<leader>ar', '<cmd>ClaudeCode --resume<cr>', desc = 'Resume Claude' },
    { '<leader>aC', '<cmd>ClaudeCode --continue<cr>', desc = 'Continue Claude' },
    { '<leader>am', '<cmd>ClaudeCodeSelectModel<cr>', desc = 'Select Claude model' },
    { '<leader>ab', '<cmd>ClaudeCodeAdd %<cr>', desc = 'Add current buffer' },
    { '<leader>as', '<cmd>ClaudeCodeSend<cr>', mode = 'v', desc = 'Send selection to Claude' },
    {
      '<leader>as',
      '<cmd>ClaudeCodeTreeAdd<cr>',
      desc = 'Add file',
      ft = { 'NvimTree', 'neo-tree', 'oil', 'minifiles', 'netrw', 'snacks_picker_list' },
    },
    { '<leader>aa', '<cmd>ClaudeCodeDiffAccept<cr>', desc = 'Accept diff' },
    { '<leader>ad', '<cmd>ClaudeCodeDiffDeny<cr>', desc = 'Deny diff' },
  },
  opts = {
    terminal = {
      split_side = 'right',
      split_width_percentage = 0.30,
      provider = 'auto',
    },
    diff_opts = {
      layout = 'vertical', -- same orientation as :Gdiffsplit, for consistency
    },
  },
}
