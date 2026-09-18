-- Draw real images inside Neovim — opening a .png/.jpg buffer, and the images a
-- Markdown file references — using the terminal's own graphics protocol instead
-- of coloured character art.
--
-- This is snacks.nvim's `image` module, NOT 3rd/image.nvim (see neotree.lua, where
-- it stays disabled). image.nvim wants luarocks and the `magick` Lua rock, and on a
-- machine without luarocks lazy retries the build forever. snacks only shells out to
-- the ImageMagick *binary*, which apt and brew both ship.
--
-- Where an image shows: an image file opened as a buffer fills that buffer. An image
-- referenced inside markdown, html, css/scss, latex, typst, norg, jsx/tsx, vue, svelte
-- (each needs its treesitter parser) pops up in a float while the cursor sits on the
-- reference, and closes when it moves off — linkarzu's setup, so a document with many
-- images is not drawn all at once. A bare path typed into any other file is not picked up.
--
-- Three things live outside this file and all three are required:
--   * the `magick` binary — `brew install imagemagick-full`, on the Mac and on the WSL box
--     alike (linuxbrew there, so no sudo). The plain `imagemagick` formula has no librsvg:
--     SVG text fails and gradients go black. PNG needs no conversion; the rest goes through it.
--   * a terminal speaking the Kitty graphics protocol — Kitty or Ghostty.
--     WezTerm lacks unicode placeholders, so there images only show in a hover float.
--   * over ssh, TERM=xterm-kitty known at the far end — `kitten ssh host` ships the
--     terminfo across; plain `ssh` leaves the remote without it
--   * under tmux, `allow-passthrough on` — already set in tmux-config
-- Miss any one and the module goes quiet rather than erroring; `:checkhealth snacks`
-- names the one that is missing.
--
-- Over SSH it still works: snacks sees SSH_CONNECTION and sends the image bytes instead
-- of a file path, so the terminal on the near side draws it. At most ONE tmux in the
-- chain — the wrapper snacks puts around an image gets through one tmux, not two.
-- tmux passes the image through without tracking it, so a scroll or a pane resize can
-- leave it stranded; reopening the buffer redraws it.
--
-- Every other snacks module stays off: they are opt-in, and only `image` is declared.
return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false, -- the module hooks buffer events, so it cannot wait to be called
  opts = {
    image = {
      enabled = true,
      -- snacks' own default list, plus svg and ico (ImageMagick reads both). Written out
      -- in full because snacks' config merge replaces a list rather than appending to it.
      formats = {
        'png', 'jpg', 'jpeg', 'gif', 'bmp', 'webp', 'tiff', 'heic', 'avif',
        'mp4', 'mov', 'avi', 'mkv', 'webm', 'pdf', 'icns',
        'svg', 'ico',
      },
      -- An .ico holds several sizes; snacks' default takes frame [0], the smallest (16px).
      -- ponytail: the last frame is the largest in icons written in ascending order (most
      -- tools); an .ico stored largest-first would show its smallest size.
      convert = {
        magick = {
          ico = { '{src}[-1]', '-scale', '1920x1080>' },
          -- Kitty refuses any image wider or taller than 10000 px ("Image too large", kitty
          -- graphics.c) and says nothing, so the buffer just stays blank. snacks caps rasters
          -- at 1920x1080 but renders pdf/svg at 192 dpi uncapped: a long single-page PDF
          -- (8100 pt tall) comes out 21314 px. These are snacks' own args plus the cap —
          -- written in full because a list replaces snacks' default instead of extending it.
          -- 4096 leaves an A4 page at 192 dpi (1587x2245) untouched and keeps the bytes sent
          -- down an ssh small; a page that tall shows as a narrow strip at any cap anyway.
          -- -depth 8: ghostscript hands back 16-bit, which the terminal throws away on arrival;
          -- the long page drops from 2.2 MB to 712 KB of PNG for the same picture.
          pdf = { '-density', 192, '{src}[{page}]', '-background', 'white', '-alpha', 'remove', '-trim', '-resize', '4096x4096>', '-depth', 8 },
          vector = { '-density', 192, '{src}[{page}]', '-resize', '4096x4096>', '-depth', 8 },
        },
      },
      -- inline = true would draw every reference under its line; float draws only the
      -- one at the cursor. Size is in cells.
      doc = { inline = false, float = true, max_width = 60, max_height = 30 },
    },
  },
  config = function(_, opts)
    -- Behind a tmux, snacks cannot see kitty: its XTVERSION query is answered by tmux, so it
    -- finds no graphics terminal and draws nothing. Over ssh the tmux may even be on the far
    -- side (kitty -> tmux on the Mac -> ssh -> here), leaving only TERM=tmux-256color to go on.
    -- kitty-config exports LC_TERMINAL=kitty, and LC_* is what ssh carries by default; seeing
    -- it, tell snacks outright. Set only on that signal, so a plain terminal gets no escapes.
    --
    -- A tmux on THIS side needs one more question: a server started before kitty attached
    -- keeps its old environment in every pane, so LC_TERMINAL is missing there — and that is
    -- the usual way to use a remote tmux (ssh in, `tmux attach`). tmux itself knows which
    -- terminal the attached client is; snacks asks the same thing when extended-keys is on.
    local function far_end_is_kitty()
      if vim.env.LC_TERMINAL == 'kitty' then
        return true
      end
      if vim.env.TMUX then
        local out = vim.fn.system { 'tmux', 'display-message', '-p', '#{client_termname}' }
        return vim.v.shell_error == 0 and out:find('kitty', 1, true) ~= nil
      end
      return false
    end
    if not vim.env.SNACKS_KITTY and far_end_is_kitty() then
      vim.env.SNACKS_KITTY = '1'
    end
    require('snacks').setup(opts)
    -- Upstream bug folke/snacks.nvim#2896 (closed as stale, not fixed): leaving an image
    -- buffer sets its placement `hidden`, and nothing clears it on return, so going back
    -- to an image already open (:b#, bufferline, neo-tree) shows a blank buffer. The
    -- patch below is the one from that issue. Drop it once snacks clears `hidden` itself.
    local placement = require('snacks.image.placement')
    local update = placement.update
    placement.update = function(self, ...)
      if self.hidden and #self:wins() > 0 then
        self.hidden = false
        self._state = nil
      end
      return update(self, ...)
    end

    -- Space + s + i: find an image with a live preview. Telescope cannot preview an
    -- image; snacks.picker draws it with this module. Lists only the formats above.
    vim.keymap.set('n', '<leader>si', function()
      Snacks.picker.files { ft = opts.image.formats }
    end, { desc = '[S]earch [I]mages' })
  end,
}
