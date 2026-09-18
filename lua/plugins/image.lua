-- Draw real images inside Neovim — opening a .png/.jpg buffer, and the images a
-- Markdown file references — using the terminal's own graphics protocol instead
-- of coloured character art.
--
-- This is snacks.nvim's `image` module, NOT 3rd/image.nvim (see neotree.lua, where
-- it stays disabled). image.nvim wants luarocks and the `magick` Lua rock, and on a
-- machine without luarocks lazy retries the build forever. snacks only shells out to
-- the ImageMagick *binary*, which apt and brew both ship.
--
-- Where an image shows: an image file opened as a buffer, and image references inside
-- markdown, html, css/scss, latex, typst, norg, jsx/tsx, vue, svelte (each needs its
-- treesitter parser). A bare path typed into any other file is not picked up.
--
-- Three things live outside this file and all three are required:
--   * the `magick` binary   — `sudo apt install imagemagick` / `brew install imagemagick`
--     (PNG needs no conversion; every other format goes through it)
--   * a terminal speaking the Kitty graphics protocol — Kitty or Ghostty draw inline.
--     WezTerm lacks unicode placeholders, so there images only show in a hover float.
--   * under tmux, `allow-passthrough on` — already set in tmux-config
-- Miss any one and the module goes quiet rather than erroring; `:checkhealth snacks`
-- names the one that is missing.
--
-- Over SSH it still works: snacks sees SSH_CONNECTION and sends the image bytes instead
-- of a file path, so the terminal on the near side draws it. At most ONE tmux in the
-- chain — the wrapper snacks puts around an image gets through one tmux, not two.
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
