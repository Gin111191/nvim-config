vim.wo.number = true -- Make line numbers default (default: false)
vim.o.relativenumber = true -- Set relative numbered lines (default: false)
vim.o.clipboard = 'unnamedplus' -- Sync clipboard between OS and Neovim. (default: '')
vim.o.wrap = false -- Display lines as one long line (default: true)
vim.o.linebreak = true -- Companion to wrap, don't split words (default: false)
vim.o.mouse = 'a' -- Enable mouse mode (default: '')
vim.o.autoindent = true -- Copy indent from current line when starting new one (default: true)
vim.o.ignorecase = true -- Case-insensitive searching UNLESS \C or capital in search (default: false)
vim.o.smartcase = true -- Smart case (default: false)
vim.o.shiftwidth = 4 -- The number of spaces inserted for each indentation (default: 8)
vim.o.tabstop = 4 -- Insert n spaces for a tab (default: 8)
vim.o.softtabstop = 4 -- Number of spaces that a tab counts for while performing editing operations (default: 0)
vim.o.expandtab = true -- Convert tabs to spaces (default: false)
vim.o.scrolloff = 4 -- Minimal number of screen lines to keep above and below the cursor (default: 0)
vim.o.sidescrolloff = 8 -- Minimal number of screen columns either side of cursor if wrap is `false` (default: 0)
vim.o.cursorline = true -- Highlight the current line (default: false)
vim.o.splitbelow = true -- Force all horizontal splits to go below current window (default: false)
vim.o.splitright = true -- Force all vertical splits to go to the right of current window (default: false)
vim.o.hlsearch = false -- Set highlight on search (default: true)
vim.o.showmode = false -- We don't need to see things like -- INSERT -- anymore (default: true)
-- 'termguicolors' is deliberately NOT set here. Neovim asks the terminal itself and
-- turns it on when the answer is yes (:h 'termguicolors'); setting it by hand disables
-- that. Forcing it on was the bug: Terminal.app has no 24-bit colour, so it was being
-- sent codes it cannot read and showed a single colour. When the answer is no, the
-- 256-colour numbers in lua/plugins/colortheme.lua take over.
-- Force it by hand if ever needed: export COLORTERM=truecolor
vim.o.whichwrap = 'bs<>[]hl' -- Which "horizontal" keys are allowed to travel to prev/next line (default: 'b,s')
vim.o.numberwidth = 4 -- Set number column width to 2 {default 4} (default: 4)
vim.o.swapfile = false -- Creates a swapfile (default: true)
vim.o.smartindent = true -- Make indenting smarter again (default: false)
vim.o.showtabline = 2 -- Always show tabs (default: 1)
vim.o.backspace = 'indent,eol,start' -- Allow backspace on (default: 'indent,eol,start')
vim.o.pumheight = 10 -- Pop up menu height (default: 0)
vim.o.conceallevel = 0 -- So that `` is visible in markdown files (default: 1)
vim.wo.signcolumn = 'yes' -- Keep signcolumn on by default (default: 'auto')
vim.o.fileencoding = 'utf-8' -- The encoding written to a file (default: 'utf-8')
vim.o.cmdheight = 1 -- More space in the Neovim command line for displaying messages (default: 1)
vim.o.breakindent = true -- Enable break indent (default: false)
vim.o.updatetime = 250 -- Decrease update time (default: 4000)
vim.o.timeoutlen = 300 -- Time to wait for a mapped sequence to complete (in milliseconds) (default: 1000)
vim.o.backup = false -- Creates a backup file (default: false)
vim.o.writebackup = false -- If a file is being edited by another program (or was written to file while editing with another program), it is not allowed to be edited (default: true)
vim.o.undofile = true -- Save undo history (default: false)
vim.o.completeopt = 'menuone,noselect' -- Set completeopt to have a better completion experience (default: 'menu,preview')
vim.opt.shortmess:append 'c' -- Don't give |ins-completion-menu| messages (default: does not include 'c')
vim.opt.iskeyword:append '-' -- Hyphenated words recognized by searches (default: does not include '-')
vim.opt.formatoptions:remove { 'c', 'r', 'o' } -- Don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode. (default: 'croql')
vim.opt.runtimepath:remove '/usr/share/vim/vimfiles' -- Separate Vim plugins from Neovim in case Vim still in use (default: includes this path if Vim is installed)
vim.o.foldlevelstart = 99 -- Open files with every fold expanded; treesitter.lua turns folding on but never sets foldlevel, so Neovim's default of 0 (everything closed) applied (default: -1)

