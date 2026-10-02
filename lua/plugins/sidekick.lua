-- folke/sidekick.nvim — only its AI CLI half: Claude runs in a floating terminal, and the session
-- lives in its own tmux session, so hiding the float (or quitting Neovim) never stops Claude.
-- The other half, Copilot "Next Edit Suggestions", is switched off: it needs the Copilot LSP,
-- which this config does not run (`:checkhealth sidekick` still warns about it — ignore that).
--
-- Replaces coder/claudecode.nvim. What that plugin did and this one does not: the IDE protocol
-- (`/ide`, accept/reject diffs in Neovim, Claude asking for LSP diagnostics or the live selection).
-- What still works without it: the nvim-open.sh hooks (open + highlight + close the files Claude
-- edits), which find this Neovim through lua/core/nvim-registry.lua instead of claudecode's lock file.
--
-- Sessions: one per tool per project folder (sidekick's id = tool + sha256(cwd)), so `Space a c`
-- always reopens the same Claude for this project. Extra Claudes in the same project: start them
-- in a tmux window/pane — `Space a s` lists every running Claude it finds in tmux and can send
-- context to any of them, but only the project's own session shows in the float.
return {
  'folke/sidekick.nvim',
  dependencies = { 'folke/snacks.nvim' }, -- picker for prompts / sessions
  cmd = 'Sidekick',
  opts = {
    nes = { enabled = false },
    cli = {
      win = {
        layout = 'float',
        float = { width = 0.9, height = 0.9 },
      },
      mux = {
        enabled = true,
        backend = 'tmux',
        create = 'terminal', -- show the tmux session in the float, not in a new tmux window
      },
    },
  },
  keys = {
    { '<leader>a', nil, desc = '[A]I / Claude' },
    {
      '<leader>ac',
      function()
        require('sidekick.cli').toggle { name = 'claude', focus = true }
      end,
      desc = 'Claude: toggle the float',
    },
    {
      '<leader>as',
      function()
        require('sidekick.cli').select { filter = { installed = true } }
      end,
      desc = 'Claude: pick a session',
    },
    {
      '<leader>ad',
      function()
        require('sidekick.cli').close()
      end,
      desc = 'Claude: detach (the session keeps running)',
    },
    {
      '<leader>at',
      function()
        require('sidekick.cli').send { msg = '{this}' }
      end,
      mode = { 'n', 'x' },
      desc = 'Claude: send this (line or selection, with location)',
    },
    {
      '<leader>af',
      function()
        require('sidekick.cli').send { msg = '{file}' }
      end,
      desc = 'Claude: send the current file',
    },
    {
      '<leader>av',
      function()
        require('sidekick.cli').send { msg = '{selection}' }
      end,
      mode = { 'x' },
      desc = 'Claude: send the selected text',
    },
    {
      '<leader>ap',
      function()
        require('sidekick.cli').prompt()
      end,
      mode = { 'n', 'x' },
      desc = 'Claude: pick a ready-made prompt',
    },
  },
}
