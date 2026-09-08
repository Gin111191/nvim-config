-- Đọc scheme WezTerm đang dùng, để Neovim khoác đúng bộ màu của terminal.
--
-- WezTerm ghi lựa chọn vào theme.lua (bộ chọn CMD/CTRL+SHIFT+T viết ra file này).
-- Ta đọc lại file đó. Không tìm thấy thì rơi về Dusk-Navy tối.
local M = {}

-- Thứ tự tìm: macOS/Linux trước, rồi phía Windows khi đang chạy trong WSL.
local function candidates()
  local home = os.getenv("HOME") or ""
  local list = {
    home .. "/.config/wezterm/theme.lua",
    home .. "/.wezterm-theme.lua",
  }
  -- Trong WSL, config WezTerm nằm bên Windows.
  local winuser = os.getenv("WIN_USER")
  if winuser then
    list[#list + 1] = "/mnt/c/Users/" .. winuser .. "/.config/wezterm/theme.lua"
  end
  -- Không đặt WIN_USER thì dò các thư mục người dùng Windows.
  local ok, dirs = pcall(vim.fn.glob, "/mnt/c/Users/*/.config/wezterm/theme.lua", false, true)
  if ok and type(dirs) == "table" then
    for _, path in ipairs(dirs) do
      list[#list + 1] = path
    end
  end
  return list
end

-- Trả về { dark = "...", light = "..." } hoặc nil nếu không đọc được.
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

-- Neovim nên dùng nền tối hay sáng?
-- vim.o.background do biến $COLORFGBG hoặc truy vấn OSC 11 của terminal quyết định;
-- ta tin vào nó, vì WezTerm đã tự đổi theo sáng/tối của hệ điều hành rồi.
function M.is_dark()
  return vim.o.background ~= "light"
end

return M
