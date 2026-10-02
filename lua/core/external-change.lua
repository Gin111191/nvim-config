-- What to do when a file is re-read because something else changed it (Claude, a formatter, git):
-- show what changed, so an outside edit is not silent. Needs the autoread/checktime block in
-- options.lua (that is what triggers the re-read).
--
--   mode 'highlight' (default): changed/added lines get a green background and a sign, removed or
--     replaced lines show above as red virtual lines. One column, nothing opens. Stays until the
--     file is saved, changes again, or :ChangeClear.
--   mode 'split': a side-by-side diff opens in the window showing the file (old text left, new
--     right). At most vim.g.external_change_max_splits (default 1) are open at once; a newer one
--     closes the oldest, so editing many files in a row does not fill the screen with columns.
--
-- Switch with :ChangeMode highlight|split. Either mode also scrolls any window showing the file
-- (other than the one you are in) to the first change.
--
-- A snapshot of each file's lines is kept because by the time FileChangedShellPost fires the old
-- text is already gone.
local M = {}

local group = vim.api.nvim_create_augroup('AutoChecktime', { clear = false })
local ns = vim.api.nvim_create_namespace 'external_change'
local splits = {} -- { buf = real buffer, ref = scratch "BEFORE" buffer, win = real window }

local function snapshot(buf, only_if_missing)
  if vim.bo[buf].buftype ~= '' or (only_if_missing and vim.b[buf].snapshot) then
    return
  end
  vim.b[buf].snapshot = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

vim.api.nvim_create_autocmd('BufWritePost', {
  group = group,
  callback = function(ev)
    snapshot(ev.buf)
    vim.api.nvim_buf_clear_namespace(ev.buf, ns, 0, -1)
    vim.b[ev.buf].opened_by_claude = nil -- you saved it yourself: it is yours now, never auto-closed
  end,
})
-- Only when missing: an autoread reload fires BufReadPost BEFORE FileChangedShellPost, so
-- overwriting here would replace the old text with the new and the diff would always be empty.
-- ponytail: a manual :e! therefore leaves a stale snapshot, so the next outside change may
-- show a few extra lines; refresh it there if that ever matters.
vim.api.nvim_create_autocmd({ 'BufReadPost', 'BufEnter' }, {
  group = group,
  callback = function(ev)
    snapshot(ev.buf, true)
  end,
})

