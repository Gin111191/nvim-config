-- Read the scheme WezTerm is using, so Neovim wears the terminal's own colours.
--
-- WezTerm writes the choice into theme.lua (the CMD/CTRL+SHIFT+T picker writes that
-- file). We read it back. If it cannot be found, fall back to the dark Dusk-Navy.
local M = {}

-- Search order: macOS/Linux first, then the Windows side when running inside WSL.
local function candidates()
  local home = os.getenv("HOME") or ""
  local list = {
    home .. "/.config/wezterm/theme.lua",
    home .. "/.wezterm-theme.lua",
  }
  -- Inside WSL, the WezTerm config lives on the Windows side.
  local winuser = os.getenv("WIN_USER")
  if winuser then
    list[#list + 1] = "/mnt/c/Users/" .. winuser .. "/.config/wezterm/theme.lua"
  end
  -- With WIN_USER unset, probe the Windows user directories.
  local ok, dirs = pcall(vim.fn.glob, "/mnt/c/Users/*/.config/wezterm/theme.lua", false, true)
  if ok and type(dirs) == "table" then
    for _, path in ipairs(dirs) do
      list[#list + 1] = path
    end
  end
  return list
end

-- Returns { dark = "...", light = "..." }, or nil if it could not be read.
function M.wezterm_theme()
  for _, path in ipairs(candidates()) do
    if vim.uv.fs_stat(path) then
      local chunk = loadfile(path)
      if chunk then
        local ok, saved = pcall(chunk)
        if ok and type(saved) == "table" and saved.dark and saved.light then
          return saved, path
        end
      end
    end
  end
  return nil
end

-- Should Neovim use a dark or a light background?
-- vim.o.background is decided by $COLORFGBG or by the terminal's OSC 11 reply; we
-- trust it, because WezTerm already follows the operating system's light/dark.
function M.is_dark()
  return vim.o.background ~= "light"
end

return M
