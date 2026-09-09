-- Neovim's colours, matched to WezTerm.
--
-- The 16 colours below are taken VERBATIM from Gin's wezterm.lua (the
-- CUSTOM_SCHEMES["Dusk-Navy"] entry), itself ported from the Dusk-Navy Terminal.app
-- profile. Change a colour in wezterm.lua and these exact values must be changed too,
-- or the two sides drift apart.
--
-- base16 is the 16-slot colour convention: 00-07 run from the darkest background to
-- the brightest text, and 08-0F are the syntax colours (red, orange, yellow, green,
-- blue, cyan, purple, brown).

local DUSK_NAVY = {
  base00 = "#1d2837", -- background                    (WezTerm's background)
  base01 = "#26334a", -- lighter background: status bar, current line
  base02 = "#3D4A6B", -- selection background           (selection_bg)
  base03 = "#93a1b3", -- comments, hidden characters
                      -- Exactly BRIGHT_BLACK.dark from wezterm.lua: Gin lifted ANSI
                      -- slot 8 because most schemes leave it too dark to read.
  base04 = "#A9AFC6", -- dim text                       (ansi[7] / cursor_bg)
  base05 = "#EDEEF7", -- normal text                    (foreground)
  base06 = "#f2f3f9", -- bright text
  base07 = "#ffffff", -- brightest
  base08 = "#D18A9E", -- red    — variables, errors     (brights[1])
  base09 = "#E0C05A", -- orange — numbers, constants    (brights[3])
  base0A = "#C9A227", -- yellow — class names, search highlight (ansi[3])
  base0B = "#8FBFA9", -- green  — strings               (brights[2])
  base0C = "#8FBBD4", -- cyan   — regex, escapes        (brights[6])
  base0D = "#7D9BD4", -- blue   — function names        (brights[4])
  base0E = "#A99AD4", -- purple — keywords              (brights[5])
  base0F = "#B4637A", -- brown  — deprecated/unused     (ansi[1])

  -- 256-colour fallback, used only when termguicolors is off (see options.lua) —
  -- i.e. in a terminal without 24-bit colour, such as macOS Terminal.app.
  -- Without these base16-nvim leaves cterm unset and the theme shows no colour at all.
  -- Each number is the nearest colour in the fixed xterm 16-255 palette, by redmean
  -- distance; indices 0-15 are deliberately avoided because they change with the
  -- terminal profile. The eight syntax colours plus comments and normal text are
  -- forced distinct, so nothing readable collapses into its neighbour.
  -- Regenerate: tools/nearest256.py
  cterm00 = 235, -- #262626  (the navy tint is lost: the 256 cube has no dark blue-grey)
  cterm01 = 237, -- #3a3a3a
  cterm02 = 239, -- #4e4e4e
  cterm03 = 247, -- #9e9e9e
  cterm04 = 146, -- #afafd7
  cterm05 = 255, -- #eeeeee
  cterm06 = 255, -- #eeeeee  (shares with base05 on purpose — both are plain bright text)
  cterm07 = 231, -- #ffffff  (exact)
  cterm08 = 175, -- #d787af
  cterm09 = 179, -- #d7af5f
  cterm0A = 178, -- #d7af00
  cterm0B = 109, -- #87afaf
  cterm0C = 110, -- #87afd7
  cterm0D = 104, -- #8787d7
  cterm0E = 140, -- #af87d7
  cterm0F = 132, -- #af5f87
}

return {
  {
    -- Builds a full colorscheme from the 16 colours above (treesitter + LSP aware).
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
    config = function()
      local source = require("core.theme-source")
      local transparent = true -- lets WezTerm's gradient and opacity show through

      local function apply()
        if source.is_dark() then
          require("base16-colorscheme").setup(DUSK_NAVY)
          -- base16 gives CursorLineNr the same fg as LineNr (base04), so the current
          -- line's number was told apart only by its background. Merge in base09 so it
          -- reads at a glance against the relative numbers either side.
          local cur = vim.api.nvim_get_hl(0, { name = "CursorLineNr", link = false })
          cur.fg, cur.ctermfg, cur.bold = DUSK_NAVY.base09, DUSK_NAVY.cterm09, true
          vim.api.nvim_set_hl(0, "CursorLineNr", cur)
        else
          -- Light background: WezTerm uses "Everforest Light Medium (Gogh)".
          vim.o.background = "light"
          pcall(vim.cmd.colorscheme, "everforest")
        end

        if transparent then
          for _, group in ipairs({
            "Normal", "NormalNC", "NormalFloat", "FloatBorder",
            "SignColumn", "LineNr", "EndOfBuffer", "TabLineFill",
          }) do
            -- Merge, do not replace: nvim_set_hl overwrites the whole group, so
            -- passing only bg threw the foreground away too (Normal, LineNr and
            -- SignColumn came out empty).
            local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
            hl.bg, hl.ctermbg = "none", "none"
            vim.api.nvim_set_hl(0, group, hl)
          end
        end
      end

      apply()

      -- Space + bg: toggle the transparent background
      vim.keymap.set("n", "<leader>bg", function()
        transparent = not transparent
        apply()
        vim.notify("Transparent background: " .. (transparent and "ON" or "OFF"))
      end, { noremap = true, silent = true, desc = "Toggle the transparent background" })

      -- Space + tt: show where Neovim is reading the theme from
      vim.keymap.set("n", "<leader>tt", function()
        local theme, path = source.wezterm_theme()
        if theme then
          vim.notify(("WezTerm: dark=%s | light=%s\n%s"):format(theme.dark, theme.light, path))
        else
          vim.notify("WezTerm's theme.lua not found — falling back to the default Dusk-Navy")
        end
      end, { noremap = true, silent = true, desc = "Theme source" })
    end,
  },
  {
    -- Used when the operating system switches to light mode.
    "neanias/everforest-nvim",
    lazy = false,
    priority = 999,
    config = function()
      require("everforest").setup({ background = "medium", transparent_background_level = 1 })
    end,
  },
}
