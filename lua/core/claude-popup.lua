-- Claude Code in a tmux popup, per project, driven from Neovim. Needs Neovim inside tmux.
--
-- Every Claude lives in a tmux window of its own ("stash window", named ·claude:<project>#<n>) in the
-- session you work in, running `claude` inside your shell — so after /exit you land on a shell
-- prompt and can start `claude --resume`, `claude -c`, … in the same place. Space a c shows it in a
-- 90% popup over Neovim; inside it is a normal tmux pane: Ctrl+b [ scrolls, Ctrl+b d hides the
-- popup (Claude keeps running).
--
-- How the popup shows a window without disturbing your own view: a throwaway session
-- (claude-view-*) gets that one window linked into it, the popup attaches to it, and the session
-- dies when the popup closes. A tmux popup shows a whole window, so a Claude pane that shares a
-- window with other panes is broken out into its own window first — except one sitting next to
-- Neovim in this window, or in any other window of yours with several panes: those are left
-- alone and Space a s just jumps to them.
--
-- Which Claude belongs to which project: any interactive `claude` process (found through ps, since
-- tmux names its pane after the version, e.g. 2.1.287) whose pane's working folder is the folder
-- Neovim has open, or below it. Stash windows carry @claude_project / @claude_n, so a stash window
-- whose Claude has exited to the shell is still listed. "The Claude in use" is remembered per tmux
-- window and project (@claude_last_<hash> on the window holding Neovim) — sends go there.
--
-- Keys: Space a c / s / t / f / v — see CHEATSHEET.md, "AI — Claude in a tmux popup".
local M = {}

local WARN = vim.log.levels.WARN

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = 'Claude' })
end

local function tmux(args, stdin)
  local r = vim.system(vim.list_extend({ 'tmux' }, args), { text = true, stdin = stdin }):wait()
  if r.code ~= 0 then
    return nil, vim.trim(r.stderr or '')
  end
  return vim.trim(r.stdout or '')
end

local function root()
  return vim.fs.normalize(vim.fn.getcwd())
end

local function inside(path, dir)
  return path == dir or vim.startswith(path, dir .. '/')
end

local function last_option(dir)
  return '@claude_last_' .. vim.fn.sha256(dir):sub(1, 12)
end

-- `claude` started to chat with, not `claude -p …` in a script, nor its background daemons.
local NOT_CHAT = { daemon = true, mcp = true, config = true, doctor = true, update = true, install = true, plugin = true }
local function interactive_claude(args)
  local words = vim.split(args, '%s+', { trimempty = true })
  if not words[1] or vim.fs.basename(words[1]) ~= 'claude' or NOT_CHAT[words[2] or ''] then
    return false
  end
  for _, w in ipairs(words) do
    if w == '-p' or w == '--print' or w:match '^%-%-bg%-' then
      return false
    end
  end
  return true
end

