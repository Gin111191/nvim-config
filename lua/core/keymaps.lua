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

-- Đổi kích thước cửa sổ: Space + H/J/K/L
-- Khớp với tmux (Prefix + H/J/K/L). Trước đây dùng phím mũi tên, nhưng như vậy
-- mũi tên mất chức năng di chuyển con trỏ thông thường.
vim.keymap.set('n', '<leader>H', ':vertical resize -5<CR>', opts)
vim.keymap.set('n', '<leader>J', ':resize +5<CR>', opts)
vim.keymap.set('n', '<leader>K', ':resize -5<CR>', opts)
vim.keymap.set('n', '<leader>L', ':vertical resize +5<CR>', opts)

-- Buffers
vim.keymap.set('n', '<Tab>', ':bnext<CR>', opts)
vim.keymap.set('n', '<S-Tab>', ':bprevious<CR>', opts)
vim.keymap.set('n', '<leader>x', ':bdelete!<CR>', opts) -- close buffer
vim.keymap.set('n', '<leader>b', '<cmd> enew <CR>', opts) -- new buffer

-- Window management
-- Chia cửa sổ, ký hiệu giống tmux: | dọc, - ngang
vim.keymap.set('n', '<leader>|', '<C-w>v', opts) -- chia dọc  (tmux: Prefix + |)
vim.keymap.set('n', '<leader>-', '<C-w>s', opts) -- chia ngang (tmux: Prefix + -)
vim.keymap.set('n', '<leader>se', '<C-w>=', opts) -- make split windows equal width & height
vim.keymap.set('n', '<leader>xs', ':close<CR>', opts) -- close current split window

-- Di chuyển giữa các cửa sổ: Ctrl + h/j/k/l
--
-- KHÔNG đặt ở đây. Plugin christoomey/vim-tmux-navigator (lua/plugins/misc.lua)
-- chiếm đúng bộ phím này và nạp sau, nên mọi ánh xạ :wincmd viết ở đây đều bị đè
-- và không bao giờ chạy.
--
-- Plugin làm được nhiều hơn :wincmd: khi con trỏ đã ở cửa sổ ngoài cùng, nó nhảy
-- tiếp sang pane tmux bên cạnh thay vì đứng im. Muốn vậy tmux cũng phải có phần
-- cấu hình tương ứng — xem mục "Điều hướng liền mạch với Neovim" trong tmux.conf
-- của Gin111191/tmux-config.

-- Tabs
vim.keymap.set('n', '<leader>to', ':tabnew<CR>', opts) -- open new tab
vim.keymap.set('n', '<leader>tx', ':tabclose<CR>', opts) -- close current tab
vim.keymap.set('n', '<leader>tn', ':tabn<CR>', opts) --  go to next tab
vim.keymap.set('n', '<leader>tp', ':tabp<CR>', opts) --  go to previous tab

-- Toggle line wrapping
vim.keymap.set('n', '<leader>lw', '<cmd>set wrap!<CR>', opts)

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