local function mark(buf, old, new, hunks)
  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(hunks) do
    local sa, ca, sb, cb = h[1], h[2], h[3], h[4]
    for l = sb, sb + cb - 1 do
      if l >= 1 and l <= #new then
        vim.api.nvim_buf_set_extmark(buf, ns, l - 1, 0, { line_hl_group = 'DiffAdd', sign_text = '▎', sign_hl_group = 'DiffAdd', priority = 200 })
      end
    end
    if ca > 0 and #new > 0 then
      local virt = {}
      for i = sa, sa + ca - 1 do
        virt[#virt + 1] = { { '- ' .. old[i], 'DiffDelete' } }
      end
      -- a replaced/added hunk shows its old text above the new lines; a pure deletion has no new
      -- line of its own, so it hangs below the line before it (or above line 1)
      local above = cb > 0 or sb == 0
      local row = math.min(math.max(cb > 0 and sb - 1 or sb - 1, 0), #new - 1)
      vim.api.nvim_buf_set_extmark(buf, ns, row, 0, { virt_lines = virt, virt_lines_above = above })
    end
  end
end

local function prune()
  splits = vim.tbl_filter(function(s)
    return vim.api.nvim_buf_is_valid(s.ref) and #vim.fn.win_findbuf(s.ref) > 0
  end, splits)
end

local function close_split(s)
  for _, w in ipairs(vim.fn.win_findbuf(s.ref)) do
    pcall(vim.api.nvim_win_close, w, true)
  end
  if vim.api.nvim_win_is_valid(s.win) then
    pcall(vim.api.nvim_win_call, s.win, function()
      vim.cmd 'diffoff'
    end)
  end
end

-- Old text in a scratch buffer on the left of `win`, both sides in diff mode.
local function show_split(buf, win, old)
  prune()
  for _, s in ipairs(splits) do
    if s.buf == buf then -- same file again: show the state just before the latest change
      vim.bo[s.ref].modifiable = true
      vim.api.nvim_buf_set_lines(s.ref, 0, -1, false, old)
      vim.bo[s.ref].modifiable = false
      vim.cmd 'diffupdate'
      return
    end
  end
  while #splits >= (vim.g.external_change_max_splits or 1) do
    close_split(table.remove(splits, 1))
  end
  if not vim.api.nvim_win_is_valid(win) then
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
    splits[#splits + 1] = { buf = buf, ref = sb, win = win }
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
  group = group,
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
    local split_mode = vim.g.external_change_mode == 'split'
    if not split_mode then
      mark(buf, old, new, hunks)
    end
    local target = math.min(math.max(hunks[1][3], 1), #new)
    local here = vim.api.nvim_get_current_win()
    local shown = false
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      if win ~= here then
        if split_mode and not shown then
          shown = true
          show_split(buf, win, old)
        end
        vim.api.nvim_win_set_cursor(win, { target, 0 })
        vim.api.nvim_win_call(win, function()
          vim.cmd 'normal! zz'
        end)
      end
    end
  end,
})

-- Open `path` for the user without stealing focus: in the window already showing it, else in the
-- first ordinary code window, else in a new split on the left. Never in a terminal (the Claude
-- split) — an :edit there replaced the chat, which is the bug this guards against. Called by
-- ~/.claude/hooks/nvim-open.sh over the RPC socket.
function M.open(path, line)
  path = vim.fn.fnamemodify(path, ':p')
  local buf = vim.fn.bufnr(path)
  local was_loaded = buf > 0 and vim.api.nvim_buf_is_loaded(buf)
  local win = buf > 0 and vim.fn.win_findbuf(buf)[1] or nil
  if not win then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local b = vim.api.nvim_win_get_buf(w)
      if vim.api.nvim_win_get_config(w).relative == '' and vim.bo[b].buftype == '' and not vim.wo[w].diff then
        win = w
        break
      end
    end
    if not win then
      win = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), false, { split = 'left', win = -1 })
    end
    local ok = pcall(vim.api.nvim_win_call, win, function()
      vim.cmd('edit ' .. vim.fn.fnameescape(path))
    end)
    if not ok then -- the window holds unsaved changes: leave them alone, use a new split
      win = vim.api.nvim_open_win(vim.api.nvim_get_current_buf(), false, { split = 'left', win = -1 })
      vim.api.nvim_win_call(win, function()
        vim.cmd('edit ' .. vim.fn.fnameescape(path))
      end)
    end
  end
  if not was_loaded then -- a buffer you already had open is yours: only ones opened here get cleaned up
    vim.b[vim.fn.bufnr(path)].opened_by_claude = true
  end
  if line then
    vim.api.nvim_win_set_cursor(win, { math.max(tonumber(line) or 1, 1), 0 })
    vim.api.nvim_win_call(win, function()
      vim.cmd 'normal! zz'
    end)
  end
  return win
end

-- Close the buffers M.open loaded, once Claude is done (the Stop hook calls this over RPC).
-- Skipped: a buffer with unsaved changes, one you saved yourself (flag cleared in BufWritePost),
-- and one still showing in a window — the last file Claude touched stays on screen until the next
-- one replaces it.
-- ponytail: a buffer left showing survives this run and is only closed by a later one.
function M.close_opened()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.b[b].opened_by_claude and not vim.bo[b].modified and #vim.fn.win_findbuf(b) == 0 then
      pcall(vim.api.nvim_buf_delete, b, {})
    end
  end
end

function M.checktime()
  vim.cmd 'silent! checktime'
end

function M.clear()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
  end
  prune()
  for _, s in ipairs(splits) do
    close_split(s)
  end
  splits = {}
end

vim.api.nvim_create_user_command('ChangeClear', M.clear, { desc = 'Clear change highlights and close change diff splits' })
vim.api.nvim_create_user_command('ChangeMode', function(o)
  vim.g.external_change_mode = o.args
  M.clear()
end, {
  nargs = 1,
  complete = function()
    return { 'highlight', 'split' }
  end,
  desc = 'How an outside change is shown: highlight (one column) or split (side-by-side diff)',
})

vim.g.external_change_mode = vim.g.external_change_mode or 'highlight'

return M