-- Set of pids that are an interactive claude or one of its ancestors: a pane holds a Claude when
-- its pane_pid (usually the shell) is in here.
local function claude_ancestors()
  local out = vim.system({ 'ps', '-A', '-o', 'pid=,ppid=,args=' }, { text = true }):wait().stdout or ''
  local parent, found = {}, {}
  for line in out:gmatch '[^\n]+' do
    local pid, ppid, args = line:match '^%s*(%d+)%s+(%d+)%s+(.*)$'
    if pid then
      parent[pid] = ppid
      if interactive_claude(args) then
        found[#found + 1] = pid
      end
    end
  end
  local set = {}
  for _, pid in ipairs(found) do
    while pid and pid ~= '0' and not set[pid] do
      set[pid] = true
      pid = parent[pid]
    end
  end
  return set
end

local FORMAT = table.concat({
  '#{pane_id}',
  '#{pane_pid}',
  '#{session_id}',
  '#{window_id}',
  '#{window_name}',
  '#{window_panes}',
  '#{pane_current_path}',
  '#{@claude_project}',
  '#{@claude_n}',
  '#{@claude_stash}',
}, '\t')

-- Every Claude of project `dir` (plus its stash windows sitting at a shell prompt), lowest #n first.
local function list(dir)
  local here = tmux { 'display-message', '-p', '-t', vim.env.TMUX_PANE, '#{window_id}' }
  local claude = claude_ancestors()
  local items = {}
  for line in (tmux { 'list-panes', '-a', '-F', FORMAT } or ''):gmatch '[^\n]+' do
    local f = vim.split(line, '\t')
    local e = {
      pane = f[1],
      session = f[3],
      window = f[4],
      wname = f[5],
      npanes = tonumber(f[6]) or 1,
      cwd = f[7],
      project = f[8],
      n = tonumber(f[9]),
      stash = f[10] == '1',
      claude = claude[f[2]] == true,
    }
    if (e.claude and inside(e.cwd, dir)) or (e.project == dir and e.stash) then
      e.side = e.window == here
      items[#items + 1] = e
    end
  end
  table.sort(items, function(a, b)
    return (a.n or math.huge) < (b.n or math.huge)
  end)
  return items, here
end

local function next_n(dir)
  local max = 0
  for line in (tmux { 'list-panes', '-a', '-F', '#{@claude_project}\t#{@claude_n}' } or ''):gmatch '[^\n]+' do
    local project, n = line:match '^(.-)\t(%d+)$'
    if project == dir then
      max = math.max(max, tonumber(n))
    end
  end
  return max + 1
end

local function stash_name(dir, n)
  return ('·claude:%s#%d'):format(vim.fs.basename(dir), n)
end

-- Make e's window a stash window of `dir`: label the pane, name the window.
local function adopt(e, dir)
  e.n = e.n and e.project == dir and e.n or next_n(dir)
  e.project = dir
  tmux { 'set-option', '-p', '-t', e.pane, '@claude_project', dir }
  tmux { 'set-option', '-p', '-t', e.pane, '@claude_n', tostring(e.n) }
  tmux { 'set-option', '-w', '-t', e.window, '@claude_stash', '1' }
  tmux { 'set-option', '-w', '-t', e.window, 'automatic-rename', 'off' }
  tmux { 'rename-window', '-t', e.window, stash_name(dir, e.n) }
end

local function remember(dir, here, pane)
  tmux { 'set-option', '-w', '-t', here, last_option(dir), pane }
end

-- Show e's window in a 90% popup over this client.
local function popup(e)
  for line in (tmux { 'list-sessions', '-F', '#{session_name}\t#{session_attached}' } or ''):gmatch '[^\n]+' do
    local name, attached = line:match '^(claude%-view%-.-)\t(%d+)$'
    if name and attached == '0' then -- left over from a popup that never attached
      tmux { 'kill-session', '-t', '=' .. name }
    end
  end
  local view = ('claude-view-%d-%d'):format(vim.fn.getpid(), vim.uv.hrtime() % 1e9)
  local tmp = tmux { 'new-session', '-d', '-s', view, '-P', '-F', '#{window_id}' }
  if not tmp then
    return notify('Could not create the popup session', WARN)
  end
  tmux { 'link-window', '-d', '-s', e.window, '-t', view .. ':' }
  tmux { 'kill-window', '-t', tmp }
  tmux { 'set-option', '-t', view, 'status', 'off' }
  -- if the Claude window goes away while shown, close the popup instead of jumping to another session
  tmux { 'set-option', '-t', view, 'detach-on-destroy', 'on' }
  -- where Shift+←/→ pressed inside the popup should move (tmux-config's claude-window.sh)
  local origin = tmux { 'display-message', '-p', '-t', vim.env.TMUX_PANE, '#{session_id}' }
  tmux { 'set-option', '-t', view, '@claude_origin', origin }
  tmux { 'select-pane', '-t', e.pane }
  local title = (' Claude · %s #%s '):format(vim.fs.basename(e.project ~= '' and e.project or e.cwd), e.n or '?')
  -- -S: same server as this Neovim's (TMUX is unset inside to avoid the "nested" refusal)
  local socket = vim.fn.shellescape(vim.env.TMUX:match '^[^,]+')
  local attach = ('env -u TMUX tmux -S %s attach-session -t %s \\; set-option -t %s destroy-unattached on'):format(socket, view, view)
  -- not waited on: display-popup only returns once the popup is closed
  vim.system { 'tmux', 'display-popup', '-E', '-w', '90%', '-h', '90%', '-b', 'rounded', '-T', title, '-t', vim.env.TMUX_PANE, attach }
end

-- Bring Claude e up: popup, or a jump for one that shares a window with other panes.
local function open(e, dir, here)
  remember(dir, here, e.pane)
  if e.side then
    return tmux { 'select-pane', '-t', e.pane }
  end
  if e.npanes > 1 and not e.stash then -- one of your own multi-pane windows: leave it be, go there
    return tmux { 'switch-client', '-t', e.pane }
  end
  if e.npanes > 1 then -- a stash window split by hand: give this Claude a window of its own
    local old = e.window
    e.window = tmux { 'break-pane', '-d', '-s', e.pane, '-t', e.session .. ':', '-P', '-F', '#{window_id}' }
    e.npanes = 1
    if e.project == dir then -- its Claude moved out: what is left is an ordinary window again
      tmux { 'set-option', '-w', '-u', '-t', old, '@claude_stash' }
      tmux { 'set-option', '-w', '-t', old, 'automatic-rename', 'on' }
    end
    e.stash = false -- the new window still has to be named and marked
  end
  if e.project ~= dir or not e.stash then
    adopt(e, dir)
  end
  popup(e)
end

-- Start a new Claude for `dir` in a stash window. `args` is one of the fixed strings below.
local function create(dir, here, args)
  local session = tmux { 'display-message', '-p', '-t', vim.env.TMUX_PANE, '#{session_id}' }
  local n = next_n(dir)
  local shell = vim.env.SHELL or 'sh'
  local cmd = ('%s -ic %s'):format(shell, vim.fn.shellescape(('claude%s; exec %s -i'):format(args, shell)))
  local out = tmux { 'new-window', '-d', '-t', session .. ':', '-c', dir, '-P', '-F', '#{pane_id}\t#{window_id}', cmd }
  if not out then
    return notify('Could not start Claude', WARN)
  end
  local pane, window = out:match '^(.-)\t(.*)$'
  local e = { pane = pane, window = window, session = session, npanes = 1, cwd = dir, n = n, stash = true, claude = true }
  adopt(e, dir)
  open(e, dir, here)
end

local function ready()
  if not vim.env.TMUX or not vim.env.TMUX_PANE then
    notify('Neovim is not running inside tmux', WARN)
    return false
  end
  return true
end

-- The Claude in use for `dir` in this window: the remembered one, else the first that still runs.
local function current(dir, items, here, need_claude)
  local last = tmux { 'show-options', '-w', '-q', '-v', '-t', here, last_option(dir) }
  local fallback
  for _, e in ipairs(items) do
    if not need_claude or e.claude then
      if e.pane == last then
        return e
      end
      fallback = fallback or e
    end
  end
  return fallback
end

function M.toggle()
  if not ready() then
    return
  end
  local dir = root()
  local items, here = list(dir)
  local e = current(dir, items, here, false)
  if e then
    open(e, dir, here)
  else
    create(dir, here, '')
  end
end

function M.select()
  if not ready() then
    return
  end
  local dir = root()
  local items, here = list(dir)
  local last = (current(dir, items, here, false) or {}).pane
  local choices = {}
  for _, e in ipairs(items) do
    local state = e.claude and 'claude' or 'shell'
    local label
    if e.side then
      label = ('↪ pane next to Neovim (%s) — jump to it'):format(e.pane)
    elseif e.npanes > 1 and not e.stash then
      label = ('↪ window "%s" (%s) — jump to it'):format(e.wname, e.pane)
    elseif e.project == dir and e.npanes == 1 then
      label = ('#%s  %s  [%s]'):format(e.n, e.wname, state)
    elseif e.npanes > 1 then
      label = ('pane %s, split inside %s — moves to its own window, opens here'):format(e.pane, e.wname)
    else
      label = ('window "%s" (%s) — becomes a ·claude window, opens here'):format(e.wname, e.pane)
    end
    if e.pane == last then
      label = label .. '  (in use)'
    end
    choices[#choices + 1] = { label = label, entry = e }
  end
  vim.list_extend(choices, {
    { label = '+ New Claude', args = '' },
    { label = '+ Continue the latest conversation (claude --continue)', args = ' --continue' },
    { label = '+ Pick an old conversation (claude --resume)', args = ' --resume' },
  })
  pcall(require, 'telescope') -- loads telescope-ui-select, so vim.ui.select gets a proper picker
  vim.ui.select(choices, {
    prompt = 'Claude · ' .. vim.fs.basename(dir),
    format_item = function(c)
      return c.label
    end,
  }, function(c)
    if not c then
      return
    end
    if c.entry then
      open(c.entry, dir, here)
    else
      create(dir, here, c.args)
    end
  end)
end

-- Paste text into the Claude in use (not submitted), then bring that Claude up.
-- `build(e)` makes the text, given the target, so paths can be relative to that Claude's folder.
local function send(build)
  if not ready() then
    return
  end
  local dir = root()
  local items, here = list(dir)
  local e = current(dir, items, here, true)
  if not e then
    return notify('No Claude running for this project — Space a c (or Space a s) starts one', WARN)
  end
  local text = build(e)
  if not text then
    return
  end
  tmux({ 'load-buffer', '-b', 'claude-send', '-' }, text)
  tmux { 'paste-buffer', '-p', '-d', '-b', 'claude-send', '-t', e.pane } -- -p: bracketed, so lines are not sent one by one
  open(e, dir, here)
end

-- "@path#L10-20 ": what Claude Code reads as "these lines of this file". Saves first, since
-- Claude reads the file from disk.
local function mention(e, l1, l2)
  local file = vim.api.nvim_buf_get_name(0)
  if file == '' or vim.bo.buftype ~= '' then
    notify('This buffer is not a file', WARN)
    return nil
  end
  if vim.bo.modified then
    vim.cmd 'silent update'
  end
  -- ponytail: a path with spaces is sent as is; Claude may not resolve it
  local text = '@' .. (vim.fs.relpath(e.cwd, file) or file)
  if l1 then
    text = text .. '#L' .. l1 .. (l2 and l2 ~= l1 and ('-' .. l2) or '')
  end
  return text .. ' '
end

local function leave_visual()
  vim.api.nvim_feedkeys(vim.keycode '<Esc>', 'nx', false)
end

function M.send_line()
  local line = vim.fn.line '.'
  send(function(e)
    return mention(e, line)
  end)
end

function M.send_range()
  local a, b = vim.fn.line 'v', vim.fn.line '.'
  leave_visual()
  send(function(e)
    return mention(e, math.min(a, b), math.max(a, b))
  end)
end

function M.send_file()
  send(function(e)
    return mention(e)
  end)
end

function M.send_text()
  local lines = vim.fn.getregion(vim.fn.getpos 'v', vim.fn.getpos '.', { type = vim.fn.mode() })
  leave_visual()
  send(function()
    return table.concat(lines, '\n') .. '\n' -- so what you type next starts on its own line
  end)
end

local map = vim.keymap.set
map('n', '<leader>ac', M.toggle, { desc = 'Claude: open the one in use (popup)' })
map('n', '<leader>as', M.select, { desc = 'Claude: pick / start one for this project' })
map('n', '<leader>at', M.send_line, { desc = 'Claude: send this line (@file#L)' })
map('x', '<leader>at', M.send_range, { desc = 'Claude: send these lines (@file#L-L)' })
map('n', '<leader>af', M.send_file, { desc = 'Claude: send this file (@file)' })
map('x', '<leader>av', M.send_text, { desc = 'Claude: send the selected text' })

return M
