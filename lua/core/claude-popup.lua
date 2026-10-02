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

-- pid → the interactive claude it is, or is an ancestor of: a pane holds a Claude when its
-- pane_pid (usually the shell) is in here, and the value says which claude process.
local function claude_owners()
  local out = vim.system({ 'ps', '-A', '-o', 'pid=,ppid=,args=' }, { text = true }):wait().stdout or ''
  local parent, found, attach = {}, {}, {}
  for line in out:gmatch '[^\n]+' do
    local pid, ppid, args = line:match '^%s*(%d+)%s+(%d+)%s+(.*)$'
    if pid then
      parent[pid] = ppid
      if interactive_claude(args) then
        found[#found + 1] = pid
        attach[pid] = args:match '%sattach%s+([%w%-]+)' -- a window onto a background session
      end
    end
  end
  local owner = {}
  for _, claude in ipairs(found) do
    local pid = claude
    while pid and pid ~= '0' and not owner[pid] do
      owner[pid] = claude
      pid = parent[pid]
    end
  end
  return owner, attach
end

local claude_dir = vim.env.CLAUDE_CONFIG_DIR or (vim.env.HOME .. '/.claude')

-- The conversation a running claude has open: Claude Code writes sessions/<pid>.json for each one.
local function conversation(pid)
  local ok, data = pcall(function()
    return vim.json.decode(table.concat(vim.fn.readfile(('%s/sessions/%s.json'):format(claude_dir, pid)), '\n'))
  end)
  return ok and type(data) == 'table' and data.sessionId or nil
end

-- Background sessions (`claude --bg`, ones started from Claude's ← agents view) of `dir`. They run
-- in Claude Code's daemon, not in any tmux pane, so the only way in is `claude attach <id>`.
local function background(dir)
  local out = vim.system({ 'claude', 'agents', '--json' }, { text = true }):wait()
  local ok, sessions = pcall(vim.json.decode, out.stdout or '')
  local ret = {}
  if out.code ~= 0 or not ok or type(sessions) ~= 'table' then
    return ret
  end
  for _, s in ipairs(sessions) do
    if s.kind == 'background' and type(s.id) == 'string' and s.id:match '^[%w%-]+$' -- goes into a shell command
      and type(s.cwd) == 'string' and inside(vim.fs.normalize(s.cwd), dir) then
      ret[#ret + 1] = s
    end
  end
  return ret
end

-- The conversation `claude --continue` started in `dir` opens: the newest transcript Claude Code
-- keeps for that folder, in projects/<the path with every non-alphanumeric character as '-'>.
local function latest_conversation(dir)
  local newest, time = nil, -1
  for _, file in ipairs(vim.fn.glob(('%s/projects/%s/*.jsonl'):format(claude_dir, (dir:gsub('[^%w]', '-'))), false, true)) do
    local stat = vim.uv.fs_stat(file)
    if stat and stat.mtime.sec > time then
      newest, time = vim.fn.fnamemodify(file, ':t:r'), stat.mtime.sec
    end
  end
  return newest
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
  '#{session_name}',
}, '\t')

-- Every Claude of project `dir` (plus its stash windows sitting at a shell prompt), lowest #n first.
local function list(dir)
  local here = tmux { 'display-message', '-p', '-t', vim.env.TMUX_PANE, '#{window_id}' }
  local owner, attach = claude_owners()
  local items, seen = {}, {}
  for line in (tmux { 'list-panes', '-a', '-F', FORMAT } or ''):gmatch '[^\n]+' do
    local f = vim.split(line, '\t')
    -- A window shown in a popup is also linked into its claude-view-* session, so list-panes -a
    -- reports its pane twice; keep the copy in the session it really belongs to.
    if seen[f[1]] or vim.startswith(f[11] or '', 'claude-view-') then
      goto continue
    end
    seen[f[1]] = true
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
      claude = owner[f[2]] ~= nil,
    }
    e.conversation = e.claude and conversation(owner[f[2]]) or nil
    e.attach = e.claude and attach[owner[f[2]]] or nil
    if (e.claude and inside(e.cwd, dir)) or (e.project == dir and e.stash) then
      e.side = e.window == here
      items[#items + 1] = e
    end
    ::continue::
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

-- Start a new Claude for `dir` in a stash window. `args` is one of the fixed strings in M.select,
-- or " attach <id>" / " --resume <id>" with the id checked first (background(), past()).
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

-- Past conversations of `dir`, newest first, from Claude Code's transcripts in projects/<dir>/:
-- named by their last custom-title / ai-title record. Left out: ones Claude continued under a
-- newer id (a "continued-in" record — the newer one is listed instead) and near-empty stubs.
local function past(dir)
  local folder = ('%s/projects/%s'):format(claude_dir, (dir:gsub('[^%w]', '-')))
  local ok, run = pcall(vim.system, {
    'rg', '--no-config', '--with-filename', '-N', '--max-depth', '1', '-g', '*.jsonl',
    '^\\{"type":"(ai-title|custom-title|continued-in)"', folder,
  }, { text = true })
  local out = ok and run:wait().stdout or '' -- rg reads 850 MB of transcripts in ~25 ms
  local title, custom, continued = {}, {}, {}
  for line in out:gmatch '[^\n]+' do
    local file, json = line:match '^(.-%.jsonl):(.*)$'
    local decoded, rec = pcall(vim.json.decode, json or '')
    if decoded and type(rec) == 'table' then
      local id = vim.fs.basename(file):sub(1, -7)
      if rec.type == 'continued-in' then
        continued[id] = true
      elseif rec.type == 'custom-title' and type(rec.customTitle) == 'string' then
        custom[id] = rec.customTitle
      elseif rec.type == 'ai-title' and type(rec.aiTitle) == 'string' then
        title[id] = rec.aiTitle
      end
    end
  end
  local ret = {}
  for _, file in ipairs(vim.fn.glob(folder .. '/*.jsonl', false, true)) do
    local id = vim.fs.basename(file):sub(1, -7)
    local stat = vim.uv.fs_stat(file)
    -- ponytail: under 2 kB is a placeholder with no conversation in it; raise it if real ones go missing
    if stat and stat.size > 2048 and not continued[id] and id:match '^[%x%-]+$' then -- id goes into a shell command
      ret[#ret + 1] = { id = id, title = custom[id] or title[id] or id:sub(1, 8), mtime = stat.mtime.sec }
    end
  end
  table.sort(ret, function(a, b)
    return a.mtime > b.mtime
  end)
  return ret
end

local function ref(e, dir)
  return e.n and e.project == dir and ('#' .. e.n) or e.pane
end

-- Pick a past conversation in Neovim; nothing is started until one is picked, so cancelling leaves
-- no window behind (as `claude --resume`'s own picker in a fresh window did). One already open in a
-- window is shown there instead of being opened twice.
local function open_past(dir, here, items)
  local shown_in = {}
  for _, e in ipairs(items) do
    if e.conversation and not shown_in[e.conversation] then
      shown_in[e.conversation] = e
    end
  end
  local conversations = past(dir)
  if #conversations == 0 then
    return notify('No past conversations for this project', WARN)
  end
  vim.ui.select(conversations, {
    prompt = 'Past conversations · ' .. vim.fs.basename(dir),
    format_item = function(c)
      local where = shown_in[c.id] and ('  ← open in ' .. ref(shown_in[c.id], dir)) or ''
      return ('%s  %s  · %s%s'):format(os.date('%m-%d %H:%M', c.mtime), c.title, c.id:sub(1, 8), where)
    end,
  }, function(c)
    if not c then
      return
    elseif shown_in[c.id] then
      open(shown_in[c.id], dir, here)
    else
      create(dir, here, ' --resume ' .. c.id)
    end
  end)
end

function M.select()
  if not ready() then
    return
  end
  local dir = root()
  local items, here = list(dir)
  local last = (current(dir, items, here, false) or {}).pane
  local bg, bg_by_id, bg_by_conversation = background(dir), {}, {}
  for _, s in ipairs(bg) do
    bg_by_id[s.id] = s
    if type(s.sessionId) == 'string' then
      bg_by_conversation[s.sessionId] = s
    end
  end
  for _, e in ipairs(items) do -- a window attached to a background session shows its conversation
    local s = e.attach and bg_by_id[e.attach]
    if s and type(s.sessionId) == 'string' then
      e.conversation = s.sessionId
    end
  end
  -- Two Claudes on one conversation both write to it and interleave their messages (what
  -- `claude --continue` does when the latest conversation is already open): flag it.
  local open_in = {} ---@type table<string, table[]>
  for _, e in ipairs(items) do
    if e.conversation then
      open_in[e.conversation] = open_in[e.conversation] or {}
      table.insert(open_in[e.conversation], e)
    end
  end
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
    if e.conversation then
      label = label .. '  · ' .. e.conversation:sub(1, 8)
      for _, other in ipairs(open_in[e.conversation]) do
        if other ~= e then
          label = label .. '  ⚠ same conversation as ' .. ref(other, dir)
          break
        end
      end
    end
    if e.attach then
      label = label .. '  ☁ attached to background ' .. e.attach
    end
    if e.pane == last then
      label = label .. '  (in use)'
    end
    choices[#choices + 1] = { label = label, entry = e }
  end
  -- Background sessions no window here is attached to yet: picking one attaches it in a new
  -- stash window, so from then on Space a c / t / f / v reach it like any other Claude.
  local attached = {}
  for _, e in ipairs(items) do
    if e.attach then
      attached[e.attach] = true
    end
  end
  for _, s in ipairs(bg) do
    if not attached[s.id] then
      local name = type(s.name) == 'string' and s.name ~= s.id and ('"' .. s.name .. '"  ') or ''
      choices[#choices + 1] = {
        label = ('☁ background  %s· %s  [%s] — attach in a popup'):format(name, s.id, type(s.status) == 'string' and s.status or '?'),
        args = ' attach ' .. s.id,
      }
    end
  end
  local latest = latest_conversation(dir)
  local holder = latest and open_in[latest] and open_in[latest][1]
  local bg_holder = latest and not holder and bg_by_conversation[latest]
  local continue_choice = { label = '+ Continue the latest conversation (claude --continue)', args = ' --continue' }
  if holder then
    continue_choice = { label = ('+ Continue the latest conversation — already open in %s, shows that one'):format(ref(holder, dir)), entry = holder }
  elseif bg_holder then
    continue_choice = { label = ('+ Continue the latest conversation — it runs in background %s, attaches to it'):format(bg_holder.id), args = ' attach ' .. bg_holder.id }
  end
  vim.list_extend(choices, {
    { label = '+ New Claude', args = '' },
    continue_choice,
    { label = '+ Open a past conversation…', past = true },
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
    elseif c.past then
      vim.schedule(function() -- let this picker close before the next one opens
        open_past(dir, here, items)
      end)
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
