-- esmuellert/codediff.nvim — VSCode-style side-by-side diffs for reviewing what Claude changed,
-- across many files: an explorer of changed files on the left, the diff on the right, and it
-- refreshes by itself while Claude keeps editing. The diff library is a prebuilt binary the plugin
-- downloads on first use (`:CodeDiff install!` to force it again) — no compiler needed.
--
-- auto_open_on_cursor: moving j/k in the explorer opens that file's diff at once, instead of
-- pressing Enter on each one (the option craftzdog added upstream, shown in his tmux video).
--
-- It compares the working tree with HEAD, so your own uncommitted edits show up next to Claude's.
-- To see only Claude's: stage your own work first (`-` on a file, `S` for all), then hand over the
-- task — the "Changes" group is what Claude did since.
return {
  'esmuellert/codediff.nvim',
  cmd = 'CodeDiff',
  opts = {
    explorer = {
      auto_open_on_cursor = true,
    },
  },
  keys = {
    { '<leader>g', nil, desc = '[G]it diff' },
    { '<leader>gd', '<cmd>CodeDiff<cr>', desc = 'Diff: every changed file (working tree vs HEAD)' },
    { '<leader>gf', '<cmd>CodeDiff file HEAD<cr>', desc = 'Diff: this file vs HEAD' },
    { '<leader>gh', '<cmd>CodeDiff history %<cr>', desc = 'Diff: history of this file' },
    { '<leader>gH', '<cmd>CodeDiff history<cr>', desc = 'Diff: history of the repo' },
  },
}
