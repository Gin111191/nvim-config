-- Bộ màu Neovim, khớp với WezTerm.
--
-- 16 màu dưới đây lấy NGUYÊN từ wezterm.lua của Gin (mục CUSTOM_SCHEMES["Dusk-Navy"]),
-- vốn được port từ profile Terminal.app Dusk-Navy. Đổi màu trong wezterm.lua thì
-- sửa lại đúng những giá trị này để hai bên không lệch nhau.
--
-- base16 là quy ước 16 ô màu: 00-07 đi từ nền tối nhất tới chữ sáng nhất,
-- 08-0F là các màu cú pháp (đỏ, cam, vàng, lục, lam, lơ, tím, nâu).

local DUSK_NAVY = {
  base00 = "#1d2837", -- nền                        (background của WezTerm)
  base01 = "#26334a", -- nền nhạt hơn: thanh status, dòng đang đứng
  base02 = "#3D4A6B", -- nền vùng bôi đen           (selection_bg)
  base03 = "#93a1b3", -- chú thích, ký tự ẩn
                      -- Lấy đúng BRIGHT_BLACK.dark trong wezterm.lua: Gin đã nâng
                      -- ô ANSI 8 lên vì mặc định của các scheme quá tối để đọc.
  base04 = "#A9AFC6", -- chữ mờ                     (ansi[7] / cursor_bg)
  base05 = "#EDEEF7", -- chữ thường                 (foreground)
  base06 = "#f2f3f9", -- chữ sáng
  base07 = "#ffffff", -- sáng nhất
  base08 = "#D18A9E", -- đỏ    — biến, lỗi          (brights[1])
  base09 = "#E0C05A", -- cam   — số, hằng           (brights[3])
  base0A = "#C9A227", -- vàng  — tên lớp, nền tìm kiếm (ansi[3])
  base0B = "#8FBFA9", -- lục   — chuỗi              (brights[2])
  base0C = "#8FBBD4", -- lơ    — regex, escape      (brights[6])
  base0D = "#7D9BD4", -- lam   — tên hàm            (brights[4])
  base0E = "#A99AD4", -- tím   — từ khoá            (brights[5])
  base0F = "#B4637A", -- nâu đỏ — cũ/không dùng nữa (ansi[1])
}

return {
  {
    -- Dựng colorscheme đầy đủ từ 16 màu trên (hỗ trợ treesitter + LSP).
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local source = require("core.theme-source")
      local transparent = true -- để gradient và độ mờ của WezTerm hiện xuyên qua

      local function apply()
        if source.is_dark() then
          require("base16-colorscheme").setup(DUSK_NAVY)
        else
          -- Nền sáng: WezTerm dùng "Everforest Light Medium (Gogh)".
          vim.o.background = "light"
          pcall(vim.cmd.colorscheme, "everforest")
        end

        if transparent then
          for _, group in ipairs({
            "Normal", "NormalNC", "NormalFloat", "FloatBorder",
            "SignColumn", "LineNr", "EndOfBuffer", "TabLineFill",
          }) do
            vim.api.nvim_set_hl(0, group, { bg = "none" })
          end
        end
      end

      apply()

      -- Space + bg: bật/tắt nền trong suốt
      vim.keymap.set("n", "<leader>bg", function()
        transparent = not transparent
        apply()
        vim.notify("Nền trong suốt: " .. (transparent and "BẬT" or "TẮT"))
      end, { noremap = true, silent = true, desc = "Bật/tắt nền trong suốt" })

      -- Space + tt: xem Neovim đang đọc theme từ đâu
      vim.keymap.set("n", "<leader>tt", function()
        local theme, path = source.wezterm_theme()
        if theme then
          vim.notify(("WezTerm: tối=%s | sáng=%s\n%s"):format(theme.dark, theme.light, path))
        else
          vim.notify("Không tìm thấy theme.lua của WezTerm — đang dùng Dusk-Navy mặc định")
        end
      end, { noremap = true, silent = true, desc = "Nguồn theme" })
    end,
  },
  {
    -- Dùng khi hệ điều hành chuyển sang chế độ sáng.
    "neanias/everforest-nvim",
    lazy = false,
    priority = 999,
    config = function()
      require("everforest").setup({ background = "medium", transparent_background_level = 1 })
    end,
  },
}
