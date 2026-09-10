-- Draw real images inside Neovim — opening a .png/.jpg buffer, and the images a
-- Markdown file references — using the terminal's own graphics protocol instead
-- of coloured character art.
--
-- This is snacks.nvim's `image` module, NOT 3rd/image.nvim (see neotree.lua, where
-- it stays disabled). image.nvim wants luarocks and the `magick` Lua rock, and on a
-- machine without luarocks lazy retries the build forever. snacks only shells out to
-- the ImageMagick *binary*, which apt and brew both ship.
--
-- Three things live outside this file and all three are required:
--   * the `magick` binary   — `sudo apt install imagemagick` / `brew install imagemagick`
--   * a terminal speaking the Kitty graphics protocol — WezTerm, Kitty, Ghostty
--   * under tmux, `allow-passthrough on` — already set in tmux-config
-- Miss any one and the module goes quiet rather than erroring; `:checkhealth snacks`
-- names the one that is missing.
--
-- Every other snacks module stays off: they are opt-in, and only `image` is declared.
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false, -- the module hooks buffer events, so it cannot wait to be called
  opts = {
    image = { enabled = true },
  },
}