-- 'autoread' only re-reads a changed file when something runs :checktime, and Neovim runs it by
-- itself only on FocusGained. Anything else that writes a file while it is open here (Claude over
-- the IDE connection, a formatter, git) therefore shows up late. Run it on the events below too.
-- CursorHold never fires in terminal-mode, so the Claude split would starve the autocmd; the 1s
-- timer covers the case where the cursor is sitting in that split while the file changes.
local checktime_group = vim.api.nvim_create_augroup('AutoChecktime', { clear = true })
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'CursorHoldI' }, {
  group = checktime_group,
  desc = 'Re-read files that changed on disk',
  callback = function()
    if vim.fn.mode() ~= 'c' then
      vim.cmd 'checktime'
    end
  end,
})
local checktime_timer = (vim.uv or vim.loop).new_timer()
checktime_timer:start(1000, 1000, vim.schedule_wrap(function()
  if vim.fn.mode() ~= 'c' then
    vim.cmd 'silent! checktime'
  end
end))

-- When a file is re-read because something else changed it (Claude, a formatter, git), show what
-- changed: the new lines flash, and a side-by-side diff opens (old text left, new text right) in
-- the window showing the file. Otherwise the buffer changes silently and there is nothing to look
-- at. Needs the autoread/checktime block above. Turn the split off with
-- `vim.g.external_change_split = false`; close it with :q on the left half (diff mode ends too).
-- A snapshot of each file's lines is kept because by the time FileChangedShellPost fires the old
-- text is already gone.
local change_ns = vim.api.nvim_create_namespace 'external_change'
local function snapshot(buf, only_if_missing)
  if vim.bo[buf].buftype ~= '' or (only_if_missing and vim.b[buf].snapshot) then
    return
  end
  vim.b[buf].snapshot = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end
vim.api.nvim_create_autocmd('BufWritePost', {
  group = checktime_group,
  callback = function(ev)
    snapshot(ev.buf)
  end,
})
-- Only when missing: an autoread reload fires BufReadPost BEFORE FileChangedShellPost, so
-- overwriting here would replace the old text with the new and the diff would always be empty.
-- ponytail: a manual :e! therefore leaves a stale snapshot, so the next outside change may
-- show a few extra lines; refresh it there if that ever matters.
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufEnter' }, {
  group = checktime_group,
  callback = function(ev)
    snapshot(ev.buf, true)
  end,
})

-- Old text in a scratch buffer on the left of `win`, both sides in diff mode. A second change
-- reuses the same scratch buffer (it then shows the state just before the latest change).
local function show_split(buf, win, old)
  local ref = vim.b[buf].change_ref
  if ref and vim.api.nvim_buf_is_valid(ref) and #vim.fn.win_findbuf(ref) > 0 then
    vim.bo[ref].modifiable = true
    vim.api.nvim_buf_set_lines(ref, 0, -1, false, old)
    vim.bo[ref].modifiable = false
    vim.cmd 'diffupdate'
    return
  end
  vim.api.nvim_win_call(win, function()
    vim.cmd 'diffthis'
    vim.cmd 'leftabove vsplit'
    local sb = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(sb, 0, -1, false, old)
    vim.bo[sb].filetype = vim.bo[buf].filetype
    vim.bo[sb].bufhidden = 'wipe'
    vim.bo[sb].modifiable = false
    pcall(vim.api.nvim_buf_set_name, sb, 'BEFORE ' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(buf), ':t'))
    vim.api.nvim_win_set_buf(0, sb)
    vim.cmd 'diffthis'
    vim.b[buf].change_ref = sb
    vim.api.nvim_create_autocmd('BufWinLeave', {
      buffer = sb,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_call(win, function()
            vim.cmd 'diffoff'
          end)
        end
      end,
    })
  end)
end

vim.api.nvim_create_autocmd('FileChangedShellPost', {
  group = checktime_group,
  desc = 'Show what an outside change touched',
  callback = function(ev)
    local buf, old = ev.buf, vim.b[ev.buf].snapshot
    local new = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    snapshot(buf)
    if not old then
      return
    end
    local hunks = vim.diff(table.concat(old, '\n') .. '\n', table.concat(new, '\n') .. '\n', { result_type = 'indices' })
    if #hunks == 0 then
      return
    end
    vim.api.nvim_buf_clear_namespace(buf, change_ns, 0, -1)
    for _, h in ipairs(hunks) do
      local first, count = h[3], h[4]
      for l = first, first + math.max(count, 1) - 1 do
        if l >= 1 and l <= #new then
          vim.api.nvim_buf_set_extmark(buf, change_ns, l - 1, 0, { line_hl_group = 'DiffAdd', priority = 200 })
        end
      end
    end
    local target = math.min(math.max(hunks[1][3], 1), #new)
    local here = vim.api.nvim_get_current_win()
    local shown = false
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if win ~= here then
        if vim.g.external_change_split ~= false and not shown then
          shown = true
          show_split(buf, win, old)
        end
        vim.api.nvim_win_set_cursor(win, { target, 0 })
        vim.api.nvim_win_call(win, function()
          vim.cmd 'normal! zz'
        end)
      end
    end
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_clear_namespace(buf, change_ns, 0, -1)
      end
    end, 5000)
  end,
})
