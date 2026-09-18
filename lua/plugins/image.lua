-- Inline images, drawn by the terminal itself over the kitty graphics protocol:
-- kitty on the Mac -> ssh -> tmux -> this nvim. No X11, no WSLg, nothing on the
-- Linux side but ImageMagick, which snacks shells out to for the conversion.
--
-- Needs, and fails silently without:
--   magick            `brew install imagemagick` (no sudo on the WSL box)
--   TERM=xterm-kitty  reaching this nvim — `kitten ssh host` ships the terminfo
--                     across for you; plain `ssh` leaves the remote without it
--   tmux allow-passthrough on   already set in tmux-config
--
-- Redraws inside tmux are the known rough edge: tmux does not track the image,
-- so a scroll or a pane resize can leave it behind. :lua Snacks.image.hover() or
-- reopening the buffer puts it back.
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    image = { enabled = true },
  },
}
