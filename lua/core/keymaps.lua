-- Set leader key
vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

-- Disable the spacebar key's default behavior in Normal and Visual modes
vim.keymap.set({ 'n', 'v' }, '<Space>', '<Nop>', { silent = true })

-- For conciseness
local opts = { noremap = true, silent = true }

-- save file
vim.keymap.set('n', '<C-s>', '<cmd> w <CR>', opts)

-- save file without auto-formatting
vim.keymap.set('n', '<leader>sn', '<cmd>noautocmd w <CR>', opts)

-- quit file
vim.keymap.set('n', '<C-q>', '<cmd> q <CR>', opts)

-- delete single character without copying into register
vim.keymap.set('n', 'x', '"_x', opts)

-- Vertical scroll and center
vim.keymap.set('n', '<C-d>', '<C-d>zz', opts)
vim.keymap.set('n', '<C-u>', '<C-u>zz', opts)

-- Find and center
vim.keymap.set('n', 'n', 'nzzzv', opts)
vim.keymap.set('n', 'N', 'Nzzzv', opts)

-- Resize the window: Space + h/j/k/l, the big step (5).
-- Lowercase, matching tmux's Prefix + h/j/k/l. It needs no Shift, and Space + l is
-- free only because the wrap toggle moved off <leader>lw to <leader>w -- left there,
-- every Space+l would stall for timeoutlen (300ms) waiting to see if w followed.
vim.keymap.set('n', '<leader>h', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<leader>j', ':resize +5<CR>', opts)
vim.keymap.set('n', '<leader>k', ':resize -5<CR>', opts)
vim.keymap.set('n', '<leader>l', ':vertical resize +5<CR>', opts)

-- Resize by holding Ctrl+arrow, the fine step (1). Ctrl+w and <leader> both fire
-- once and let go -- Vim has no `bind -r` -- so a run of small adjustments means
-- re-pressing the prefix each time. These repeat on key-repeat instead.
-- Checked free on all four layers: nvim (all modes), tmux (bound only under prefix
-- and in copy-mode, so the bare key reaches us), WezTerm (only CMD+OPT arrows),
-- macOS Spaces (Ctrl+←/→ disabled here; Ctrl+SHIFT+arrow is the one macOS still
-- takes, which is why Shift is avoided).
vim.keymap.set('n', '<C-Left>', ':vertical resize -1<CR>', opts)
vim.keymap.set('n', '<C-Right>', ':vertical resize +1<CR>', opts)
vim.keymap.set('n', '<C-Up>', ':resize +1<CR>', opts)
vim.keymap.set('n', '<C-Down>', ':resize -1<CR>', opts)

-- Ctrl+w > < + - : the middle step (2), and a count still multiplies it.
-- Stock Vim moves by 1 here. A plain remap to ":vertical resize +2" would have
-- thrown the count away -- 10<C-w>> would give 2, not 20 -- so v:count1 is used.
vim.keymap.set('n', '<C-w>>', function() vim.cmd('vertical resize +' .. vim.v.count1 * 2) end, opts)
vim.keymap.set('n', '<C-w><', function() vim.cmd('vertical resize -' .. vim.v.count1 * 2) end, opts)
vim.keymap.set('n', '<C-w>+', function() vim.cmd('resize +' .. vim.v.count1 * 2) end, opts)
vim.keymap.set('n', '<C-w>-', function() vim.cmd('resize -' .. vim.v.count1 * 2) end, opts)

-- Buffers
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts)
vim.keymap.set('n', '<leader>x', ':bdelete!<CR>', opts) -- close buffer
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer

-- Window management
-- Splitting windows, with the same symbols as tmux: | vertical, - horizontal
vim.keymap.set('n', '<leader>|', '<C-w>v', opts) -- split vertically   (tmux: Prefix + |)
vim.keymap.set('n', '<leader>-', '<C-w>s', opts) -- split horizontally (tmux: Prefix + -)
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', ':close<CR>', opts) -- close current split window

-- Moving between windows: Ctrl + h/j/k/l
--
-- NOT set here. The christoomey/vim-tmux-navigator plugin (lua/plugins/misc.lua)
-- claims exactly these keys and loads later, so any :wincmd mapping written here is
-- overwritten and never runs.
--
-- The plugin does more than :wincmd: with the cursor already in the outermost
-- window, it carries on into the tmux pane beside it instead of stopping. For that,
-- tmux needs its matching half — see the "Seamless navigation with Neovim" section
-- in the tmux.conf of Gin111191/tmux-config.

-- Tabs
vim.keymap.set('n', '<leader>to', ':tabnew<CR>', opts) -- open new tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>', opts) -- close current tab
vim.keymap.set('n', '<leader>tn', ':tabn<CR>', opts) --  go to next tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>', opts) --  go to previous tab

-- Toggle line wrapping. Moved off <leader>lw so that <leader>l is a leaf, not a
-- prefix -- see the resize block above.
vim.keymap.set('n', '<leader>w', '<cmd>set wrap!<CR>', opts)

-- Stay in indent mode
vim.keymap.set('v', '<', '<gv', opts)
vim.keymap.set('v', '>', '>gv', opts)

-- Keep last yanked when pasting
vim.keymap.set('v', 'p', '"_dP', opts)

-- Diagnostic keymaps
vim.keymap.set('n', '[d', function()
  vim.diagnostic.jump { count = -1, float = true }
end, { desc = 'Go to previous diagnostic message' })

vim.keymap.set('n', ']d', function()
  vim.diagnostic.jump { count = 1, float = true }
end, { desc = 'Go to next diagnostic message' })

vim.keymap.set('n', '<leader>d', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })
