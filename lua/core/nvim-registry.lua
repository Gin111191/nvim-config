-- Tell ~/.claude/hooks/nvim-open.sh (repo claude-config) which Neovim belongs to which project.
-- claudecode.nvim used to do this as a side effect of its IDE lock file in ~/.claude/ide/; without
-- it, the hook would find no Neovim and Claude's edits would stop showing up here.
--
-- One small JSON file per running Neovim, same fields the hook already reads from those lock files:
--   ${XDG_CACHE_HOME:-~/.cache}/nvim-claude/<pid>.json  {"pid":…,"ideName":"Neovim","workspaceFolders":[cwd]}
-- Written at startup and whenever the global cwd changes, removed on exit. A file left behind by a
-- crash is harmless: the hook checks that the pid is still alive before using it.
local dir = (vim.env.XDG_CACHE_HOME or (vim.env.HOME .. '/.cache')) .. '/nvim-claude'
local file = ('%s/%d.json'):format(dir, vim.fn.getpid())

local function write()
  vim.fn.mkdir(dir, 'p')
  local data = { pid = vim.fn.getpid(), ideName = 'Neovim', workspaceFolders = { vim.fn.getcwd(-1, -1) } }
  vim.fn.writefile({ vim.json.encode(data) }, file)
end

local group = vim.api.nvim_create_augroup('NvimRegistry', { clear = true })
vim.api.nvim_create_autocmd('VimEnter', { group = group, callback = write })
vim.api.nvim_create_autocmd('DirChanged', { group = group, pattern = 'global', callback = write })
vim.api.nvim_create_autocmd('VimLeavePre', {
  group = group,
  callback = function()
    vim.fn.delete(file)
  end,
})
